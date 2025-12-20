import 'dart:convert';

import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/models/comment_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// API service untuk operasi post dengan integrasi Django backend
/// Menangani: fetch posts, notifications, post detail, dan utilities URL
class PostApi {
  PostApi({required this.request, String? baseUrl})
    : baseUrl = baseUrl ?? 'http://localhost:8000';

  final CookieRequest request;
  final String baseUrl;
  static const String _defaultAvatarPath = '/static/images/user-profile.png';

  /// Ambil semua post dari endpoint /post/api/posts/
  /// Mengembalikan List<ProfileFeedItem> dengan semua data termasuk interaksi user
  Future<List<ProfileFeedItem>> fetchAllPosts() async {
    final uri = Uri.parse(
      '$baseUrl/post/api/posts/',
    ).replace(queryParameters: {'sort': 'newest'});
    final response = await _safeGet(uri);

    if (response is Map<String, dynamic> && response['status'] == 'success') {
      final posts =
          (response['posts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      return posts.map((post) {
        return ProfileFeedItem(
          id: post['id'] ?? 0,
          title: post['title'] ?? '',
          content: post['content'] ?? '',
          image: post['image'] as String?,
          videoLink: post['video_link'] as String?,
          user: post['user'] ?? '', // Username dari API
          userId: post['user_id'] ?? 0,
          createdAt:
              DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now(),
          commentCount: post['comment_count'] ?? 0,
          likesCount: post['likes_count'] ?? 0,
          dislikesCount: post['dislikes_count'] ?? 0,
          sharesCount: post['shares_count'] ?? 0,
          profilePhoto: post['profile_photo'] as String?,
          userInteraction: post['user_interaction'] as String?,
          isSaved: post['is_saved'] ?? false,
          canEdit: post['can_edit'] ?? false,
        );
      }).toList();
    }
    throw Exception('Gagal mengambil posts.');
  }

  /// Cari post berdasarkan query string
  /// Endpoint: GET /post/api/search/?q=<query>
  Future<List<ProfileFeedItem>> searchPosts(String query) async {
    final uri = Uri.parse(
      '$baseUrl/post/api/search/',
    ).replace(queryParameters: {'q': query});
    final response = await _safeGet(uri);

    if (response is Map<String, dynamic> && response['status'] == 'success') {
      final posts = response['posts'] as List<dynamic>? ?? [];
      return posts.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return ProfileFeedItem(
          id: map['id'] ?? 0,
          title: map['title'] ?? '',
          content: map['content'] ?? '',
          image: map['image'] as String?,
          videoLink: map['video_link'] as String?,
          user: map['user'] ?? '',
          userId: map['user_id'] ?? 0,
          createdAt:
              DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
          commentCount: map['comment_count'] ?? 0,
          likesCount: map['likes_count'] ?? 0,
          dislikesCount: map['dislikes_count'] ?? 0,
          sharesCount: map['shares_count'] ?? 0,
          profilePhoto: map['profile_photo'] as String?,
          userInteraction: null,
          isSaved: false,
          canEdit: false,
        );
      }).toList();
    }
    throw Exception('Gagal mencari post.');
  }

  /// Ambil notifikasi untuk user yang sedang login
  /// Endpoint: GET /post/api/notifications/
  Future<List<NotificationItem>> fetchNotifications() async {
    final uri = Uri.parse('$baseUrl/post/api/notifications/');
    final response = await _safeGet(uri);

    if (response is Map<String, dynamic> && response['status'] == 'success') {
      final list = response['notifications'] as List<dynamic>? ?? [];
      return list
          .map(
            (item) => NotificationItem.fromJson(
              Map<String, dynamic>.from(item as Map),
              resolveMediaUrl: _resolveMediaUrl,
              defaultAvatarUrl: '$baseUrl$_defaultAvatarPath',
            ),
          )
          .toList();
    }
    throw Exception('INVALID_RESPONSE');
  }

  /// Ambil detail single post berdasarkan ID
  /// Endpoint: GET /post/api/posts/<postId>/
  Future<ProfileFeedItem> fetchPostDetail(int postId) async {
    final uri = Uri.parse('$baseUrl/post/api/posts/$postId/');
    final response = await _safeGet(uri);
    if (response is Map<String, dynamic> &&
        response['status'] == 'success' &&
        response['post'] != null) {
      final map = Map<String, dynamic>.from(response['post']);
      return ProfileFeedItem(
        id: map['id'] ?? 0,
        title: map['title'] ?? '',
        content: map['content'] ?? '',
        image: map['image'] as String?,
        videoLink: map['video_link'] as String?,
        user: map['user'] ?? '',
        userId: map['user_id'] ?? 0,
        createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
        commentCount: map['comment_count'] ?? 0,
        likesCount: map['likes_count'] ?? 0,
        dislikesCount: map['dislikes_count'] ?? 0,
        sharesCount: map['shares_count'] ?? 0,
        profilePhoto: map['profile_photo'] as String?,
        userInteraction: map['user_interaction'] as String?,
        isSaved: map['is_saved'] ?? false,
        canEdit: map['can_edit'] ?? false,
      );
    }
    throw Exception('Gagal mengambil detail post.');
  }

  /// Fetch comments for a post
  /// Endpoint: GET /post/api/posts/<postId>/comments/
  Future<List<Comment>> fetchComments(int postId, {int? userId}) async {
    final uri = Uri.parse('$baseUrl/post/api/posts/$postId/comments/').replace(
      queryParameters: userId != null ? {'user_id': userId.toString()} : null,
    );
    final response = await _safeGet(uri);

    List<dynamic> rawList;
    if (response is List) {
      rawList = response;
    } else if (response is Map<String, dynamic> &&
        response['status'] == 'success' &&
        response['comments'] is List) {
      rawList = response['comments'] as List<dynamic>;
    } else {
      throw Exception('Gagal mengambil komentar.');
    }

    return rawList
        .map((e) => Comment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Create a comment via Flutter client
  /// Endpoint: POST /post/api/create-comment/
  Future<Comment> createComment(
    int postId,
    String content, {
    int? userId,
    int? parentId,
  }) async {
    final uri = Uri.parse('$baseUrl/post/api/create-comment/');
    final body = {
      'post_id': postId.toString(),
      'content': content,
      if (userId != null) 'user_id': userId.toString(),
      if (parentId != null) 'parent_id': parentId.toString(),
    };

    final res = await request.post(uri.toString(), body);
    if (res is Map<String, dynamic> && res['status'] == 'success') {
      final commentMap = res['comment'] as Map<String, dynamic>?;
      if (commentMap != null) return Comment.fromJson(commentMap);
    }
    throw Exception('Gagal membuat komentar.');
  }

  /// Interact with a comment (like/dislike/report)
  /// Endpoint: POST /comments/<commentId>/<action>/
  Future<Map<String, dynamic>> interactWithComment(
    String commentId,
    String action,
  ) async {
    // use plural 'comments' to match Django include path (e.g. /comments/...)
    final uri = Uri.parse('$baseUrl/comments/$commentId/$action/');
    final res = await request.post(uri.toString(), {});
    if (res is Map<String, dynamic> && res['status'] == 'success') {
      return Map<String, dynamic>.from(res);
    }
    throw Exception('Gagal melakukan interaksi pada komentar.');
  }

  /// Helper untuk GET request dengan error handling
  Future<dynamic> _safeGet(Uri uri) async {
    try {
      final res = await request.get(uri.toString());
      if (res is String) {
        try {
          return jsonDecode(res);
        } catch (_) {
          return res;
        }
      }
      return res;
    } on FormatException {
      throw Exception('INVALID_RESPONSE');
    }
  }

  /// Resolve relative URL ke absolute URL
  /// Contoh: /media/avatar.jpg -> http://localhost:8000/media/avatar.jpg
  String? _resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('/')) return '$baseUrl$trimmed';
    return '$baseUrl/$trimmed';
  }

  /// Public wrapper untuk _resolveMediaUrl
  String? resolveMediaUrl(String? url) => _resolveMediaUrl(url);
}

/// Model untuk notifikasi (like, comment, save, dll)
/// Digunakan di halaman notifikasi dan feed
class NotificationItem {
  NotificationItem({
    required this.type,
    required this.actor,
    required this.postTitle,
    required this.postId,
    this.actorId,
    this.actorProfileUrl,
    this.actorPhoto,
    this.fallbackPhoto,
    this.content,
    required this.message,
    this.timestamp,
  });

  final String type;
  final String actor;
  final String postTitle;
  final int postId;
  final int? actorId;
  final String? actorProfileUrl;
  final String? actorPhoto;
  final String? fallbackPhoto;
  final String? content;
  final String message;
  final DateTime? timestamp;

  /// Parse dari JSON API dengan flexible field mapping
  factory NotificationItem.fromJson(
    Map<String, dynamic> json, {
    String? Function(String?)? resolveMediaUrl,
    String? defaultAvatarUrl,
  }) {
    final resolver = resolveMediaUrl ?? (s) => s;
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    String? extractProfileUrl() {
      final candidates = [
        json['actor_profile_url'],
        json['profile_url'],
        json['actor_url'],
      ];
      for (final c in candidates) {
        if (c is String && c.trim().isNotEmpty) return c.trim();
      }
      if (json['actor'] is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(json['actor'] as Map);
        final link = map['profile_url'] ?? map['url'];
        if (link is String && link.trim().isNotEmpty) return link.trim();
      }
      return null;
    }

    int? extractActorId() {
      final keys = [
        json['actor_id'],
        json['user_id'],
        json['actor_user_id'],
        json['actorId'],
        json['userId'],
      ];
      for (final candidate in keys) {
        final parsed = toInt(candidate);
        if (parsed != null) return parsed;
      }
      if (json['actor'] is Map<String, dynamic>) {
        return toInt((json['actor'] as Map)['id']);
      }
      // Parse dari URL format /profil/<id>/
      final profileUrl = extractProfileUrl();
      if (profileUrl != null) {
        final match = RegExp(
          r'/profil/(?:api/profile/)?(\d+)/',
        ).firstMatch(profileUrl);
        if (match != null) return int.tryParse(match.group(1) ?? '');
      }
      return null;
    }

    String extractActorName() {
      if (json['actor'] is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(json['actor'] as Map);
        return map['username'] ?? map['name'] ?? '';
      }
      return json['actor'] ?? '';
    }

    String? pickPhoto() {
      if (json['actor'] is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(json['actor'] as Map);
        final inlinePhoto = map['profile_photo'] ?? map['photo'];
        if (inlinePhoto is String && inlinePhoto.trim().isNotEmpty) {
          final resolved = resolver(inlinePhoto);
          if (resolved != null && resolved.isNotEmpty) return resolved;
        }
      }
      final candidates = [
        json['actor_profile_photo_url'],
        json['actor_photo_url'],
        json['actor_photo'],
        json['actor_profile_photo'],
        json['profile_photo'],
        json['user_photo'],
        json['profile_photo_url'],
      ];
      for (final c in candidates) {
        if (c is String && c.trim().isNotEmpty) {
          final resolved = resolver(c);
          if (resolved != null && resolved.isNotEmpty) return resolved;
        }
      }
      return defaultAvatarUrl;
    }

    return NotificationItem(
      type: json['type'] ?? '',
      actor: extractActorName(),
      postTitle: json['post_title'] ?? '',
      postId: json['post_id'] ?? 0,
      actorId: extractActorId(),
      actorProfileUrl: extractProfileUrl(),
      actorPhoto: pickPhoto(),
      fallbackPhoto: defaultAvatarUrl,
      content: json['content'] as String?,
      message: json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
