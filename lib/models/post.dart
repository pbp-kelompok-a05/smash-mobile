class Post {
  final String id;
  final String title;
  final String content;
  final String? image;
  final String videoLink;
  final String user;
  final int userId;
  final DateTime createdAt;
  final int commentCount;
  final int likesCount;
  final int dislikesCount;
  final int sharesCount;
  final String? userInteraction;
  final bool canEdit;

  Post({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    required this.videoLink,
    required this.user,
    required this.userId,
    required this.createdAt,
    required this.commentCount,
    required this.likesCount,
    required this.dislikesCount,
    required this.sharesCount,
    this.userInteraction,
    required this.canEdit,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      image: json['image'],
      videoLink: json['video_link'] ?? '',
      user: json['user'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      commentCount: json['comment_count'],
      likesCount: json['likes_count'],
      dislikesCount: json['dislikes_count'],
      sharesCount: json['shares_count'],
      userInteraction: json['user_interaction'],
      canEdit: json['can_edit'],
    );
  }
}
