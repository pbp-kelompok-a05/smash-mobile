import 'dart:convert';
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

      return postsJson
          .map((json) => Post.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  Future<List<Comment>> fetchComments(String postId) async {
    final url = commentsUrl(postId);
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
      return items
          .map((c) => Comment.fromJson(Map<String, dynamic>.from(c)))
          .toList();
    } catch (e) {
      throw Exception('Error fetching comments from $url: $e');
    }
  }
}
