// file: test/models_test.dart
import 'dart:convert';
import 'package:smash_mobile/models/post_entry.dart';
import 'package:flutter_test/flutter_test.dart';

const String fakeJson = '''
{
  "posts": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "user_id": "f1f2f3f4-f5f6-7890-abcd-ef1234567890",
      "title": "Test post",
      "content": "Lorem ipsum",
      "image": null,
      "video": null,
      "created_at": "2025-12-03T08:00:00Z",
      "updated_at": null,
      "is_deleted": false,
      "likes_count": 7,
      "dislikes_count": 2
    }
  ],
  "interactions": [
    {
      "post_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "user_id": "f1f2f3f4-f5f6-7890-abcd-ef1234567890",
      "interaction_type": "like",
      "created_at": "2025-12-03T08:05:00Z"
    }
  ],
  "saves": [],
  "shares": []
}
''';

void main() {
  group('JSON parsing', () {
    test('PostEntry list dari JSON', () {
      final data = jsonDecode(fakeJson);
      final posts = (data['posts'] as List)
          .map((e) => PostEntry.fromJson(e))
          .toList();

      expect(posts.length, 1);
      expect(posts.first.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(posts.first.userId, 'f1f2f3f4-f5f6-7890-abcd-ef1234567890');
      expect(posts.first.image, isNull);
      expect(posts.first.createdAt?.year, 2025);
      expect(posts.first.likesCount, 7);
    });
  });
}