import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smash_mobile/models/post.dart';

class PostService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator/web
  // If you are running on a real device, use your machine's IP address
  static const String baseUrl = 'http://127.0.0.1:8000/api/posts/';

  Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> postsJson = data['posts'];
          return postsJson.map((json) => Post.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load posts: ${data['message']}');
        }
      } else {
        throw Exception(
          'Failed to load posts. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }
}
