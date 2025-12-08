import 'dart:convert';
import 'package:http/http.dart' as http;
Future<void> fetchAllPostData() async {
  final uri = Uri.parse('https://<your-domain>/post/json/');
  final resp = await http.get(uri);

  if (resp.statusCode != 200) {
    throw Exception('Gagal load: ${resp.statusCode}');
  }

  final data = jsonDecode(resp.body);

  List<CommentEntry> comments =
      (data['comments'] as List).map((e) => CommentEntry.fromJson(e)).toList();

  List<InteractionComment> interactions =
      (data['comment_interactions'] as List)
          .map((e) => InteractionComment.fromJson(e))
          .toList();

}


String postEntryFromJson(List<CommentEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class CommentEntry {
  String id;
  String postId;
  String parentId;
  String userId;
  String content;
  String emoji;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool isDeleted;
  int likesCount;
  int dislikesCount;
  CommentEntry({
    required this.id,
    required this.postId,
    required this.parentId,
    required this.userId,
    required this.content,
    required this.emoji,
    required this.createdAt,
    this.updatedAt,
    required this.isDeleted,
    this.likesCount=0,
    this.dislikesCount=0,
  });
  factory CommentEntry.fromJson(Map<String,dynamic> json)=>  CommentEntry(
        id: json["id"],
        postId: json["post_id"],
        parentId: json["parent_id"],
        userId: json["user_id"],
        content: json["content"],
        emoji: json["emoji"],
        createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
        updatedAt: json["updated_at"] != null
            ? DateTime.parse(json["updated_at"])
            : null,
        isDeleted: json["is_deleted"],
        likesCount: json["likes_count"] ?? 0,
        dislikesCount: json["dislikes_count"] ?? 0,
    );
  Map<String,dynamic> toJson() => {
    "id": id,
    "post_id": postId,
    "parent_id": parentId,
    "user_id": userId,
    "content": content,
    "emoji": emoji,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "is_deleted": isDeleted,
    "likes_count": likesCount,
    "dislikes_count": dislikesCount,
  };
}

String interactionPostFromJson(List<InteractionComment> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class InteractionComment{
  String commentId;
  String userId;
  DateTime? createdAt;
  String interactionType;
  InteractionComment({
    required this.commentId,
    required this.userId,
    required this.createdAt,
    required this.interactionType,
  });
  factory InteractionComment.fromJson(Map<String, dynamic> json) => InteractionComment(
    commentId: json["comment_id"],
    userId: json["user_id"],
    createdAt: json["created_at"] != null
            ? DateTime.parse(json["created_at"])
            : null,
    interactionType: json["interaction_type"],
  );
  Map<String, dynamic> toJson() =>{
    "comment_id": commentId,
    "user_id": userId,
    "created_at": createdAt?.toIso8601String(),
    "interaction_type": interactionType,
  };
}