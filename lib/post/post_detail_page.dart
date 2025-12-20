// ignore_for_file: deprecated_member_use, unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_api.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/widgets/post_card.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final int postId;
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PostApi _api;
  late ProfileApi _profileApi;
  ProfileFeedItem? _item;
  bool _loading = true;
  String? _error;
  int? _currentUserId;

  // NEW: Modern colors
  static const Color _primaryColor = Color(0xFF667EEA);
  static const Color _secondaryColor = Color(0xFF764BA2);

  String? _resolveMediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('/')) return '${_api.baseUrl}$trimmed';
    return '${_api.baseUrl}/$trimmed';
  }

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _api = PostApi(request: request);
    _profileApi = ProfileApi(request: request);
    _loadCurrentUser();
    _load();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final me = await _profileApi.fetchProfile();
      if (!mounted) return;
      setState(() {
        _currentUserId = me.id;
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchPostDetail(widget.postId);
      if (!mounted) return;
      setState(() {
        _item = data as ProfileFeedItem?;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      // NEW: Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _handleShare,
                ),
              ],
            ),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_item == null) {
      return _buildEmptyState();
    }

    final item = _item!;
    final avatar = _api.resolveMediaUrl(item.profilePhoto);
    final defaultAvatar =
        _api.resolveMediaUrl('/static/images/user-profile.png') ??
        '${_api.baseUrl}/static/images/user-profile.png';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Glassmorphism card
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: PostCard(
              item: item,
              avatarUrl: avatar,
              imageUrl: _api.resolveMediaUrl(item.image),
              defaultAvatar: defaultAvatar,
              resolveAvatar: _api.resolveMediaUrl,
              showMenu: true,
              currentUserId: _currentUserId,
              showFooterActions: true,
              enableInteractions: true,
              profilePageBuilder: (id) => ProfilePage(userId: id),
              // NEW: Interaction handlers
              onLike: _handleLike,
              onDislike: _handleDislike,
              onSave: _handleSave,
              onComment: _handleComment,
              onShare: _handleShare,
              // Disable tap on detail page (avoid recursion)
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          // Comments section
          _buildCommentsSection(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Post not found',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Placeholder untuk komentar
          Text(
            'Comments feature coming soon...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Handler interactions (implementasi API)
  Future<void> _handleLike() async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Like action triggered')));
    // Implementasi: await _api.interact(widget.postId, 'like');
  }

  Future<void> _handleDislike() async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dislike action triggered')));
  }

  Future<void> _handleSave() async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Save action triggered')));
  }

  Future<void> _handleComment() async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comment action triggered')));
  }

  Future<void> _handleShare() async {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share action triggered')));
  }
}
