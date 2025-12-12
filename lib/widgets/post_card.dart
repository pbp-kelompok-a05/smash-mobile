import 'package:flutter/material.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.item,
    this.avatarUrl,
    this.imageUrl,
    this.onProfileTap,
    this.onEdit,
    this.onDelete,
    this.showMenu = false,
    this.showFooterActions = true,
  });

  final ProfileFeedItem item;
  final String? avatarUrl;
  final String? imageUrl;
  final VoidCallback? onProfileTap;
  final ValueChanged<ProfileFeedItem>? onEdit;
  final ValueChanged<ProfileFeedItem>? onDelete;
  final bool showMenu;
  final bool showFooterActions;

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
    final resolvedAvatar = (avatarUrl != null && avatarUrl!.isNotEmpty)
        ? avatarUrl
        : null;
    final imageLink = imageUrl ?? item.image;
    final videoLink = item.videoLink ?? '';
    final isLiked = item.userInteraction == 'like';
    final isDisliked = item.userInteraction == 'dislike';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(22),
                    child: _avatar(resolvedAvatar),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
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
                          '${item.user}  |  ${_formattedDate(item.createdAt)}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showMenu && item.canEdit)
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
                    height: 180,
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
              if (showFooterActions) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${item.likesCount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('likes', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    Text(
                      '${item.dislikesCount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('dislikes', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    Text(
                      '${item.commentCount}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('comments', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: 14,
                      color: isLiked
                          ? Colors.pink.shade400
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Liked',
                      style: TextStyle(
                        fontSize: 11,
                        color: isLiked
                            ? Colors.pink.shade400
                            : Colors.grey.shade800,
                        fontWeight: isLiked ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.thumb_down,
                      size: 14,
                      color: isDisliked
                          ? Colors.red.shade400
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Dislike',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDisliked
                            ? Colors.red.shade400
                            : Colors.grey.shade800,
                        fontWeight:
                            isDisliked ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.comment, size: 14, color: Colors.black87),
                    const SizedBox(width: 3),
                    const Text(
                      'Comment',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      item.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 16,
                      color: item.isSaved
                          ? Colors.green.shade600
                          : Colors.grey.shade800,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.isSaved
                            ? Colors.green.shade700
                            : Colors.grey.shade800,
                        fontWeight:
                            item.isSaved ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.share_outlined, size: 14),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

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
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 22, color: Colors.grey.shade600),
    );
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
