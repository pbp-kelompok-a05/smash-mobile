import 'dart:convert';

List<Comment> commentFromJson(String str) =>
    List<Comment>.from(json.decode(str).map((x) => Comment.fromJson(x)));

String commentToJson(List<Comment> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Comment {
  String id;
  String content;
  String author;
  DateTime createdAt;
  DateTime updatedAt;
  int likesCount;
  int dislikesCount;
  String? userReaction;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.dislikesCount,
    this.userReaction,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json["id"]?.toString() ?? '0',
    content: json["content"] ?? '',
    author: json["author"] ?? '',
    createdAt: DateTime.tryParse(json["created_at"] ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json["updated_at"] ?? '') ??
        DateTime.tryParse(json["created_at"] ?? '') ??
        DateTime.now(),
    likesCount: json["likes_count"] is int
        ? json["likes_count"] as int
        : int.tryParse((json["likes_count"] ?? '').toString()) ?? 0,
    dislikesCount: json["dislikes_count"] is int
        ? json["dislikes_count"] as int
        : int.tryParse((json["dislikes_count"] ?? '').toString()) ?? 0,
    userReaction: json["user_reaction"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "content": content,
    "author": author,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "likes_count": likesCount,
    "dislikes_count": dislikesCount,
    "user_reaction": userReaction,
  };
}
