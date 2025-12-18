// ignore_for_file: deprecated_member_use, unused_import, unused_field, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_api.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';
import 'package:smash_mobile/post/post_detail_page.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/widgets/post_card.dart';

/// Halaman daftar post dengan glassmorphism UI dan auto-scroll
class PostListPage extends StatefulWidget {
  const PostListPage({super.key});

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage>
    with SingleTickerProviderStateMixin {
  // === CONTROLLERS & KEYS ===
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // === API & DATA ===
  late PostApi _postApi;
  late ProfileApi _profileApi;
  List<ProfileFeedItem> _posts = [];
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;

  // === PAGINATION ===
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // === REFRESH HANDLER ===
  late final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();

    final request = Provider.of<CookieRequest>(context, listen: false);
    _postApi = PostApi(request: request);
    _profileApi = ProfileApi(request: request);

    _loadCurrentUser();
    _loadPosts();

    // Auto-refresh setiap 30 detik untuk data baru
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadPosts(showLoading: false);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // === USER & AUTH ===
  Future<void> _loadCurrentUser() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    if (!request.loggedIn) return;

    try {
      final profile = await _profileApi.fetchProfile();
      if (!mounted) return;
      setState(() {
        _currentUserId = profile.id;
      });
    } catch (_) {}
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmashLoginPage()),
    );
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SmashRegisterPage()),
    );
  }

  // === DATA LOADING ===
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
      // Untuk sekarang load semua post
      final response = await _postApi.searchPosts('');

      if (!mounted) return;

      setState(() {
        _posts = response;
        _hasMore = false; // Backend belum support pagination
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

  // === NAVIGATION ===
  void _openPostDetail(ProfileFeedItem post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
    );
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostEntryFormPage()),
    );
  }

  // === UI BUILDERS ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAnimatedAppBar(),
      body: _isLoading ? _buildLoading() : _buildContent(),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  /// Membangun AppBar dengan glassmorphism effect
  PreferredSizeWidget _buildAnimatedAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          String? _photoUrl;
          String? _username;
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _animationController.value)),
            child: Opacity(
              opacity: _animationController.value,
              child: NavBar(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                isLoggedIn: _currentUserId != null,
                showCreate: _currentUserId != null,
                photoUrl: _photoUrl,
                photoBytes: null,
                username: _username,
                onLogin: _openLogin,
                onRegister: _openRegister,
                onLogout: () {},
                onProfileTap: () {},
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildError();
    }

    if (_posts.isEmpty) {
      return _buildEmpty();
    }

    return FadeTransition(
      opacity: _animationController,
      child: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        color: Colors.white,
        backgroundColor: const Color(0xFF4A2B55),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: _posts.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return _buildLoadingMore();
            }

            final post = _posts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPostCard(post),
            );
          },
        ),
      ),
    );
  }

  Widget _buildError() {
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

  Widget _buildEmpty() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a post!',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 24),
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

  Widget _buildPostCard(ProfileFeedItem post) {
    final avatar = _profileApi.resolveMediaUrl(post.profilePhoto);
    final defaultAvatar =
        '${_profileApi.baseUrl}/static/images/user-profile.png';

    return InkWell(
      onTap: () => _openPostDetail(post),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: PostCard(
              item: post,
              avatarUrl: avatar,
              defaultAvatar: defaultAvatar,
              resolveAvatar: _profileApi.resolveMediaUrl,
              showMenu: _currentUserId == post.userId,
              currentUserId: _currentUserId,
              showFooterActions: true,
              enableInteractions: true,
              onLike: () => _handleLike(post.id),
              onComment: () => _openPostDetail(post),
              onSave: () => _handleSave(post.id),
              profilePageBuilder: (id) => ProfilePage(userId: id),
            ),
          ),
        ),
      ),
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
    return _currentUserId != null
        ? FloatingActionButton(
            onPressed: _openCreatePost,
            backgroundColor: const Color(0xFFFB6340),
            child: const Icon(Icons.add, color: Colors.white),
          )
        : const SizedBox.shrink();
  }

  // === INTERACTION HANDLERS ===
  Future<void> _handleLike(int postId) async {
    // Implementasi like di backend
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
    // Implementasi save di backend
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
