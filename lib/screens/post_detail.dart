import 'package:flutter/material.dart';
import 'package:smash_mobile/models/post.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smash_mobile/models/comment.dart';
import 'package:smash_mobile/widgets/comment_card.dart';
import 'package:smash_mobile/services/post_service.dart';

String? _youtubeThumbnail(String url) {
  try {
    final uri = Uri.parse(url);
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

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final Image? profileImage;

  const PostDetailScreen({super.key, required this.post, this.profileImage});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _posting = false;
  late int likesCount;
  late int dislikesCount;
  late int commentsCount;
  String? userReaction;
  bool _processing = false;

  Widget _section({required Widget child, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    _commentsFuture = PostService().fetchComments(widget.post.id, userId: '1');
    likesCount = widget.post.likesCount;
    dislikesCount = widget.post.dislikesCount;
    commentsCount = widget.post.commentsCount;
    userReaction = widget.post.userReaction;
    _loadLocalReactionIfMissing();
  }

  Future<void> _loadLocalReactionIfMissing() async {
    if (userReaction != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('post_reactions');
      if (stored == null || stored.isEmpty) return;
      final Map<String, dynamic> reactions = json.decode(stored);
      final key = widget.post.id.toString();
      if (!reactions.containsKey(key)) return;
      final val = reactions[key];
      if (val is String) {
        setState(() => userReaction = val);
      } else if (val is Map) {
        setState(() {
          userReaction = val['user_reaction'] as String?;
          try {
            if (val['likes_count'] != null)
              likesCount = val['likes_count'] as int;
          } catch (_) {}
          try {
            if (val['dislikes_count'] != null)
              dislikesCount = val['dislikes_count'] as int;
          } catch (_) {}
          try {
            if (val['comments_count'] != null)
              commentsCount = val['comments_count'] as int;
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await PostService().createComment(
        postId: widget.post.id,
        content: text,
        userId: '1',
      );
      _commentController.clear();
      setState(() {
        _commentsFuture = PostService().fetchComments(
          widget.post.id,
          userId: '1',
        );
        commentsCount += 1;
        widget.post.commentsCount = commentsCount;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment posted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
    } finally {
      setState(() => _posting = false);
    }
  }

  Future<void> _handleReaction(String action) async {
    if (_processing) return;
    setState(() => _processing = true);

    final prevLikes = likesCount;
    final prevDislikes = dislikesCount;
    final prevReaction = userReaction;

    // optimistic update
    if (userReaction == action) {
      if (action == 'like')
        likesCount = (likesCount - 1).clamp(0, 1 << 31) as int;
      if (action == 'dislike')
        dislikesCount = (dislikesCount - 1).clamp(0, 1 << 31) as int;
      userReaction = null;
    } else {
      if (action == 'like') {
        likesCount += 1;
        if (userReaction == 'dislike')
          dislikesCount = (dislikesCount - 1).clamp(0, 1 << 31) as int;
      } else {
        dislikesCount += 1;
        if (userReaction == 'like')
          likesCount = (likesCount - 1).clamp(0, 1 << 31) as int;
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
        // persist to the Post so callers can read updated state
        widget.post.likesCount = likesCount;
        widget.post.dislikesCount = dislikesCount;
        widget.post.userReaction = userReaction;
      });
    } catch (e) {
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, widget.post);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: Text(post.title),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD6F5E4), // Light Green (Top)
                Color(0xFFFFECEF), // Light Pink (Bottom)
              ],
              stops: [0.3, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                profileImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: profileImage,
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey[300],
                                        child: Icon(
                                          Icons.person,
                                          size: 32,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.author,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${post.createdAt.toLocal()}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (post.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  post.imageUrl.toString(),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (post.videoLink != null &&
                                post.videoLink!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  final thumb = _youtubeThumbnail(
                                    post.videoLink!,
                                  );
                                  return GestureDetector(
                                    onTap: () => _openUrl(post.videoLink!),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        thumb != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  thumb,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: 200,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        height: 200,
                                                        color: Colors.black12,
                                                      ),
                                                ),
                                              )
                                            : Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.black12,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.play_arrow,
                                                    size: 48,
                                                  ),
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
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _handleReaction('like'),
                                  icon: Icon(
                                    userReaction == 'like'
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                    size: 18,
                                    color: userReaction == 'like'
                                        ? Colors.blue
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('$likesCount'),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () => _handleReaction('dislike'),
                                  icon: Icon(
                                    userReaction == 'dislike'
                                        ? Icons.thumb_down
                                        : Icons.thumb_down_outlined,
                                    size: 18,
                                    color: userReaction == 'dislike'
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('$dislikesCount'),
                                const Spacer(),
                                const Icon(Icons.share, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _section(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          _posting
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: _submitComment,
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Comment>>(
                      future: _commentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading comments: ${snapshot.error}',
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(child: Text('No comments'));
                        }

                        final comments = snapshot.data!;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (commentsCount != comments.length) {
                            setState(() {
                              commentsCount = comments.length;
                              widget.post.commentsCount = commentsCount;
                            });
                          }
                        });
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final c = comments[idx];
                            return CommentCard(comment: c, onTap: () {});
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
