import 'package:flutter/material.dart';
import 'package:smash_mobile/models/post.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smash_mobile/services/post_service.dart';

String? _youtubeThumbnail(String url) {
  try {
    final uri = Uri.parse(url);
    // youtube.com/watch?v=ID or youtu.be/ID
    if ((uri.host.contains('youtube.com') &&
        uri.queryParameters['v'] != null)) {
      final id = uri.queryParameters['v']!;
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    if (uri.host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      if (id != null && id.isNotEmpty)
        return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
  } catch (_) {}
  return null;
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // ignore: avoid_print
    print('Could not launch $url');
  }
}

class PostCard extends StatefulWidget {
  final Post post;
  final Image? profileImage;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    this.profileImage,
    required this.onTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int likesCount;
  late int dislikesCount;
  String? userReaction; // 'like' or 'dislike' or null
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    likesCount = widget.post.likesCount;
    dislikesCount = widget.post.dislikesCount;
    userReaction = widget.post.userReaction;
  }

  Future<void> _handleReaction(String action) async {
    if (_processing) return;
    setState(() => _processing = true);

    final prevLikes = likesCount;
    final prevDislikes = dislikesCount;
    final prevReaction = userReaction;

    // optimistic update
    if (userReaction == action) {
      // undo
      if (action == 'like') likesCount = (likesCount - 1).clamp(0, 1 << 31);
      if (action == 'dislike')
        dislikesCount = (dislikesCount - 1).clamp(0, 1 << 31);
      userReaction = null;
    } else {
      if (action == 'like') {
        likesCount += 1;
        if (userReaction == 'dislike')
          dislikesCount = (dislikesCount - 1).clamp(0, 1 << 31);
      } else {
        dislikesCount += 1;
        if (userReaction == 'like')
          likesCount = (likesCount - 1).clamp(0, 1 << 31);
      }
      userReaction = action;
    }

    try {
      final res = await PostService().togglePostReaction(
        postId: widget.post.id,
        action: action,
        userId: '1',
      );
      setState(() {
        likesCount = (res['likes_count'] ?? likesCount) as int;
        dislikesCount = (res['dislikes_count'] ?? dislikesCount) as int;
        userReaction = res['user_reaction'];
      });
    } catch (e) {
      // revert
      setState(() {
        likesCount = prevLikes;
        dislikesCount = prevDislikes;
        userReaction = prevReaction;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to toggle: $e')));
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final profileImage = widget.profileImage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: widget.onTap,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profileImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: profileImage,
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${post.author} - ${post.createdAt.toLocal()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.imageUrl.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
                if (post.videoLink != null && post.videoLink!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final thumb = _youtubeThumbnail(post.videoLink!);
                      return GestureDetector(
                        onTap: () => _openUrl(post.videoLink!),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            thumb != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      thumb,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 180,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 180,
                                        color: Colors.black12,
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.play_arrow, size: 48),
                                    ),
                                  ),
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.black45,
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => _handleReaction('like'),
                      icon: Icon(
                        userReaction == 'like'
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 20,
                        color: userReaction == 'like'
                            ? Colors.blue
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('$likesCount'),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _handleReaction('dislike'),
                      icon: Icon(
                        userReaction == 'dislike'
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined,
                        size: 20,
                        color: userReaction == 'dislike'
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('$dislikesCount'),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment, size: 16, color: Colors.black),
                    const SizedBox(width: 16),
                    const Icon(Icons.bookmark, size: 16, color: Colors.black),
                    const Spacer(),
                    const Icon(Icons.share, size: 16, color: Colors.black),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
