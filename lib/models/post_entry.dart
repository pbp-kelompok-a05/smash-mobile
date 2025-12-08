import 'dart:convert';
import 'package:http/http.dart' as http;
Future<void> fetchAllPostData() async {
  final uri = Uri.parse('https://<your-domain>/post/json/');
  final resp = await http.get(uri);

  if (resp.statusCode != 200) {
    throw Exception('Gagal load: ${resp.statusCode}');
  }

  final data = jsonDecode(resp.body);

  List<PostEntry> posts =
      (data['posts'] as List).map((e) => PostEntry.fromJson(e)).toList();

  List<InteractionPost> interactions =
      (data['post_interactions'] as List)
          .map((e) => InteractionPost.fromJson(e))
          .toList();

  List<PostSave> saves =
      (data['saves'] as List).map((e) => PostSave.fromJson(e)).toList();

  List<PostShare> shares =
      (data['shares'] as List).map((e) => PostShare.fromJson(e)).toList();

}


String postEntryFromJson(List<PostEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class PostEntry {
    String id;
    String title;
    String content;
    String? image;
    String? video;
    DateTime? createdAt;
    DateTime? updatedAt;
    bool isDeleted;
    String userId;
    int likesCount;
    int dislikesCount;
    PostEntry({
          required this.id,
          required this.title,
          required this.content,
          this.image,
          this.video,
          required this.createdAt,
          this.updatedAt,
          required this.isDeleted,
          required this.userId,
          this.likesCount=0,
          this.dislikesCount=0,
      });
    factory PostEntry.fromJson(Map<String, dynamic> json)=> PostEntry(
        id: json["id"],
        title: json["title"],
        content: json["content"],
        image: json["image"],
        video: json["video"],
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : null,
        isDeleted: json["is_deleted"],
        userId: json["user_id"],
        likesCount: json["likes_count"] ?? 0,
        dislikesCount: json["dislikes_count"] ?? 0,
    );
    Map<String, dynamic> toJson() =>{
      "id": id,
      "title": title,
      "content": content,
      "image": image,
      "video": video,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
      "is_deleted": isDeleted,
      "user_id": userId,
      "likes_count": likesCount,
      "dislikes_count": dislikesCount,
    };
}


String interactionPostFromJson(List<InteractionPost> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class InteractionPost{
  String postId;
  String userId;
  DateTime? createdAt;
  String interactionType;
  InteractionPost({
    required this.postId,
    required this.userId,
    required this.createdAt,
    required this.interactionType,
  });
  factory InteractionPost.fromJson(Map<String, dynamic> json) => InteractionPost(
    postId: json["post_id"],
    userId: json["user_id"],
    createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
    interactionType: json["interaction_type"],
  );
  Map<String, dynamic> toJson() =>{
    "post_id": postId,
    "user_id": userId,
    "created_at": createdAt?.toIso8601String(),
    "interaction_type": interactionType,
  };
}


String postSaveFromJson(List<PostSave> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class PostSave{
  String postId;
  String userId;
  DateTime? createdAt;
  PostSave({
    required this.postId,
    required this.userId,
    required this.createdAt,
  });
  factory PostSave.fromJson(Map<String, dynamic> json) => PostSave(
    postId: json["post_id"],
    userId: json["user_id"],
    createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
  );
  Map<String, dynamic> toJson() =>{
    "post_id": postId,
    "user_id": userId,
    "created_at": createdAt?.toIso8601String(),
  };
}

String postShareFromJson(List<PostShare> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class PostShare{
  String postId;
  String userId;
  DateTime? createdAt;
  PostShare({
    required this.postId,
    required this.userId,
    required this.createdAt,
  });
  factory PostShare.fromJson(Map<String, dynamic> json) => PostShare(
    postId: json["post_id"],
    userId: json["user_id"],
    createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
  );
  Map<String, dynamic> toJson() =>{
    "post_id": postId,
    "user_id": userId,
    "created_at": createdAt?.toIso8601String(),
  };
}