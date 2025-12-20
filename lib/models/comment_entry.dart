import 'dart:convert';

List<Comment> commentFromJson(String str) =>
    List<Comment>.from(json.decode(str).map((x) => Comment.fromJson(x)));

String commentToJson(List<Comment> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Comment {
  String id;
  String content;
  String author;
  int? userId;
  DateTime createdAt;
  DateTime updatedAt;
  int likesCount;
  int dislikesCount;
  String? userReaction;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    this.userId,
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
    userId: (() {
      try {
        final candidates = [
          json['user'],
          json['user_id'],
          json['author_id'],
          json['author'],
        ];
        for (var v in candidates) {
          if (v == null) continue;
          if (v is int) return v;
          if (v is String) {
            final p = int.tryParse(v);
            if (p != null) return p;
            // try to decode JSON string
            try {
              final dec = jsonDecode(v);
              if (dec is Map) {
                if (dec['id'] is int) return dec['id'] as int;
                if (dec['pk'] is int) return dec['pk'] as int;
                if (dec['id'] is String) return int.tryParse(dec['id']);
                if (dec['pk'] is String) return int.tryParse(dec['pk']);
              }
            } catch (_) {}
            continue;
          }
          if (v is Map) {
            if (v['id'] is int) return v['id'] as int;
            if (v['pk'] is int) return v['pk'] as int;
            if (v['id'] is String) return int.tryParse(v['id']);
            if (v['pk'] is String) return int.tryParse(v['pk']);
          }
        }
      } catch (_) {}
      return null;
    })(),
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
    userReaction:
        json["user_reaction"]?.toString() ??
        json["user_interaction"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "content": content,
    "author": author,
    "user_id": userId,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "likes_count": likesCount,
    "dislikes_count": dislikesCount,
    "user_reaction": userReaction,
  };
}
