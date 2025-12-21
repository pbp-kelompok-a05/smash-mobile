// ignore_for_file: unused_field, avoid_print
import 'package:flutter/material.dart';
import 'package:smash_mobile/profile/profile_page.dart';

/// Simple comment card styled similarly to PostCard but compact.
class CommentCard extends StatefulWidget {
  const CommentCard({
    super.key,
    required this.id,
    required this.author,
    required this.content,
    this.avatarUrl,
    this.createdAt,
    this.likes = 0,
    this.dislikes = 0,
    this.userReaction,
    this.onLike,
    this.onDislike,
    this.canEdit = false,
    this.onDelete,
    this.userId,
    this.onProfileTap,
  });

  final String id;
  final String author;
  final String content;
  final String? avatarUrl;
  final DateTime? createdAt;
  final int likes;
  final int dislikes;
  final String? userReaction; // 'like' | 'dislike' | null

  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final bool canEdit;
  final VoidCallback? onDelete;
  final int? userId;
  final VoidCallback? onProfileTap;

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late int _likes;
  late int _dislikes;
  late bool _isLiked;
  late bool _isDisliked;
  String? _reaction;

  void _handleAvatarTap() {
    if (widget.onProfileTap != null) {
      widget.onProfileTap!.call();
      return;
    }
    if (widget.userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.userId)),
      );
      print('CommentCard: navigated to ProfilePage userId=${widget.userId}');
      return;
    }
    // Debug / fallback: inform user and log
    print(
      'CommentCard: userId is null for comment id=${widget.id}, author=${widget.author}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open profile: user id missing'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _likes = widget.likes;
    _dislikes = widget.dislikes;
    _reaction = widget.userReaction;
    _isLiked = widget.userReaction == 'like';
    _isDisliked = widget.userReaction == 'dislike';
  }

  @override
  void didUpdateWidget(covariant CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the comment identity changed (widget reused by list), fully
    // reinitialize internal state from the new widget to avoid showing
    // stale reaction/counts from the previous comment.
    if (widget.id != oldWidget.id) {
      setState(() {
        _likes = widget.likes;
        _dislikes = widget.dislikes;
        _reaction = widget.userReaction;
        _isLiked = widget.userReaction == 'like';
        _isDisliked = widget.userReaction == 'dislike';
      });
      return;
    }
    // Sync internal counters/reaction when parent provides updated values.
    // Important: don't overwrite the local `_reaction` when only counts
    // (likes/dislikes) change — otherwise a parent update that only
    // refreshes counts would clear the user's reaction state.
    final countsChanged =
        widget.likes != oldWidget.likes ||
        widget.dislikes != oldWidget.dislikes;
    final reactionChanged = widget.userReaction != oldWidget.userReaction;

    if (reactionChanged) {
      setState(() {
        _likes = widget.likes;
        _dislikes = widget.dislikes;
        _reaction = widget.userReaction;
        _isLiked = widget.userReaction == 'like';
        _isDisliked = widget.userReaction == 'dislike';
      });
    } else if (countsChanged) {
      setState(() {
        _likes = widget.likes;
        _dislikes = widget.dislikes;
        // keep existing `_reaction` — don't overwrite with possibly-null
        // `widget.userReaction` when only counts updated.
      });
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = local.day;
    final month = months[local.month - 1];
    final year = local.year;
    final sameYear = year == now.year;
    return sameYear ? '$month $day' : '$month $day $year';
  }

  void _handleLike() {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _reaction = null;
        _likes = (_likes - 1).clamp(0, 999999);
      } else {
        if (_isDisliked) {
          _isDisliked = false;
          _dislikes = (_dislikes - 1).clamp(0, 999999);
        }
        _isLiked = true;
        _reaction = 'like';
        _likes++;
      }
    });
    widget.onLike?.call();
  }

  void _handleDislike() {
    setState(() {
      if (_isDisliked) {
        _isDisliked = false;
        _reaction = null;
        _dislikes = (_dislikes - 1).clamp(0, 999999);
      } else {
        if (_isLiked) {
          _isLiked = false;
          _likes = (_likes - 1).clamp(0, 999999);
        }
        _isDisliked = true;
        _reaction = 'dislike';
        _dislikes++;
      }
    });
    widget.onDislike?.call();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.avatarUrl;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _handleAvatarTap,
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: (avatar != null && avatar.isNotEmpty)
                  ? NetworkImage(avatar)
                  : null,
              child: (avatar == null || avatar.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: Colors.white70)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _handleAvatarTap,
                      child: Text(
                        widget.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _fmtDate(widget.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          onSelected: (value) {
                            if (value == 'like') {
                              _handleLike();
                              return;
                            }
                            if (value == 'dislike') {
                              _handleDislike();
                              return;
                            }
                            if (value == 'delete' && widget.canEdit) {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete comment?'),
                                  content: const Text(
                                    'This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ).then((confirmed) {
                                if (confirmed == true) {
                                  widget.onDelete?.call();
                                }
                              });
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'like',
                              child: Text('Like'),
                            ),
                            const PopupMenuItem(
                              value: 'dislike',
                              child: Text('Dislike'),
                            ),
                            if (widget.canEdit)
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red.shade600),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(widget.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: _handleLike,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              size: 16,
                              color: _isLiked
                                  ? Colors.blue
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_likes',
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _handleDislike,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.thumb_down,
                              size: 16,
                              color: _isDisliked
                                  ? Colors.red
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_dislikes',
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
