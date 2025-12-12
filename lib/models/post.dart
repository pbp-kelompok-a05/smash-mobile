import 'dart:convert';

List<Post> postFromJson(String str) =>
    List<Post>.from(json.decode(str).map((x) => Post.fromJson(x)));

String postToJson(List<Post> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Post {
  String id;
  String title;
  String content;
  String author;
  dynamic imageUrl;
  String? videoLink;
  DateTime createdAt;
  DateTime updatedAt;
  int likesCount;
  int dislikesCount;
  int sharesCount;
  bool isDeleted;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    this.imageUrl,
    this.videoLink,
    required this.createdAt,
    required this.updatedAt,
    required this.likesCount,
    required this.dislikesCount,
    required this.sharesCount,
    required this.isDeleted,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json["id"],
    title: json["title"],
    content: json["content"],
    author: json["author"],
    imageUrl: json["image_url"],
    videoLink: json["video_link"],
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
    likesCount: json["likes_count"],
    dislikesCount: json["dislikes_count"],
    sharesCount: json["shares_count"],
    isDeleted: json["is_deleted"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "content": content,
    "author": author,
    "image_url": imageUrl,
    "video_link": videoLink,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "likes_count": likesCount,
    "dislikes_count": dislikesCount,
    "shares_count": sharesCount,
    "is_deleted": isDeleted,
  };
}
