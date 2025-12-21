// ignore_for_file: unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Import model dan widget
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_api.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';
import 'package:smash_mobile/post/post_detail_page.dart';
import 'package:smash_mobile/screens/search.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/widgets/post_card.dart';

/// Halaman daftar post yang menampilkan semua post dari semua user
/// dengan data interaksi real-time untuk user yang sedang login
class PostListPage extends StatefulWidget {
  final bool showBookmarksOnly;

  const PostListPage({super.key, this.showBookmarksOnly = false});

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Controllers & Keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  late final TextEditingController _searchController;

  // API & Data
  late PostApi _postApi;
  late ProfileApi _profileApi;
  List<ProfileFeedItem> _posts = [];
  List<ProfileFeedItem> _filteredPosts = [];
  bool _isLoading = true;
  String? _error;
  String? _navUsername;
  String? _navPhotoUrl;

  // Pagination
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Refresh Handler
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _searchController = TextEditingController();
    _animationController.forward();

    final request = Provider.of<CookieRequest>(context, listen: false);
    _postApi = PostApi(request: request);
    _profileApi = ProfileApi(request: request);

    _loadInitialData();
    _loadNavProfile();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Auto refresh setiap 30 detik untuk data real-time
  void _setupAutoRefresh() {
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadPosts(showLoading: false);
    });
  }

  void _loadInitialData() {
    _loadPosts();
  }

  Future<void> _loadNavProfile() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    if (!request.loggedIn) {
      setState(() {
        _navUsername = null;
        _navPhotoUrl = null;
      });
      return;
    }
    try {
      final profile = await _profileApi.fetchProfile();
      if (!mounted) return;
      setState(() {
        _navUsername = profile.username;
        _navPhotoUrl =
            _profileApi.resolveMediaUrl(profile.profilePhoto) ??
            _profileApi.defaultAvatarUrl;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _navUsername = null;
        _navPhotoUrl = _profileApi.defaultAvatarUrl;
      });
    }
  }

  Future<void> _handleLogout() async {
    final request = context.read<CookieRequest>();
    try {
      await request.logout('http://localhost:8000/authentication/logout/');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _navUsername = null;
      _navPhotoUrl = null;
    });
  }

  /// Filter bookmark di frontend (menunggu API support filter)
  void _applyBookmarkFilter() {
    if (widget.showBookmarksOnly) {
      _filteredPosts = _posts.where((post) => post.isSaved == true).toList();
    } else {
      _filteredPosts = List.from(_posts);
    }
  }

  // Navigation helpers
  void _openLogin() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SmashLoginPage()),
  );

  void _openRegister() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SmashRegisterPage()),
  );
  void _openSearch(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: normalized)),
    );
  }

  void _openPostDetail(ProfileFeedItem post) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
  );

  Future<void> _openCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostEntryFormPage()),
    );
    // If the create page returned `true`, refresh posts immediately
    if (result == true) {
      await _loadPosts(showLoading: true);
    }
  }

  /// Handler untuk klik avatar - navigasi ke halaman profil
  void _handleProfileTap(int userId) {
    if (userId != 0) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)));
    }
  }

  /// Load posts dari API dengan error handling
  Future<void> _loadPosts({
    bool showLoading = true,
    bool isRefresh = false,
  }) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // GUNAKAN fetchAllPosts() untuk ambil semua post
      final response = await _postApi.fetchAllPosts();
      if (!mounted) return;

      setState(() {
        _posts = response.cast<ProfileFeedItem>();
        _applyBookmarkFilter();
        _hasMore = false;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadPosts(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAnimatedAppBar(),
      body: _isLoading ? _buildLoading() : _buildContentBody(),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -50 * (1 - _animationController.value)),
          child: Opacity(opacity: _animationController.value, child: child),
        ),
        child: _buildNavBar(),
      ),
    );
  }

  Widget _buildNavBar() {
    final request = Provider.of<CookieRequest>(context, listen: true);
    if (request.loggedIn && _navUsername == null) {
      Future.microtask(_loadNavProfile);
    }
    return NavBar(
      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      isLoggedIn: request.loggedIn,
      showCreate: request.loggedIn,
      photoUrl: _navPhotoUrl,
      photoBytes: null,
      username: _navUsername,
      onLogin: _openLogin,
      onRegister: _openRegister,
      onLogout: _handleLogout,
      onProfileTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      ),
      searchController: _searchController,
      onSearchSubmit: _openSearch,
    );
  }

  Widget _buildLoading() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildContentBody() {
    if (_error != null) return _buildErrorState();
    if (_filteredPosts.isEmpty) return _buildEmptyState();

    return FadeTransition(
      opacity: _animationController,
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        color: Colors.white,
        backgroundColor: const Color(0xFF4A2B55),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          itemCount: _filteredPosts.length,
          itemBuilder: (context, index) {
            final post = _filteredPosts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: PostCard(
                key: ValueKey('post-${post.id}'),
                item: post,
                // Gunakan method resolve dari PostApi
                avatarUrl: _postApi.resolveMediaUrl(post.profilePhoto),
                imageUrl: _postApi.resolveMediaUrl(post.image),
                defaultAvatar:
                    '${_postApi.baseUrl}/static/images/user-profile.png',
                resolveAvatar: _postApi.resolveMediaUrl,
                showMenu: post.canEdit,
                showFooterActions: true,
                enableInteractions: true,
                onComment: () => _openPostDetail(post),
                onSave: () => _handleSave(post.id),
                profilePageBuilder: (id) => ProfilePage(userId: id),
                // Handler klik avatar
                onProfileTap: () => _handleProfileTap(post.userId),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to load posts',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadPosts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4A2B55),
              ),
              child: Text('Retry', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final emptyMessage = widget.showBookmarksOnly
        ? "You haven't saved any posts yet"
        : 'No posts yet';
    final emptySubtitle = widget.showBookmarksOnly
        ? 'Tap the save button on posts to add them here'
        : 'Be the first to create a post!';

    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.showBookmarksOnly
                  ? Icons.bookmark_border
                  : Icons.article_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle,
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (!widget.showBookmarksOnly)
              ElevatedButton(
                onPressed: _openCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB6340),
                  foregroundColor: Colors.white,
                ),
                child: Text('Create Post', style: GoogleFonts.inter()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    final request = Provider.of<CookieRequest>(context, listen: true);
    return request.loggedIn
        ? FloatingActionButton(
            onPressed: _openCreatePost,
            backgroundColor: const Color(0xFFFB6340),
            child: const Icon(Icons.add, color: Colors.white),
          )
        : const SizedBox.shrink();
  }

  Future<void> _handleSave(int postId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Save feature coming soon', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
