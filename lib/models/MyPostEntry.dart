// To parse this JSON data, do
//
//     final myPostEntry = myPostEntryFromJson(jsonString);

import 'dart:convert';

List<MyPostEntry> myPostEntryFromJson(String str) => List<MyPostEntry>.from(json.decode(str).map((x) => MyPostEntry.fromJson(x)));

String myPostEntryToJson(List<MyPostEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MyPostEntry {
    String title;
    String content;
    String? image;
    String urlVid;
    DateTime createdAt;
    String userName;
    int authorId;

    MyPostEntry({
        required this.title,
        required this.content,
        required this.image,
        required this.urlVid,
        required this.createdAt,
        required this.userName,
        required this.authorId,
    });

    factory MyPostEntry.fromJson(Map<String, dynamic> json) => MyPostEntry(
        title: json["title"],
        content: json["content"],
        image: json["image"],
        urlVid: json["url_vid"],
        createdAt: DateTime.parse(json["created_at"]),
        userName: json["user_name"],
        authorId: json["author_id"],
    );

    Map<String, dynamic> toJson() => {
        "title": title,
        "content": content,
        "image": image,
        "url_vid": urlVid,
        "created_at": createdAt.toIso8601String(),
        "user_name": userName,
        "author_id": authorId,
    };
}
