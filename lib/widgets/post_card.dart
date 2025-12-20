// ignore_for_file: deprecated_member_use, unused_element, control_flow_in_finally, unused_import, unnecessary_import, unused_field, unnecessary_underscores, avoid_print, unused_local_variable

import 'package:flutter/material.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_detail_page.dart';
import 'package:smash_mobile/screens/edit_post.dart';
import 'package:smash_mobile/widgets/default_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/profile/profile_api.dart';

class PostCard extends StatefulWidget {
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

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late bool _isDisliked;
  late bool _isSaved;
  late int _likesCount;
  late int _dislikesCount;
  String? _reaction;
  int? _effectiveUserId;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.item.userInteraction == 'like';
    _isDisliked = widget.item.userInteraction == 'dislike';
    _isSaved = widget.item.isSaved;
    _likesCount = widget.item.likesCount;
    _dislikesCount = widget.item.dislikesCount;
    _reaction = widget.item.userInteraction;
    _effectiveUserId = widget.currentUserId;

    // If parent didn't provide currentUserId, try to infer from Profile API
    if (_effectiveUserId == null) {
      // schedule async fetch
      Future.microtask(() async {
        try {
          final request = Provider.of<CookieRequest>(context, listen: false);
          final profileApi = ProfileApi(request: request);
          final profile = await profileApi.fetchProfile();
          if (!mounted) return;
          setState(() {
            _effectiveUserId = profile.id;
          });
        } catch (_) {
          // ignore: if not logged in or failed, leave as null
        }
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = _pickAvatar();
    final avatarWithCacheBust = _bustCache(resolvedAvatar);
    final imageLink = widget.imageUrl ?? widget.item.image;
    final videoLink = widget.item.videoLink ?? '';
    final isLiked = _isLiked;
    final isDisliked = _isDisliked;
    final isSaved = _isSaved;

    return InkWell(
      onTap: widget.onTap ?? () => _defaultTapHandler(context),
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
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernHeader(context, avatarWithCacheBust),
            _buildModernContent(imageLink, videoLink, context),
            if (widget.showFooterActions)
              _buildModernFooter(isLiked, isDisliked, isSaved),
          ],
        ),
      ),
    );
  }

  // Handler default untuk navigasi
  void _defaultTapHandler(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailPage(postId: widget.item.id)),
    );
  }

  /// Header modern: avatar + online indicator + user info
  Widget _buildModernHeader(BuildContext context, String? avatarUrl) {
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
                  widget.item.title.isNotEmpty
                      ? widget.item.title
                      : widget.item.user,
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
                      widget.item.user,
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
                      _formattedDate(widget.item.createdAt),
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
          if (_canShowMenu)
            _PostActionsMenu(
              onSelected: (action) => _handleMenuAction(context, action),
            ),
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
          if (widget.item.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.item.content,
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
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Builder(
            builder: (context) {
              String displayUrl = imageLink;
              try {
                final uri = Uri.parse(imageLink);
                if (uri.scheme.isNotEmpty &&
                    !imageLink.contains('image-proxy')) {
                  final origin =
                      '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
                  displayUrl =
                      '$origin/post/image-proxy/?url=${Uri.encodeComponent(imageLink)}';
                }
              } catch (_) {}

              return Image.network(
                displayUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.3),
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
                    width: double.infinity,
                    color: Colors.blue.shade900.withOpacity(0.3),
                    child: const Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.white70,
                    ),
                  );
                },
              );
            },
          ),
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
          colors: [Colors.purple.shade900.withOpacity(0.3), Colors.transparent],
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
          count: _likesCount,
          label: 'Likes',
          color: Colors.blue.shade300,
          isActive: isLiked,
        ),
        _buildModernStatItem(
          icon: Icons.thumb_down_outlined,
          count: _dislikesCount,
          label: 'Dislikes',
          color: Colors.red.shade300,
          isActive: isDisliked,
        ),
        _buildModernStatItem(
          icon: Icons.comment_outlined,
          count: widget.item.commentCount,
          label: 'Comments',
          color: Colors.green.shade300,
          isActive: false,
        ),
        _buildModernStatItem(
          icon: Icons.share_outlined,
          count: widget.item.sharesCount,
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
            Icon(icon, size: 20, color: isActive ? color : Colors.white70),
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
          onTap: _handleLike,
          isActive: isLiked,
        ),
        _buildModernActionButton(
          icon: Icons.thumb_down_alt_rounded,
          label: isDisliked ? 'Disliked' : 'Dislike',
          color: Colors.red.shade300,
          onTap: _handleDislike,
          isActive: isDisliked,
        ),
        _buildModernActionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Comment',
          color: Colors.green.shade300,
          onTap: widget.onComment,
          isActive: false,
        ),
        _buildModernActionButton(
          icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
          label: isSaved ? 'Saved' : 'Save',
          color: Colors.amber.shade300,
          onTap: _handleSave,
          isActive: isSaved,
        ),
        _buildModernActionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          color: Colors.grey.shade400,
          onTap: widget.onShare,
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
          // If user is not logged in but interactions are enabled, show login prompt.
          onTap: (widget.enableInteractions && _effectiveUserId != null)
              ? onTap
              : (widget.enableInteractions ? () => _showLoginSnack() : null),
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
                  color: (widget.enableInteractions && _effectiveUserId != null)
                      ? (isActive ? color : Colors.white70)
                      : Colors.white38,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color:
                        (widget.enableInteractions && _effectiveUserId != null)
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
  void _handleMenuAction(BuildContext context, String action) {
    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditPostPage(post: widget.item)),
      );
    }
    if (action == 'delete' && widget.onDelete != null)
      widget.onDelete!(widget.item);
  }

  /// Cek apakah menu bisa ditampilkan
  bool get _canShowMenu =>
      (widget.showMenu &&
      (widget.item.canEdit ||
          (_effectiveUserId != null &&
              widget.item.userId == _effectiveUserId)));

  /// Pilih URL avatar dari multiple sources
  String? _pickAvatar() {
    final resolver = widget.resolveAvatar ?? (String? v) => v;
    final sources = [
      widget.item.profilePhoto?.trim(),
      widget.avatarUrl?.trim(),
      widget.defaultAvatar,
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
    if (!widget.bustAvatarCache || url == null || url.isEmpty) return url;
    if (widget.defaultAvatar != null && url == widget.defaultAvatar) return url;
    final hasQuery = url.contains('?');
    final suffix = 'v=${DateTime.now().millisecondsSinceEpoch}';
    return hasQuery ? '$url&$suffix' : '$url?$suffix';
  }

  /// Buka link (placeholder)
  Future<void> _openLink(String url, BuildContext context) async {
    if (!context.mounted) return;
    try {
      String link = url.trim();
      Uri? uri = Uri.tryParse(link);

      if (uri == null || uri.scheme.isEmpty) {
        uri = Uri.tryParse('https://$link');
      }

      if (uri == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
        return;
      }

      // Try to open with external application (browser / app)
      if (await canLaunchUrl(uri)) {
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open link')));
        }
        return;
      }

      // Fallback: attempt to resolve common YouTube formats and try app scheme
      String? id;
      final parsed = Uri.tryParse(link);
      if (parsed != null) {
        if (parsed.host.contains('youtu.be')) {
          if (parsed.pathSegments.isNotEmpty) id = parsed.pathSegments.first;
        } else if (parsed.queryParameters.containsKey('v')) {
          id = parsed.queryParameters['v'];
        } else if (parsed.pathSegments.length >= 2 &&
            parsed.pathSegments[0] == 'embed') {
          id = parsed.pathSegments[1];
        }
      }

      if (id != null && id.isNotEmpty) {
        final youtubeApp = Uri.parse('vnd.youtube:$id');
        if (await canLaunchUrl(youtubeApp)) {
          await launchUrl(youtubeApp);
          return;
        }
        final youtubeWeb = Uri.parse('https://youtu.be/$id');
        if (await canLaunchUrl(youtubeWeb)) {
          await launchUrl(youtubeWeb, mode: LaunchMode.externalApplication);
          return;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to open link')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open link: $e')));
    }
  }

  void _showLoginSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to interact with posts')),
    );
  }

  bool _ensureLoggedInOrShowSnack() {
    if (_effectiveUserId != null) return true;
    _showLoginSnack();
    return false;
  }

  Future<void> _sendInteraction(String action) async {
    try {
      final request = context.read<CookieRequest>();
      final url =
          'http://localhost:8000/post/api/posts/${widget.item.id}/$action/';
      await request.post(url, {});
    } catch (e) {
      rethrow;
    }
  }

  void _handleLike() async {
    if (!widget.enableInteractions) return;
    if (!_ensureLoggedInOrShowSnack()) return;
    final prevLiked = _isLiked;
    final prevDisliked = _isDisliked;
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount = (_likesCount - 1).clamp(0, 999999);
        _reaction = null;
      } else {
        if (_isDisliked) {
          _isDisliked = false;
          _dislikesCount = (_dislikesCount - 1).clamp(0, 999999);
        }
        _isLiked = true;
        _likesCount++;
        _reaction = 'like';
      }
    });

    try {
      await _sendInteraction('like');
      widget.onLike?.call();
    } catch (e) {
      // revert
      setState(() {
        _isLiked = prevLiked;
        _isDisliked = prevDisliked;
        _likesCount = widget.item.likesCount;
        _dislikesCount = widget.item.dislikesCount;
        _reaction = widget.item.userInteraction;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
      }
    }
  }

  void _handleDislike() async {
    if (!widget.enableInteractions) return;
    if (!_ensureLoggedInOrShowSnack()) return;
    final prevLiked = _isLiked;
    final prevDisliked = _isDisliked;
    setState(() {
      if (_isDisliked) {
        _isDisliked = false;
        _dislikesCount = (_dislikesCount - 1).clamp(0, 999999);
        _reaction = null;
      } else {
        if (_isLiked) {
          _isLiked = false;
          _likesCount = (_likesCount - 1).clamp(0, 999999);
        }
        _isDisliked = true;
        _dislikesCount++;
        _reaction = 'dislike';
      }
    });

    try {
      await _sendInteraction('dislike');
      widget.onDislike?.call();
    } catch (e) {
      // revert
      setState(() {
        _isLiked = prevLiked;
        _isDisliked = prevDisliked;
        _likesCount = widget.item.likesCount;
        _dislikesCount = widget.item.dislikesCount;
        _reaction = widget.item.userInteraction;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update dislike: $e')));
      }
    }
  }

  void _handleSave() async {
    if (!widget.enableInteractions) return;
    if (!_ensureLoggedInOrShowSnack()) return;
    final prevSaved = _isSaved;
    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      await _sendInteraction('save');
      widget.onSave?.call();
    } catch (e) {
      // revert
      setState(() {
        _isSaved = prevSaved;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update save: $e')));
      }
    }
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
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text('Edit', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
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
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
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
      } else if (uri.pathSegments.length >= 2 &&
          uri.pathSegments[0] == 'embed') {
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
      } else if (uri.pathSegments.length >= 2 &&
          uri.pathSegments[0] == 'embed') {
        id = uri.pathSegments[1];
      }

      return (id != null && id.isNotEmpty) ? 'youtu.be/$id' : link;
    } catch (e) {
      return link;
    }
  }
}
