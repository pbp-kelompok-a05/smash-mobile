import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:smash_mobile/models/post.dart';
import 'package:smash_mobile/models/comment.dart';

class PostService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator/web
  // If you are running on a real device, use your machine's IP address
  // Optional override: if set to a non-empty string (e.g. 'http://192.168.1.100:8000/json/')
  // it will be used as the base URL. This is helpful when testing on a physical device.
  static String overrideBaseUrl = '';

  static String get baseUrl {
    if (overrideBaseUrl.isNotEmpty) return overrideBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000/json/';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/json/';
    } catch (_) {}
    return 'http://127.0.0.1:8000/json/';
  }

  static String commentsUrl(String postId) => '${baseUrl}comments/$postId';

  static String get serverRoot {
    if (overrideBaseUrl.isNotEmpty) {
      return overrideBaseUrl
          .replaceAll(RegExp(r'/json/?\$'), '/json/')
          .replaceAll(RegExp(r'/json/?$'), '/');
    }
    if (kIsWeb) return 'http://127.0.0.1:8000/';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/';
    } catch (_) {}
    return 'http://127.0.0.1:8000/';
  }

  String createPostUrl() => '${serverRoot}create_flutter_post/';

  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    String? videoLink,
    List<int>? imageBytes,
    String? imageMime,
    String? userId,
  }) async {
    final url = createPostUrl();
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      'video_link': videoLink ?? '',
      'user_id': userId ?? '1',
    };

    if (imageBytes != null) {
      final b64 = base64Encode(imageBytes);
      final mime = imageMime ?? 'image/png';
      body['image'] = 'data:$mime;base64,$b64';
    }

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      throw Exception('Create post failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load posts. Status code: ${response.statusCode}',
        );
      }

      final decoded = json.decode(response.body);

      // Accept either a bare list of posts, or a wrapper object with a
      // `posts` field or a `{status: 'success', posts: [...]}` shape.
      List<dynamic> postsJson;
      if (decoded is List) {
        postsJson = decoded;
      } else if (decoded is Map && decoded['posts'] is List) {
        postsJson = decoded['posts'];
      } else {
        throw Exception('Unexpected posts JSON format');
      }

      final posts = postsJson
          .map((json) => Post.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Merge locally cached user reactions so state persists across refreshes
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('post_reactions');
        if (stored != null && stored.isNotEmpty) {
          final Map<String, dynamic> reactions = json.decode(stored);
          var cacheChanged = false;
          for (final p in posts) {
            final key = p.id.toString();
            if (!reactions.containsKey(key)) continue;
            final val = reactions[key];
            if (val is String) {
              // legacy format: stored reaction only
              p.userReaction = val;
            } else if (val is Map) {
              // apply user reaction and any cached likes/dislikes, but prefer server comments_count
              p.userReaction = val['user_reaction'] as String?;
              try {
                if (val['likes_count'] != null)
                  p.likesCount = val['likes_count'] as int;
              } catch (_) {}
              try {
                if (val['dislikes_count'] != null)
                  p.dislikesCount = val['dislikes_count'] as int;
              } catch (_) {}

              // Ensure cache reflects authoritative server comments_count
              final cachedComments = (val['comments_count'] is int)
                  ? val['comments_count'] as int
                  : null;
              if (cachedComments == null || cachedComments != p.commentsCount) {
                // update cache to match server
                final newMap = Map<String, dynamic>.from(val);
                newMap['comments_count'] = p.commentsCount;
                reactions[key] = newMap;
                cacheChanged = true;
              }
            }
          }
          if (cacheChanged) {
            await prefs.setString('post_reactions', json.encode(reactions));
          }
        }
      } catch (_) {}

      return posts;
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  Future<List<Comment>> fetchComments(String postId, {String? userId}) async {
    var url = commentsUrl(postId);
    if (userId != null && userId.isNotEmpty) {
      url = '$url?user_id=$userId';
    }
    try {
      final uri = Uri.parse(url);
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception(
          'Failed to load comments. Status: ${res.statusCode} Body: ${res.body}',
        );
      }

      dynamic decoded;
      try {
        decoded = json.decode(res.body);
      } catch (e) {
        throw Exception(
          'Failed to decode comments JSON: $e. Body: ${res.body}',
        );
      }

      final List<dynamic> items = decoded is List
          ? decoded
          : (decoded['comments'] ?? []);
      final comments = items
          .map((c) => Comment.fromJson(Map<String, dynamic>.from(c)))
          .toList();

      // Merge cached comment reactions (persisted similarly to post reactions)
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('comment_reactions');
        if (stored != null && stored.isNotEmpty) {
          final Map<String, dynamic> reactions = json.decode(stored);
          for (final c in comments) {
            final key = c.id.toString();
            if (reactions.containsKey(key)) {
              final val = reactions[key];
              if (val is String) {
                c.userReaction = val;
              } else if (val is Map) {
                c.userReaction = val['user_reaction'] as String?;
                try {
                  if (val['likes_count'] != null)
                    c.likesCount = val['likes_count'] as int;
                } catch (_) {}
                try {
                  if (val['dislikes_count'] != null)
                    c.dislikesCount = val['dislikes_count'] as int;
                } catch (_) {}
              }
            }
          }
        }
      } catch (_) {}

      return comments;
    } catch (e) {
      throw Exception('Error fetching comments from $url: $e');
    }
  }

  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
    String? userId,
    String? parentId,
  }) async {
    final url = '${serverRoot}create_flutter_comment/';
    final body = <String, dynamic>{
      'post_id': postId,
      'content': content,
      'user_id': userId ?? '1',
    };
    if (parentId != null) body['parent_id'] = parentId;

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      throw Exception('Create comment failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      throw Exception('Error creating comment: $e');
    }
  }

  Future<Map<String, dynamic>> togglePostReaction({
    required String postId,
    required String action, // 'like' or 'dislike'
    String? userId,
  }) async {
    final url = '${serverRoot}toggle_post_reaction/';
    final body = {
      'post_id': postId,
      'action': action,
      'user_id': userId ?? '1',
    };
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final Map<String, dynamic> result = json.decode(res.body);
        // persist user's reaction locally so it survives refreshes
        try {
          final prefs = await SharedPreferences.getInstance();
          final stored = prefs.getString('post_reactions');
          final Map<String, dynamic> reactions =
              stored != null && stored.isNotEmpty
              ? json.decode(stored) as Map<String, dynamic>
              : <String, dynamic>{};
          final ur = result['user_reaction'];
          final likes = result['likes_count'];
          final dislikes = result['dislikes_count'];
          final key = postId.toString();
          // preserve existing comments_count if present so it isn't lost
          final existingVal = reactions.containsKey(key)
              ? reactions[key]
              : null;
          final existingComments =
              (existingVal is Map && existingVal['comments_count'] is int)
              ? existingVal['comments_count'] as int
              : null;
          if (ur == null &&
              likes == null &&
              dislikes == null &&
              existingComments == null) {
            reactions.remove(key);
          } else {
            final map = <String, dynamic>{
              'user_reaction': ur,
              'likes_count': likes,
              'dislikes_count': dislikes,
            };
            if (existingComments != null)
              map['comments_count'] = existingComments;
            reactions[key] = map;
          }
          await prefs.setString('post_reactions', json.encode(reactions));
        } catch (_) {}

        return result;
      }
      throw Exception('Toggle failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      throw Exception('Error toggling reaction: $e');
    }
  }

  Future<Map<String, dynamic>> toggleCommentReaction({
    required String commentId,
    required String action,
    String? userId,
  }) async {
    final url = '${serverRoot}toggle_comment_reaction/';
    final body = {
      'comment_id': commentId,
      'action': action,
      'user_id': userId ?? '1',
    };
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final Map<String, dynamic> result = json.decode(res.body);
        // persist local comment reaction cache
        try {
          final prefs = await SharedPreferences.getInstance();
          final stored = prefs.getString('comment_reactions');
          final Map<String, dynamic> reactions =
              stored != null && stored.isNotEmpty
              ? json.decode(stored) as Map<String, dynamic>
              : <String, dynamic>{};
          final ur = result['user_reaction'];
          final likes = result['likes_count'];
          final dislikes = result['dislikes_count'];
          final key = commentId.toString();
          if (ur == null && likes == null && dislikes == null) {
            reactions.remove(key);
          } else {
            reactions[key] = {
              'user_reaction': ur,
              'likes_count': likes,
              'dislikes_count': dislikes,
            };
          }
          await prefs.setString('comment_reactions', json.encode(reactions));
        } catch (_) {}

        return result;
      }
      throw Exception('Toggle failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      throw Exception('Error toggling comment reaction: $e');
    }
  }
}
