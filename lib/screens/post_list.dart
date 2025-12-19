// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, unused_local_variable, unnecessary_import

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Import model yang BENAR
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_api.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';
import 'package:smash_mobile/post/post_detail_page.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/widgets/post_card.dart';

// =============================================================================
// POST LIST PAGE - DIPERBAIKI UNTUK OVERFLOW DAN BOOKMARK SUPPORT
// =============================================================================
class PostListPage extends StatefulWidget {
  final bool showBookmarksOnly; // Parameter baru untuk filter bookmark

  const PostListPage({super.key, this.showBookmarksOnly = false});

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Controllers & Keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // API & Data
  late PostApi _postApi;
  late ProfileApi _profileApi;
  List<ProfileFeedItem> _posts = [];
  List<ProfileFeedItem> _filteredPosts = []; // Posts setelah filter bookmark
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Refresh Handler
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  bool get wantKeepAlive => true; // Mempertahankan state saat tab switching

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _setupApi();
    _loadInitialData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Setup Methods
  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  void _setupApi() {
    final request = Provider.of<CookieRequest>(context, listen: false);
    _postApi = PostApi(request: request);
    _profileApi = ProfileApi(request: request);
  }

  void _loadInitialData() {
    _loadCurrentUser();
    _loadPosts();
  }

  void _setupAutoRefresh() {
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadPosts(showLoading: false);
    });
  }

  // ===========================================================================
  // FILTER POST BERDASARKAN BOOKMARK
  // ===========================================================================
  void _applyBookmarkFilter() {
    if (widget.showBookmarksOnly) {
      // Filter hanya post yang disimpan
      _filteredPosts = _posts.where((post) => post.isSaved == true).toList();
    } else {
      // Tampilkan semua post
      _filteredPosts = List.from(_posts);
    }
  }

  // User & Authentication
  Future<void> _loadCurrentUser() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    if (!request.loggedIn) return;

    try {
      final profile = await _profileApi.fetchProfile();
      if (!mounted) return;
      setState(() => _currentUserId = profile.id);
    } catch (_) {}
  }

  // Navigation
  void _openLogin() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SmashLoginPage()),
  );
  void _openRegister() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SmashRegisterPage()),
  );
  void _openPostDetail(ProfileFeedItem post) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
  );
  void _openCreatePost() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PostEntryFormPage()),
  );

  // ===========================================================================
  // LOAD POST DENGAN BOOKMARK SUPPORT
  // ===========================================================================
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
      // Gunakan endpoint yang sesuai dari urls.py Django
      // Untuk bookmark, kita akan filter di frontend dari semua post
      // Alternatif: Buat endpoint API khusus di PostApi untuk bookmark
      final response = await _postApi.searchPosts('');

      if (!mounted) return;

      setState(() {
        _posts = response;
        _applyBookmarkFilter(); // Terapkan filter bookmark
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
    _currentPage = 1;
    await _loadPosts(isRefresh: true);
  }

  // UI Builders
  @override
  Widget build(BuildContext context) {
    super.build(context); // Untuk AutomaticKeepAliveClientMixin

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
    final isLoggedIn = request.loggedIn;

    return NavBar(
      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      isLoggedIn: isLoggedIn,
      showCreate: isLoggedIn,
      photoUrl: null,
      photoBytes: null,
      username: null,
      onLogin: _openLogin,
      onRegister: _openRegister,
      onLogout: () {},
      onProfileTap: () {},
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

    // Gunakan _filteredPosts bukan _posts
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
          // Atur padding untuk mencegah overflow
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          itemCount: _filteredPosts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _filteredPosts.length) return _buildLoadingMore();

            final post = _filteredPosts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _buildPostCard(post, index),
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

  // ===========================================================================
  // Widget PostCard dengan constraint untuk mencegah overflow
  // ===========================================================================
  Widget _buildPostCard(ProfileFeedItem post, int index) {
    // Validasi dan default avatar
    final defaultAvatar =
        '${_profileApi.baseUrl}/static/images/user-profile.png';
    String? avatarUrl = _profileApi.resolveMediaUrl(post.profilePhoto);

    // Handle null avatar dengan benar
    Widget buildAvatarWidget() {
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        return CircleAvatar(
          backgroundColor: Colors.green.shade50,
          radius: 22,
          backgroundImage: NetworkImage(avatarUrl),
          child: CircleAvatar(
            backgroundColor: Colors.green.shade50,
            radius: 22,
            child: Icon(Icons.person, color: Colors.green.shade800, size: 24),
          ),
        );
      } else {
        return CircleAvatar(
          backgroundColor: Colors.green.shade50,
          radius: 22,
          child: Icon(Icons.person, color: Colors.green.shade800, size: 24),
        );
      }
    }

    return Container(
      // Constraint yang lebih ketat untuk mencegah overflow
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 16,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openPostDetail(post),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan avatar dan info user
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildAvatarWidget(),
                    const SizedBox(width: 12),
                    Expanded(
                      // Expanded untuk membatasi lebar text
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.user,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formattedDate(post.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentUserId == post.userId)
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          // TODO: Implement menu actions
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Judul post
                Text(
                  post.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                // Konten post dengan pembatasan
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 100, // Batasi tinggi konten
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Text(
                      post.content,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Footer dengan stats
                _buildPostStats(post),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostStats(ProfileFeedItem post) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.thumb_up,
              size: 16,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              '${post.likesCount}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.comment, size: 16, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              '${post.commentCount}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        if (post.isSaved)
          Icon(Icons.bookmark, size: 16, color: Colors.yellow.shade600),
      ],
    );
  }

  Widget _buildLoadingMore() {
    return _isLoadingMore
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          )
        : const SizedBox.shrink();
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

  // Helper methods
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
    final month = months[local.month - 1];
    final day = local.day;
    final year = local.year;
    final sameYear = year == now.year;
    return sameYear ? '$month $day' : '$month $day $year';
  }

  // Interaction handlers
  Future<void> _handleLike(int postId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Like feature coming soon', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
