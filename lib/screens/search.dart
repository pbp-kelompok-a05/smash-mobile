// ignore_for_file: deprecated_member_use, unused_element, control_flow_in_finally, unused_import, unnecessary_import, unused_field, unnecessary_underscores

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_detail_page.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/post_card.dart';
import 'package:google_fonts/google_fonts.dart';


class SearchPage extends StatefulWidget {
  final String initialQuery;

  const SearchPage({super.key, required this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _controller;
  late ProfileApi _profileApi;
  bool _isLoading = false;
  String? _error;
  List<ProfileFeedItem> _results = [];
  String _queryTitle = '';
  bool _isLoggingOut = false;
  String? _photoUrl;
  Uint8List? _photoBytes;
  String? _username;
  bool _isLoggedIn = false;
  int? _currentUserId;
  
  /// Controller untuk animasi fade-in
  late AnimationController _animationController;

  /// Timer untuk debounce search
  Timer? _searchTimer;

  String? _resolvePhoto(String? url) {
    final resolved = _profileApi.resolveMediaUrl(url) ?? _profileApi.defaultAvatarUrl;
    if (url == null || url.trim().isEmpty) return resolved;
    return '$resolved?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void initState() {
    super.initState();
    // Setup animasi controller dengan durasi 500ms
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    final request = Provider.of<CookieRequest>(context, listen: false);
    _profileApi = ProfileApi(request: request);
    _controller = TextEditingController(text: widget.initialQuery);
    _queryTitle = widget.initialQuery;
    _loadProfileHeader();
    _performSearch();
    
    // Jalankan animasi setelah build selesai
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  /// Perform search dengan debounce 500ms
  Future<void> _performSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    
    // Cancel timer yang ada
    _searchTimer?.cancel();
    
    // Set loading state
    setState(() {
      _isLoading = true;
      _error = null;
      _queryTitle = query;
    });
    
    // Jalankan search setelah 500ms debounce
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final items = await _searchPosts(query);
        if (!mounted) return;
        setState(() {
          _results = items;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
        });
      } finally {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  /// Search post dari multiple API endpoints
  Future<List<ProfileFeedItem>> _searchPosts(String query) async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    final baseUrl = _profileApi.baseUrl;
    final endpoints = [
      '$baseUrl/search/api/',
      '$baseUrl/post/api/search/',
    ];

    dynamic lastError;
    for (final path in endpoints) {
      final uri = Uri.parse(path).replace(queryParameters: {'q': query});
      try {
        final res = await request.get(uri.toString());
        if (res is Map<String, dynamic> && res['status'] == 'success') {
          final posts = res['posts'] as List<dynamic>? ?? [];
          return posts.map((raw) {
            final map = Map<String, dynamic>.from(raw as Map);
            final resolve = _profileApi.resolveMediaUrl;
            final avatar = resolve(map['profile_photo'] as String?) ?? _profileApi.defaultAvatarUrl;
            return ProfileFeedItem(
              id: map['id'] ?? 0,
              title: map['title'] ?? '',
              content: map['content'] ?? '',
              image: resolve(map['image'] as String?),
              videoLink: map['video_link'] as String?,
              user: map['user'] ?? '',
              userId: map['user_id'] ?? 0,
              createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
              commentCount: map['comment_count'] ?? 0,
              likesCount: map['likes_count'] ?? 0,
              dislikesCount: map['dislikes_count'] ?? 0,
              sharesCount: map['shares_count'] ?? 0,
              profilePhoto: avatar,
              userInteraction: map['user_interaction'] as String?,
              isSaved: map['is_saved'] ?? false,
              canEdit: map['can_edit'] ?? false,
            );
          }).toList();
        }
        lastError = res;
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Gagal mencari post: $lastError');
  }

  Future<void> _loadProfileHeader() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    _isLoggedIn = request.loggedIn;
    if (!request.loggedIn) {
      setState(() {
        _photoUrl = null;
        _photoBytes = null;
        _username = null;
        _currentUserId = null;
      });
      return;
    }
    try {
      final profile = await _profileApi.fetchProfile();
      if (!mounted) return;
      setState(() {
        _photoUrl = _resolvePhoto(profile.profilePhoto);
        _photoBytes = null;
        _username = profile.username;
        _currentUserId = profile.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoUrl = _profileApi.defaultAvatarUrl;
        _currentUserId = null;
        _photoBytes = null;
      });
    }
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmashLoginPage()),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmashRegisterPage()),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  void _openCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostEntryFormPage()),
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    final request = Provider.of<CookieRequest>(context, listen: false);
    try {
      await request.logout('http://localhost:8000/authentication/logout/');
    } catch (_) {}
    if (!mounted) return;
    _isLoggingOut = false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SmashLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final loggedInNow = request.loggedIn;
    if (_isLoggedIn != loggedInNow) {
      _isLoggedIn = loggedInNow;
      if (_isLoggedIn) {
        _loadProfileHeader();
      } else {
        _photoUrl = null;
        _username = null;
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      
      // AppBar dengan gradient background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: _buildGlassSearchBar(),
        actions: [
          // Tombol profil jika login, atau login/register jika belum
          _isLoggedIn
              ? IconButton(
                  icon: CircleAvatar(
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: _photoUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                  onPressed: _openProfile,
                )
              : Row(
                  children: [
                    TextButton(
                      onPressed: _openLogin,
                      child: Text(
                        'Login',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _openRegister,
                      child: Text(
                        'Register',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
        ],
      ),

      // Body dengan gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4A2B55), // ungu gelap
              const Color(0xFF6A2B53), // ungu medium
              const Color(0xFF9D50BB), // ungu kebiruan
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan judul dan query
              FadeTransition(
                opacity: _animationController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Results',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _queryTitle.isEmpty ? 'Enter a query to search' : 'Results for "$_queryTitle"',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Garis pembatas gradient
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.3), Colors.transparent],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Area konten (loading, error, atau hasil)
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),

      // Floating Action Button untuk create post
      floatingActionButton: _isLoggedIn
          ? FloatingActionButton(
              onPressed: _openCreatePost,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4A2B55),
              elevation: 8,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  /// Widget untuk search bar dengan glassmorphism effect
  Widget _buildGlassSearchBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // Transparan 15%
        borderRadius: BorderRadius.circular(22), // Pill shape
        border: Border.all(color: Colors.white.withOpacity(0.3)), // Border putih transparan
      ),
      child: TextField(
        controller: _controller,
        onChanged: (_) => _performSearch(),
        onSubmitted: (_) => _performSearch(),
        style: GoogleFonts.inter(color: Colors.white), // Teks putih
        decoration: InputDecoration(
          hintText: 'Search posts...',
          hintStyle: GoogleFonts.inter(color: Colors.white54), // Hint transparan
          prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 22),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70, size: 22),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _results = [];
                      _queryTitle = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none, // Tidak ada border default
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  /// Widget untuk menampilkan konten sesuai state (loading, error, empty, atau hasil)
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Search Error',
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
              onPressed: _performSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search query',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ],
        ),
      );
    } else {
      // List hasil dengan animasi staggered
      return ListView.separated(
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = _results[index];
          final imageUrl = _profileApi.resolveMediaUrl(item.image);
          
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              );
            },
            child: PostCard(
              item: item,
              defaultAvatar: _profileApi.defaultAvatarUrl,
              resolveAvatar: _profileApi.resolveMediaUrl,
              imageUrl: imageUrl,
              showMenu: item.canEdit,
              currentUserId: _currentUserId,
              profilePageBuilder: (id) => ProfilePage(userId: id),
              onLike: () => _handleLike(item.id),
              onComment: () => _openPostDetail(item),
              onSave: () => _handleSave(item.id),
            ),
          );
        },
      );
    }
  }

  /// Handler untuk like post
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

  /// Handler untuk save post
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

  /// Buka detail post
  void _openPostDetail(ProfileFeedItem post) {
    // Navigasi ke halaman detail post
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(postId: post.id),
      ),
    );
  }
}
