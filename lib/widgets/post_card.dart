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
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'embed') return segments[1];
    return null;
  }

  String? _youtubeThumbnail(String url) {
    final id = _youtubeId(url);
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/0.jpg';
  }

  Future<void> _openLink(String url, BuildContext context) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open link is not supported in this build')),
    );
  }
}

class _PostActionsMenu extends StatelessWidget {
  const _PostActionsMenu({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.black87),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert, size: 20),
    );
  }
}

class _YoutubePreview extends StatelessWidget {
  const _YoutubePreview({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = _youtubeThumb(url);
    final displayUrl = _compactUrl(url);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    image: thumb != null
                        ? DecorationImage(
                            image: NetworkImage(thumb),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.link, color: Colors.deepPurple.shade400, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'YouTube Video',
                      style: TextStyle(
                        color: Colors.deepPurple.shade600,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    displayUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.deepPurple.shade300),
                      foregroundColor: Colors.deepPurple.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text(
                      'Open Video',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _youtubeThumb(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    String? id;
    if (uri.host.contains('youtu.be')) {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.queryParameters.containsKey('v')) {
      id = uri.queryParameters['v'];
    } else if (uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'embed') {
      id = uri.pathSegments[1];
    }
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/0.jpg';
  }

  String _compactUrl(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return link;
    String? id;
    if (uri.host.contains('youtu.be')) {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.queryParameters.containsKey('v')) {
      id = uri.queryParameters['v'];
    } else if (uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'embed') {
      id = uri.pathSegments[1];
    }
    if (id != null && id.isNotEmpty) {
      return 'https://youtu.be/$id';
    }
    return link;
  }
}
