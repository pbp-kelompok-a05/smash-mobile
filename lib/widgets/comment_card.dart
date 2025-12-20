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
  final int? userId;
  final VoidCallback? onProfileTap;

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  late int _likes;
  late int _dislikes;
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
  }

  @override
  void didUpdateWidget(covariant CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync internal counters/reaction when parent provides updated values
    if (widget.likes != oldWidget.likes ||
        widget.dislikes != oldWidget.dislikes ||
        widget.userReaction != oldWidget.userReaction) {
      setState(() {
        _likes = widget.likes;
        _dislikes = widget.dislikes;
        _reaction = widget.userReaction;
      });
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final d = now.difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _handleLike() {
    setState(() {
      if (_reaction == 'like') {
        _reaction = null;
        _likes = (_likes - 1).clamp(0, 999999);
      } else {
        if (_reaction == 'dislike') {
          _dislikes = (_dislikes - 1).clamp(0, 999999);
        }
        _reaction = 'like';
        _likes++;
      }
    });
    widget.onLike?.call();
  }

  void _handleDislike() {
    setState(() {
      if (_reaction == 'dislike') {
        _reaction = null;
        _dislikes = (_dislikes - 1).clamp(0, 999999);
      } else {
        if (_reaction == 'like') {
          _likes = (_likes - 1).clamp(0, 999999);
        }
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
                    Text(
                      widget.author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _fmtDate(widget.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
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
                              color: _reaction == 'like'
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
                              color: _reaction == 'dislike'
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
