import 'dart:convert';
List<PostEntry> postEntryFromJson(String str) => List<PostEntry>.from(json.decode(str).map((x) => PostEntry.fromJson(x)));

String postEntryFromJson(List<PostEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class PostEntry {
    String title;
    String content;
    String? image;
    String? videoLink;
    DateTime createdAt;
    DateTime updatedAt;
    bool isDeleted;
    int userId;
    int likesCount;
    int dislikesCount;
    PostEntry({
          required this.title,
          required this.content,
          required this.image,
          required this.createdAt,
          required this.updatedAt,
          required this.isDeleted,
          required this.userId,
          this.likesCount=0,
          this.dislikesCount=0,
      });
    factory PostEntry.fromJson(Map<String, dynamic> json)=> PostEntry(
        title: json["title"],
        content: json["content"],
        image: json["image"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        isDeleted: json["is_deleted"],
        userId: json["user_id"],
        likesCount: json["likes_count"] ?? 0,
        dislikesCount: json["dislikes_count"] ?? 0,
    );
    Map<String, dynamic> toJson() =>{
      "title": title,
      "content": content,
      "image": image,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "is_deleted": isDeleted,
      "user_id": userId,
      "likes_count": likesCount,
      "dislikes_count": dislikesCount,
    };
}
List<InteractionPost> interactionPostFromJson(String str) => List<InteractionPost>.from(json.decode(str).map((x) => InteractionPost.fromJson(x)));

String interactionPostFromJson(List<InteractionPost> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class InteractionPost{
  int userId;
  DateTime createdAt;
  String interactionType;
  InteractionPost({
    required this.userId,
    required this.createdAt,
    required this.interactionType,
  });
  factory InteractionPost.fromJson(Map<String, dynamic> json) => InteractionPost(
    userId: json["user_id"],
    createdAt: json["created_at"],
    interactionType: json["interaction_type"],
  );
  Map<String, dynamic> toJson() =>{
    "user_id": userId,
    "created_at": createdAt,
    "interaction_type": interactionType,
  }
}
List<PostSave> postSaveFromJson(String str) => List<PostSave>.from(json.decode(str).map((x) => PostSave.fromJson(x)));

String postSaveFromJson(List<PostSave> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class PostSave{
  int userId;
  DateTime createdAt;
  PostSave({
    required this.userId,
    required this.createdAt,
  });
  factory PostSave.fromJson(Map<String, dynamic> json) => PostSave(
    userId: json["user_id"],
    createdAt: json["created_at"],
  );
  Map<String, dynamic> toJson() =>{
    "user_id": userId,
    "created_at": createdAt,
  }
}

class PostShare{
  int userId;
  DateTime createdAt;
  PostShare({
    required this.userId,
    required this.createdAt,
  });
  factory PostShare.fromJson(Map<String, dynamic> json) => PostShare(
    userId: json["user_id"],
    createdAt: json["created_at"],
  );
  Map<String, dynamic> toJson() =>{
    "user_id": userId,
    "created_at": createdAt,
  }
}