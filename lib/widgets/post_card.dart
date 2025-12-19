// ignore_for_file: deprecated_member_use, unused_element, control_flow_in_finally, unused_import, unnecessary_import, unused_field, unnecessary_underscores, avoid_print, unused_local_variable

import 'package:flutter/material.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_detail_page.dart';
import 'package:smash_mobile/screens/edit_post.dart';
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
    this.onTap,
  });

  // Data post
  final ProfileFeedItem item;
  final String? avatarUrl;
  final String? imageUrl;

  // Navigasi
  final VoidCallback? onProfileTap;
  final Widget Function(int userId)? profilePageBuilder;

  // Avatar
  final String? defaultAvatar;
  final String? Function(String?)? resolveAvatar;
  final bool bustAvatarCache;

  // User & permission
  final int? currentUserId;
  final bool showMenu;
  final bool showFooterActions;
  final bool enableInteractions;

  // Callbacks
  final ValueChanged<ProfileFeedItem>? onEdit;
  final ValueChanged<ProfileFeedItem>? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final VoidCallback? onComment;
  final VoidCallback? onTap;

  /// Format timestamp menjadi "2m ago", "3h ago", "Jan 15"
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
    final isSaved = item.isSaved;

    return InkWell(
      onTap: onTap ?? () => _defaultTapHandler(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F2027), // Biru tua
              const Color(0xFF203A43), // Biru keunguan
              const Color(0xFF2C5364), // Ungu tua
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(avatarWithCacheBust),
            _buildModernContent(imageLink, videoLink, context),
            if (showFooterActions) _buildModernFooter(isLiked, isDisliked, isSaved),
          ],
        ),
      ),
    );
  }

  // Handler default untuk navigasi
  void _defaultTapHandler(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(postId: item.id),
      ),
    );
  }

  /// Header modern: avatar + online indicator + user info
  Widget _buildModernHeader(String? avatarUrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900.withOpacity(0.3),
            Colors.purple.shade900.withOpacity(0.2),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          _buildAvatarWithIndicator(avatarUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isNotEmpty ? item.title : item.user,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      item.user,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade300,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      _formattedDate(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_canShowMenu) _PostActionsMenu(onSelected: _handleMenuAction),
        ],
      ),
    );
  }

  /// Avatar 56px + online indicator hijau
  Widget _buildAvatarWithIndicator(String? avatarUrl) {
    final isValid = avatarUrl != null && AvatarUtils.isValidImageUrl(avatarUrl);
    return Stack(
      children: [
        SafeAvatar(
          size: 56,
          imageUrl: isValid ? avatarUrl : null,
          backgroundColor: Colors.blue.shade700,
          borderWidth: 3,
          borderColor: Colors.white30,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  /// Content: teks + gambar/video yang stylish
  Widget _buildModernContent(
    String? imageLink,
    String videoLink,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                item.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (imageLink != null && imageLink.isNotEmpty)
            _buildModernImage(imageLink),
          if (videoLink.isNotEmpty) _buildModernVideo(videoLink, context),
        ],
      ),
    );
  }

  /// Gambar 220px dengan loading shimmer dan shadow
  Widget _buildModernImage(String imageLink) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          imageLink,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.broken_image,
                size: 48,
                color: Colors.white70,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Video preview dengan play button yang lebih stylish
  Widget _buildModernVideo(String videoLink, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: _YoutubePreview(
        url: videoLink,
        onTap: () => _openLink(videoLink, context),
      ),
    );
  }

  /// Footer: stats + action buttons yang responsif
  Widget _buildModernFooter(bool isLiked, bool isDisliked, bool isSaved) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.purple.shade900.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildModernStatsRow(isLiked, isDisliked),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Colors.white24),
          const SizedBox(height: 16),
          _buildModernActionButtonsRow(isLiked, isDisliked, isSaved),
        ],
      ),
    );
  }

  /// Stats row dengan animasi scale
  Widget _buildModernStatsRow(bool isLiked, bool isDisliked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildModernStatItem(
          icon: Icons.thumb_up_outlined,
          count: item.likesCount,
          label: 'Likes',
          color: Colors.blue.shade300,
          isActive: isLiked,
        ),
        _buildModernStatItem(
          icon: Icons.thumb_down_outlined,
          count: item.dislikesCount,
          label: 'Dislikes',
          color: Colors.red.shade300,
          isActive: isDisliked,
        ),
        _buildModernStatItem(
          icon: Icons.comment_outlined,
          count: item.commentCount,
          label: 'Comments',
          color: Colors.green.shade300,
          isActive: false,
        ),
        _buildModernStatItem(
          icon: Icons.share_outlined,
          count: item.sharesCount,
          label: 'Shares',
          color: Colors.purple.shade300,
          isActive: false,
        ),
      ],
    );
  }

  /// Stat item dengan animasi scale
  Widget _buildModernStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required bool isActive,
  }) {
    return Expanded(
      child: AnimatedScale(
        scale: isActive ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? color : Colors.white70,
            ),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? color : Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? color : Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Action buttons dengan ripple effect yang lebih baik
  Widget _buildModernActionButtonsRow(
    bool isLiked,
    bool isDisliked,
    bool isSaved,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildModernActionButton(
          icon: Icons.thumb_up_alt_rounded,
          label: isLiked ? 'Liked' : 'Like',
          color: Colors.blue.shade300,
          onTap: onLike,
          isActive: isLiked,
        ),
        _buildModernActionButton(
          icon: Icons.thumb_down_alt_rounded,
          label: isDisliked ? 'Disliked' : 'Dislike',
          color: Colors.red.shade300,
          onTap: onDislike,
          isActive: isDisliked,
        ),
        _buildModernActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Comment',
          color: Colors.green.shade300,
          onTap: onComment,
          isActive: false,
        ),
        _buildModernActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
          label: isSaved ? 'Saved' : 'Save',
          color: Colors.amber.shade300,
          onTap: onSave,
          isActive: isSaved,
        ),
        _buildModernActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          color: Colors.grey.shade400,
          onTap: onShare,
          isActive: false,
        ),
      ],
    );
  }

  /// Action button dengan ripple effect
  Widget _buildModernActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required bool isActive,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enableInteractions ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.4),
          highlightColor: color.withOpacity(0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isActive ? color.withOpacity(0.2) : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: enableInteractions
                      ? (isActive ? color : Colors.white70)
                      : Colors.white38,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: enableInteractions
                        ? (isActive ? color : Colors.white70)
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handler menu aksi (edit/delete)
  void _handleMenuAction(String action) {
    if (action == 'edit') {
      // Navigasi ke halaman edit
      Navigator.push(
        context!,
        MaterialPageRoute(
          builder: (_) => EditPostPage(post: item),
        ),
      );
    }
    if (action == 'delete' && onDelete != null) onDelete!(item);
  }

  /// Cek apakah menu bisa ditampilkan
  bool get _canShowMenu =>
      showMenu &&
      (item.canEdit || (currentUserId != null && item.userId == currentUserId));
      
        BuildContext? get context => null;

  /// Pilih URL avatar dari multiple sources
  String? _pickAvatar() {
    final resolver = resolveAvatar ?? (String? v) => v;
    final sources = [
      item.profilePhoto?.trim(),
      avatarUrl?.trim(),
      defaultAvatar,
    ];
    for (var src in sources) {
      if (src == null || src.isEmpty) continue;
      final resolved = resolver(src);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    return null;
  }

  /// Tambahkan cache buster ke URL avatar
  String? _bustCache(String? url) {
    if (!bustAvatarCache || url == null || url.isEmpty) return url;
    if (defaultAvatar != null && url == defaultAvatar) return url;
    final hasQuery = url.contains('?');
    final suffix = 'v=${DateTime.now().millisecondsSinceEpoch}';
    return hasQuery ? '$url&$suffix' : '$url?$suffix';
  }

  /// Buka link (placeholder)
  Future<void> _openLink(String url, BuildContext context) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open link not supported in this build')),
    );
  }
}

/// Widget menu aksi untuk post (edit/delete)
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
          child: Row(children: [
            Icon(Icons.edit, size: 18, color: Colors.white70),
            SizedBox(width: 8),
            Text('Edit', style: TextStyle(color: Colors.white70)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete, size: 18, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ]),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, size: 18, color: Colors.white70),
      ),
      color: const Color(0xFF203A43), // Background menu gelap
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

/// Widget preview video YouTube dengan thumbnail
class _YoutubePreview extends StatelessWidget {
  const _YoutubePreview({required this.url, required this.onTap});
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = _youtubeThumb(url);
    final displayUrl = _compactUrl(url);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.3),
                      image: thumb != null
                          ? DecorationImage(
                              image: NetworkImage(thumb),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF203A43),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.video_library,
                    color: Colors.red.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'YouTube Video',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      displayUrl,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate YouTube thumbnail URL
  String? _youtubeThumb(String link) {
    try {
      final uri = Uri.tryParse(link);
      if (uri == null) return null;

      String? id;
      if (uri.host.contains('youtu.be')) {
        id = uri.pathSegments.firstOrNull;
      } else if (uri.queryParameters.containsKey('v')) {
        id = uri.queryParameters['v'];
      } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
        id = uri.pathSegments[1];
      }

      if (id == null || id.isEmpty) return null;
      return 'https://img.youtube.com/vi/$id/mqdefault.jpg';
    } catch (e) {
      return null;
    }
  }

  /// Compact URL untuk display
  String _compactUrl(String link) {
    try {
      final uri = Uri.tryParse(link);
      if (uri == null) return link;

      String? id;
      if (uri.host.contains('youtu.be')) {
        id = uri.pathSegments.firstOrNull;
      } else if (uri.queryParameters.containsKey('v')) {
        id = uri.queryParameters['v'];
      } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
        id = uri.pathSegments[1];
      }

      return (id != null && id.isNotEmpty) ? 'youtu.be/$id' : link;
    } catch (e) {
      return link;
    }
  }
}