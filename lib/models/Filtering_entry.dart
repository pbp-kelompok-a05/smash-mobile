// To parse this JSON data, do
//
//     final filteringEntry = filteringEntryFromJson(jsonString);

import 'dart:convert';

FilteringEntry filteringEntryFromJson(String str) =>
    FilteringEntry.fromJson(json.decode(str));

String filteringEntryToJson(FilteringEntry data) =>
    json.encode(data.toJson());

class FilteringEntry {
  final String status;
  final List<ProfileFeedItem> data;
  final Pagination pagination;

  FilteringEntry({
    required this.status,
    required this.data,
    required this.pagination,
  });

  factory FilteringEntry.fromJson(Map<String, dynamic> json) => FilteringEntry(
        status: json["status"] ?? '',
        data: (json["data"] as List<dynamic>? ?? [])
            .map((x) => ProfileFeedItem.fromJson(x))
            .toList(),
        pagination: Pagination.fromJson(
          Map<String, dynamic>.from(json["pagination"] ?? {}),
        ),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": data.map((x) => x.toJson()).toList(),
        "pagination": pagination.toJson(),
      };
}

class ProfileFeedItem {
  final int id;
  final String title;
  final String content;
  final String? image;
  final String? videoLink;
  final String user;
  final int userId;
  final DateTime createdAt;
  final int commentCount;
  final int likesCount;
  final int dislikesCount;
  final int sharesCount;
  final String? profilePhoto;
  final String? userInteraction;
  final bool isSaved;
  final bool canEdit;

  ProfileFeedItem({
    required this.id,
    required this.title,
    required this.content,
    required this.image,
    required this.videoLink,
    required this.user,
    required this.userId,
    required this.createdAt,
    required this.commentCount,
    required this.likesCount,
    required this.dislikesCount,
    required this.sharesCount,
    required this.profilePhoto,
    required this.userInteraction,
    required this.isSaved,
    required this.canEdit,
  });

  factory ProfileFeedItem.fromJson(Map<String, dynamic> json) =>
      ProfileFeedItem(
        id: json["id"] ?? 0,
        title: json["title"] ?? '',
        content: json["content"] ?? '',
        image: json["image"] as String?,
        videoLink: json["video_link"] as String?,
        user: json["user"] ?? '',
        userId: json["user_id"] ?? 0,
        createdAt:
            DateTime.tryParse(json["created_at"] ?? '') ?? DateTime.now(),
        commentCount: json["comment_count"] ?? 0,
        likesCount: json["likes_count"] ?? 0,
        dislikesCount: json["dislikes_count"] ?? 0,
        sharesCount: json["shares_count"] ?? 0,
        profilePhoto: json["profile_photo"] as String?,
        userInteraction: json["user_interaction"] as String?,
        isSaved: json["is_saved"] ?? false,
        canEdit: json["can_edit"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "content": content,
        "image": image,
        "video_link": videoLink,
        "user": user,
        "user_id": userId,
        "created_at": createdAt.toIso8601String(),
        "comment_count": commentCount,
        "likes_count": likesCount,
        "dislikes_count": dislikesCount,
        "shares_count": sharesCount,
        "profile_photo": profilePhoto,
        "user_interaction": userInteraction,
        "is_saved": isSaved,
        "can_edit": canEdit,
      };
}

class Pagination {
  final int page;
  final int perPage;
  final int total;
  final bool hasNext;

  Pagination({
    required this.page,
    required this.perPage,
    required this.total,
    required this.hasNext,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
        page: json["page"] ?? 1,
        perPage: json["per_page"] ?? 10,
        total: json["total"] ?? 0,
        hasNext: json["has_next"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "page": page,
        "per_page": perPage,
        "total": total,
        "has_next": hasNext,
      };
}
