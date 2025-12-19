// ignore_for_file: deprecated_member_use, unused_local_variable, unused_import, avoid_print, unused_element, dead_code

import 'package:flutter/material.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/widgets/default_avatar.dart';

/// Widget kartu post yang reusable untuk menampilkan:
/// - Header: avatar, username, judul, menu aksi
/// - Content: teks, gambar, atau video YouTube
/// - Footer: statistik (likes, comments, shares) dan tombol interaksi
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

  /// Format tanggal relatif (2m ago, 3h ago, Jan 15)
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

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 32,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + user info + menu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSafeAvatar(avatarWithCacheBust),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderRow(context),
                      const SizedBox(height: 2),
                      _buildPostMeta(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content: text/image/video
          _buildContentSection(imageLink, videoLink, context),
          
          // Footer: stats + action buttons
          if (showFooterActions) _buildFooterActions(isLiked, isDisliked, isSaved),
        ],
      ),
    );
  }

  /// Build avatar widget dengan validasi URL
  Widget _buildSafeAvatar(String? url) {
    final isValid = url != null && AvatarUtils.isValidImageUrl(url);
    
    return SafeAvatar(
      size: 48,
      imageUrl: isValid ? url : null,
      backgroundColor: Colors.blue.shade50,
      borderWidth: 2,
    );
  }

  /// Build header row dengan judul dan menu aksi
  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.title.isNotEmpty ? item.title : item.user,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
        ),
        if (_canShowMenu) _PostActionsMenu(onSelected: _handleMenuAction),
      ],
    );
  }

  /// Build metadata: username dan timestamp
  Widget _buildPostMeta() {
    return Text(
      '${item.user} • ${_formattedDate(item.createdAt)}',
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        overflow: TextOverflow.ellipsis,
      ),
      maxLines: 1,
    );
  }

  /// Build section konten (teks/gambar/video)
  Widget _buildContentSection(String? imageLink, String videoLink, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.content.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: Text(
                item.content,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 5,
              ),
            ),
          if (imageLink != null && imageLink.isNotEmpty)
            ..._buildImageContent(imageLink),
          if (videoLink.isNotEmpty)
            ..._buildVideoContent(videoLink, context),
        ],
      ),
    );
  }

  /// Build widget gambar dengan error builder
  List<Widget> _buildImageContent(String imageLink) {
    return [
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageLink,
          width: double.infinity,
          height: 190,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 190,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
            );
          },
        ),
      ),
    ];
  }

  /// Build widget preview video YouTube
  List<Widget> _buildVideoContent(String videoLink, BuildContext context) {
    return [
      const SizedBox(height: 12),
      _YoutubePreview(url: videoLink, onTap: () => _openLink(videoLink, context)),
    ];
  }

  /// Build footer dengan stats dan action buttons
  Widget _buildFooterActions(bool isLiked, bool isDisliked, bool isSaved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1.5)),
      ),
      child: Column(
        children: [
          _buildStatsRow(isLiked, isDisliked),
          const SizedBox(height: 12),
          _buildActionButtonsRow(isLiked, isDisliked, isSaved),
        ],
      ),
    );
  }

  /// Build row statistik (likes, dislikes, comments, shares)
  Widget _buildStatsRow(bool isLiked, bool isDisliked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(icon: Icons.thumb_up_outlined, count: item.likesCount, label: 'Likes', color: Colors.blue, active: isLiked),
        _buildStatItem(icon: Icons.thumb_down_outlined, count: item.dislikesCount, label: 'Dislikes', color: Colors.red, active: isDisliked),
        _buildStatItem(icon: Icons.comment_outlined, count: item.commentCount, label: 'Comments', color: Colors.green),
        _buildStatItem(icon: Icons.share_outlined, count: item.sharesCount, label: 'Shares', color: Colors.purple),
      ],
    );
  }

  /// Build row tombol aksi interaktif
  Widget _buildActionButtonsRow(bool isLiked, bool isDisliked, bool isSaved) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildActionButton(icon: Icons.thumb_up_alt_rounded, label: isLiked ? 'Liked' : 'Like', color: Colors.blue, onTap: onLike, enabled: enableInteractions),
        _buildActionButton(icon: Icons.thumb_down_alt_rounded, label: isDisliked ? 'Disliked' : 'Dislike', color: Colors.red, onTap: onDislike, enabled: enableInteractions),
        _buildActionButton(icon: Icons.chat_bubble_outline, label: 'Comment', color: Colors.green, onTap: onComment, enabled: enableInteractions),
        _buildActionButton(icon: isSaved ? Icons.bookmark : Icons.bookmark_outline, label: isSaved ? 'Saved' : 'Save', color: Colors.amber, onTap: onSave, enabled: enableInteractions),
        _buildActionButton(icon: Icons.share_outlined, label: 'Share', color: Colors.grey, onTap: onShare, enabled: enableInteractions),
      ],
    );
  }

  /// Build single stat item
  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    bool active = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: active ? color : Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? color : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? color : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Build single action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? Colors.grey.shade300 : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: enabled ? color : Colors.grey.shade400),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handler menu aksi (edit/delete)
  void _handleMenuAction(String action) {
    if (action == 'edit' && onEdit != null) onEdit!(item);
    if (action == 'delete' && onDelete != null) onDelete!(item);
  }

  /// Cek apakah menu bisa ditampilkan
  bool get _canShowMenu =>
      showMenu &&
      (item.canEdit || (currentUserId != null && item.userId == currentUserId));

  /// Pilih URL avatar dari multiple sources
  String? _pickAvatar() {
    final resolver = resolveAvatar ?? (String? v) => v;
    final sources = [item.profilePhoto?.trim(), avatarUrl?.trim(), defaultAvatar];
    for (final src in sources) {
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
        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.black87), SizedBox(width: 8), Text('Edit')])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
      ],
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
        child: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
      ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
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
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: thumb != null ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover) : null,
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.85), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.video_library, color: Colors.red.shade600, size: 16), const SizedBox(width: 8), Text('YouTube Video', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700, fontSize: 12))]),
                const SizedBox(height: 6),
                GestureDetector(onTap: onTap, child: Text(displayUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 12, decoration: TextDecoration.underline))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generate YouTube thumbnail URL (FIX: tanpa spasi)
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
      // FIX: Hapus spasi setelah /vi/
      return 'https://img.youtube.com/vi/$id/mqdefault.jpg';
    } catch (e) {
      return null;
    }
  }

  /// Compact URL untuk display (youtu.be/abc123)
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