import 'package:flutter/material.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/widgets/default_avatar.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.item,
    this.avatarUrl,
    this.imageUrl,
    this.onProfileTap,
    this.profilePageBuilder,
    this.defaultAvatar,
    this.resolveAvatar,
    this.bustAvatarCache = true,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
    this.showMenu = false,
    this.showFooterActions = true,
    this.enableInteractions = true,
    this.onLike,
    this.onDislike,
    this.onSave,
    this.onShare,
    this.onReport,
    this.onComment,
  });

  final ProfileFeedItem item;
  final String? avatarUrl;
  final String? imageUrl;
  final VoidCallback? onProfileTap;
  final Widget Function(int userId)? profilePageBuilder;
  final String? defaultAvatar;
  final String? Function(String?)? resolveAvatar;
  final bool bustAvatarCache;
  final int? currentUserId;
  final ValueChanged<ProfileFeedItem>? onEdit;
  final ValueChanged<ProfileFeedItem>? onDelete;
  final bool showMenu;
  final bool showFooterActions;
  final bool enableInteractions;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final VoidCallback? onComment;

  String _formattedDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final day = local.day;
    final month = months[local.month - 1];
    final year = local.year;
    final sameYear = year == now.year;
    return sameYear ? '$month $day' : '$month $day $year';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = _pickAvatar();
    final avatarWithCacheBust = _bustCache(resolvedAvatar);
    final imageLink = imageUrl ?? item.image;
    final videoLink = item.videoLink ?? '';
    final isLiked = item.userInteraction == 'like';
    final isDisliked = item.userInteraction == 'dislike';
    final likeEnabled = enableInteractions && onLike != null;
    final dislikeEnabled = enableInteractions && onDislike != null;
    final commentEnabled = enableInteractions && onComment != null;
    final saveEnabled = enableInteractions && onSave != null;
    final reportEnabled = enableInteractions && onReport != null;
    final shareEnabled = enableInteractions && onShare != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF7FDF9),
        border: Border.all(color: const Color(0xFFE2F5EB)),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: Colors.white,
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => _handleProfileTap(context),
                        borderRadius: BorderRadius.circular(22),
                        child: _avatar(avatarWithCacheBust),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _handleProfileTap(context),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title.isNotEmpty ? item.title : item.user,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.user} • ${_formattedDate(item.createdAt)}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_canShowMenu)
                        _PostActionsMenu(
                          onSelected: (action) {
                            if (action == 'edit') {
                              onEdit?.call(item);
                            } else if (action == 'delete') {
                              onDelete?.call(item);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                  if (imageLink != null && imageLink.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageLink,
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ] else if (videoLink.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _YoutubePreview(
                      url: videoLink,
                      onTap: () => _openLink(videoLink, context),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFECECEC)),
            if (showFooterActions)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _countText('${item.likesCount}', 'likes'),
                        const SizedBox(width: 16),
                        _countText('${item.dislikesCount}', 'dislikes'),
                        const SizedBox(width: 16),
                        _countText('${item.commentCount}', 'comments'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _action(
                          icon: Icons.thumb_up_alt_rounded,
                          label: isLiked ? 'Liked' : 'Like',
                          color: isLiked
                              ? Colors.pink.shade400
                              : likeEnabled
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                          onTap: likeEnabled ? onLike : null,
                          bold: isLiked,
                          enabled: likeEnabled,
                        ),
                        _action(
                          icon: Icons.thumb_down_alt_rounded,
                          label: isDisliked ? 'Disliked' : 'Dislike',
                          color: isDisliked
                              ? Colors.red.shade400
                              : dislikeEnabled
                                  ? Colors.grey
                                  : Colors.grey.shade400,
                          onTap: dislikeEnabled ? onDislike : null,
                          bold: isDisliked,
                          enabled: dislikeEnabled,
                        ),
                        _action(
                          icon: Icons.chat_bubble_outline,
                          label: 'Comment',
                          color: commentEnabled
                              ? Colors.grey.shade700
                              : Colors.grey,
                          onTap: commentEnabled ? onComment : null,
                          enabled: commentEnabled,
                        ),
                        _action(
                          icon: item.isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          label: item.isSaved ? 'Saved' : 'Save',
                          color:
                              item.isSaved ? Colors.blue.shade600 : Colors.grey,
                          onTap: saveEnabled ? onSave : null,
                          bold: item.isSaved,
                          enabled: saveEnabled,
                        ),
                        _action(
                          icon: Icons.report_outlined,
                          label: 'Report',
                          color: reportEnabled
                              ? Colors.grey.shade700
                              : Colors.grey,
                          onTap: reportEnabled ? onReport : null,
                          enabled: reportEnabled,
                        ),
                        _action(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: shareEnabled
                              ? Colors.grey.shade700
                              : Colors.grey,
                          onTap: shareEnabled ? onShare : null,
                          enabled: shareEnabled,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _canShowMenu =>
      showMenu && (item.canEdit || (currentUserId != null && item.userId == currentUserId));

  Widget _avatar(String? url) {
    final valid = url != null && url.isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: valid
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholderAvatar(),
            )
          : _placeholderAvatar(),
    );
  }

  Widget _placeholderAvatar() {
    return const DefaultAvatar(size: 44);
  }

  String? _pickAvatar() {
    final resolver = resolveAvatar ?? (String? v) => v;
    final sources = <String?>[
      item.profilePhoto?.trim(),
      avatarUrl?.trim(),
      defaultAvatar,
    ];
    for (final src in sources) {
      if (src == null || src.isEmpty) continue;
      final resolved = resolver(src);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    return null;
  }

  String? _bustCache(String? url) {
    if (!bustAvatarCache || url == null || url.isEmpty) return url;
    if (defaultAvatar != null && url == defaultAvatar) return url;
    final hasQuery = url.contains('?');
    final suffix = 'v=${DateTime.now().millisecondsSinceEpoch}';
    return hasQuery ? '$url&$suffix' : '$url?$suffix';
  }

  Widget _countText(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    Color? color,
    bool bold = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? (color ?? Colors.grey.shade700) : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: enabled ? (color ?? Colors.grey.shade800) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProfileTap(BuildContext context) {
    if (onProfileTap != null) {
      onProfileTap!();
      return;
    }
    if (profilePageBuilder != null && item.userId != 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => profilePageBuilder!(item.userId),
        ),
      );
    }
  }

  String? _youtubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
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
  int? loggedInUserId;
  bool isLoadingUser = true;
  late int likesCount;
  late int dislikesCount;
  late int commentsCount;
  String? userReaction; // 'like' or 'dislike' or null
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    likesCount = widget.post.likesCount;
    dislikesCount = widget.post.dislikesCount;
    commentsCount = widget.post.commentsCount;
    userReaction = widget.post.userReaction;
    _loadLocalReactionIfMissing();
    _fetchCurrentUser();
  }
  Future<void> _fetchCurrentUser() async {
    final request = context.read<CookieRequest>();

    try {
      final user =
          await request.get("http://localhost:8000/post/me/"); // Ganti URL ke link deployment
      setState(() {
        loggedInUserId = user['id'];
        isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        isLoadingUser = false;
      });
    }
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
        setState(() {
          userReaction = val;
        });
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
        widget.post.likesCount = likesCount;
        widget.post.dislikesCount = dislikesCount;
        widget.post.userReaction = userReaction;
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
                    const SizedBox(width: 4),
                    Text('$commentsCount'),
                    const SizedBox(width: 12),
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
