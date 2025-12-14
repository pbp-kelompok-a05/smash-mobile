import 'package:flutter/material.dart';
import 'package:smash_mobile/models/comment.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smash_mobile/services/post_service.dart';

class CommentCard extends StatefulWidget {
  final Comment comment;
  final Image? profileImage;

  final VoidCallback onTap;

  const CommentCard({
    super.key,
    required this.comment,
    this.profileImage,

    required this.onTap,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late int likes;
  late int dislikes;
  String? userReaction;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    likes = widget.comment.likesCount;
    dislikes = widget.comment.dislikesCount;
    userReaction = widget.comment.userReaction;
    _loadLocalReactionIfMissing();
  }

  Future<void> _loadLocalReactionIfMissing() async {
    if (userReaction != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('comment_reactions');
      if (stored == null || stored.isEmpty) return;
      final Map<String, dynamic> reactions = json.decode(stored);
      final key = widget.comment.id.toString();
      if (!reactions.containsKey(key)) return;
      final val = reactions[key];
      if (val is String) {
        setState(() => userReaction = val);
      } else if (val is Map) {
        setState(() {
          userReaction = val['user_reaction'] as String?;
          try {
            if (val['likes_count'] != null) likes = val['likes_count'] as int;
          } catch (_) {}
          try {
            if (val['dislikes_count'] != null)
              dislikes = val['dislikes_count'] as int;
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  Future<void> _handleReaction(String action) async {
    if (_processing) return;
    setState(() => _processing = true);

    final prevLikes = likes;
    final prevDislikes = dislikes;
    final prevReaction = userReaction;

    // optimistic
    if (userReaction == action) {
      if (action == 'like') likes = (likes - 1).clamp(0, 1 << 31);
      if (action == 'dislike') dislikes = (dislikes - 1).clamp(0, 1 << 31);
      userReaction = null;
    } else {
      if (action == 'like') {
        likes += 1;
        if (userReaction == 'dislike')
          dislikes = (dislikes - 1).clamp(0, 1 << 31);
      } else {
        dislikes += 1;
        if (userReaction == 'like') likes = (likes - 1).clamp(0, 1 << 31);
      }
      userReaction = action;
    }

    try {
      final res = await PostService().toggleCommentReaction(
        commentId: widget.comment.id,
        action: action,
        userId: '1',
      );
      setState(() {
        likes = (res['likes_count'] ?? likes) as int;
        dislikes = (res['dislikes_count'] ?? dislikes) as int;
        userReaction = res['user_reaction'];
        // persist to model so callers can observe
        widget.comment.likesCount = likes;
        widget.comment.dislikesCount = dislikes;
        widget.comment.userReaction = userReaction;
      });
    } catch (e) {
      setState(() {
        likes = prevLikes;
        dislikes = prevDislikes;
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
                    widget.profileImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: widget.profileImage,
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
                            widget.comment.author,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.comment.createdAt.toLocal()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.comment.content,
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
                        size: 18,
                        color: userReaction == 'like'
                            ? Colors.blue
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('$likes'),
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
                    const SizedBox(width: 4),
                    Text('$dislikes'),
                    const Spacer(),
                    const Icon(Icons.reply, size: 16, color: Colors.black),
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
