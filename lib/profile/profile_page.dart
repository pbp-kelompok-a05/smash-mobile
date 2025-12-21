// ignore_for_file: deprecated_member_use, unused_field, unused_element, unnecessary_underscores, avoid_print, unused_import, unused_local_variable

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/models/profile_entry.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/edit_profile.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/widgets/post_card.dart';
import 'package:smash_mobile/post/post_api.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman profil pengguna dengan desain modern featuring glassmorphism,
/// gradient background biru-ungu, dan enhanced UX.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId});
  final int? userId;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ProfileApi _api;
  late PostApi _postApi;

  // State management (LOGIC UNCHANGED)
  ProfileData? _profile;
  List<ProfileFeedItem> _posts = [];
  String? _profileError;
  String? _postsError;
  bool _loadingProfile = true;
  bool _loadingPosts = true;
  String _filter = 'my';
  bool _viewingOwnProfile = false;
  bool _isLoggingOut = false;
  String? _photoUrl;
  Uint8List? _photoBytes;
  String? _navPhotoUrl;
  String? _navUsername;
  int? _navUserId;

  // NEW: Modern color scheme
  static const Color _primaryColor = Color(0xFF667EEA);
  static const Color _secondaryColor = Color(0xFF764BA2);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _api = ProfileApi(request: request);
    _postApi = PostApi(request: request);
    _viewingOwnProfile = widget.userId == null;
    if (request.loggedIn && widget.userId != null) {
      _loadSelfIdIfNeeded();
    }
    if (request.loggedIn) {
      _loadNavProfile();
    }
    if (!request.loggedIn) {
      _loadingProfile = false;
      _loadingPosts = false;
    } else {
      _loadProfile();
      _loadPosts();
    }
  }

  // SEMUA METHOD LOGIC DI BAWAH INI TIDAK BERUBAH

  Future<void> _loadSelfIdIfNeeded() async {
    if (widget.userId == null || _viewingOwnProfile) return;
    try {
      final me = await _api.fetchProfile();
      if (!mounted) return;
      if (me.id == widget.userId) {
        setState(() {
          _viewingOwnProfile = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    if (!request.loggedIn) {
      setState(() {
        _loadingProfile = false;
        _profile = null;
        _profileError = null;
        _photoUrl = null;
      });
      return;
    }
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final data = await _api.fetchProfile(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = data;
        _photoUrl = _resolvedPhoto(data.profilePhoto);
        _photoBytes = null;
        if (_viewingOwnProfile) {
          _navPhotoUrl = _photoUrl;
          _navUsername = data.username;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadNavProfile() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    if (!request.loggedIn) return;
    try {
      final me = await _api.fetchProfile();
      if (!mounted) return;
      setState(() {
        _navPhotoUrl = _resolvedPhoto(me.profilePhoto);
        _navUsername = me.username;
        _navUserId = me.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _navPhotoUrl = _api.defaultAvatarUrl;
      });
    }
  }

  Future<void> _loadPosts() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    if (!request.loggedIn) {
      setState(() {
        _loadingPosts = false;
        _posts = [];
        _postsError = null;
      });
      return;
    }
    setState(() {
      _loadingPosts = true;
      _postsError = null;
    });
    try {
      final entry = await _api.fetchProfilePosts(
        filter: _filter,
        userId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        // FIX: Explicit casting untuk menghindar JSArray error
        _posts = (entry.data as List).map<ProfileFeedItem>((item) {
          if (item is ProfileFeedItem) return item;
          if (item is Map<String, dynamic>) {
            return ProfileFeedItem.fromJson(item);
          }
          throw Exception('Invalid data type: ${item.runtimeType}');
        }).toList();
        _refreshPostAvatars();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString();
      });
      print('Load posts failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingPosts = false;
        });
      }
    }
  }

  String _resolvedPhoto(String? url) {
    if (url == null || url.trim().isEmpty) return _api.defaultAvatarUrl;
    final resolved = _api.resolveMediaUrl(url);
    if (resolved == null || resolved.isEmpty) return _api.defaultAvatarUrl;
    final cacheBust = DateTime.now().millisecondsSinceEpoch;
    return '$resolved?v=$cacheBust';
  }

  void _openLogin() {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder: (_) => const SmashLoginPage(redirectTo: ProfilePage()),
      ),
    );
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SmashRegisterPage()));
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    final request = context.read<CookieRequest>();
    try {
      await request.logout('http://localhost:8000/authentication/logout/');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _profile = null;
      _posts = [];
    });
    _isLoggingOut = false;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SmashLoginPage()),
      (route) => false,
    );
  }

  Future<void> _handleDeletePost(ProfileFeedItem post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _postApi.deletePost(post.id);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post: $e')),
      );
    }
  }

  void _handleSavedToggle() {
    if (_filter == 'bookmarked') {
      _loadPosts();
    }
  }

  void _handleLikedToggle() {
    if (_filter == 'liked') {
      _loadPosts();
    }
  }


  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isLoggedIn = request.loggedIn;
    final canEdit = isLoggedIn && _viewingOwnProfile;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      // NEW: Gradient background biru-ungu
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA), // Biru
              Color(0xFF764BA2), // Ungu
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // NEW: Modern app bar dengan glass effect
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _profile?.username ?? 'Profile',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                if (!isLoggedIn)
                  TextButton(
                    onPressed: _openLogin,
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else if (_viewingOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PostEntryFormPage(),
                        ),
                      ).then((result) {
                        if (!mounted) return;
                        if (result == true) {
                          if (_filter != 'my') {
                            setState(() {
                              _filter = 'my';
                            });
                          }
                          _loadPosts();
                        }
                      });
                    },
                  ),
              ],
            ),
            // NEW: Content dengan glass cards
            SliverToBoxAdapter(
              child: isLoggedIn
                  ? _buildLoggedInContent(canEdit)
                  : _buildGuestContent(),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: UI Modern untuk user login
  Widget _buildLoggedInContent(bool canEdit) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadProfile();
        await _loadPosts();
      },
      color: _primaryColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildModernHeader(canEdit),
          const SizedBox(height: 24),
          if (_shouldShowFilters()) ...[
            _buildModernFilterChips(),
            const SizedBox(height: 24),
          ],
          _buildPostsSection(),
        ],
      ),
    );
  }

  // NEW: Glassmorphism profile header
  Widget _buildModernHeader(bool canEdit) {
    if (_loadingProfile) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_profileError != null) {
      return _buildErrorCard(
        title: 'Gagal memuat profil',
        error: _profileError,
        onRetry: _loadProfile,
      );
    }

    final avatarUrl = _photoUrl ?? _api.defaultAvatarUrl;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar dengan border gradient
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE8E8E8), Color(0xFFF6F6F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_viewingOwnProfile) ...[
                  const Text(
                    'Hello,',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  _profile?.username ?? '-',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _profile?.bio.isNotEmpty == true
                      ? _profile!.bio
                      : 'Belum ada bio',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!_viewingOwnProfile && _profile?.joinedOn != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Joined on ${_formatJoinedDate(_profile!.joinedOn!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (canEdit)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_profile == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditProfilePage(profile: _profile, api: _api),
                        ),
                      ).then((updated) {
                        if (updated is ProfileData) {
                          setState(() {
                            _profile = updated;
                            _photoUrl = _resolvedPhoto(updated.profilePhoto);
                            _navPhotoUrl = _photoUrl;
                            _navUsername = updated.username;
                            _refreshPostAvatars();
                          });
                          _loadPosts();
                        }
                      });
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  // NEW: Modern filter chips dengan icon
  Widget _buildModernFilterChips() {
    final filters = [
      {'label': 'My Posts', 'value': 'my', 'icon': Icons.article_outlined},
      {
        'label': 'Bookmark',
        'value': 'bookmarked',
        'icon': Icons.bookmark_outline,
      },
      {'label': 'Liked', 'value': 'liked', 'icon': Icons.favorite_outline},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _filter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : _textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && _filter != filter['value']) {
                  setState(() => _filter = filter['value'] as String);
                  _loadPosts();
                }
              },
              backgroundColor: Colors.white,
              selectedColor: _primaryColor,
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // NEW: Posts section dengan heading
  Widget _buildPostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _filterHeading(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildPostsList(),
      ],
    );
  }

  // Posts list (LOGIC UNCHANGED, hanya styling wrapper)
  Widget _buildPostsList() {
    if (_loadingPosts) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_postsError != null) {
      return _buildErrorCard(
        title: 'Gagal memuat postingan',
        error: _postsError,
        onRetry: _loadPosts,
      );
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        // FIX: Gunakan nama variabel yang jelas untuk menghindari konflik
        final postItem = _posts[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          child: PostCard(
            key: ValueKey(postItem.id),
            item: postItem,
            avatarUrl: _api.resolveMediaUrl(postItem.profilePhoto),
            imageUrl: _api.resolveMediaUrl(postItem.image),
            defaultAvatar: _api.defaultAvatarUrl,
            resolveAvatar: _api.resolveMediaUrl,
            showMenu: true,
            currentUserId: _navUserId,
            onEdit: (_) => _loadPosts(),
            onDelete: _handleDeletePost,
            onSave: _handleSavedToggle,
            onLike: _handleLikedToggle,
            profilePageBuilder: (id) => ProfilePage(userId: id),
          ),
        );
      },
    );
  }

  // NEW: Empty state dengan glass effect
  Widget _buildEmptyState() {
    final messages = {
      'bookmarked': 'Belum ada postingan tersimpan.',
      'liked': 'Belum ada postingan yang disukai.',
      'my': _viewingOwnProfile
          ? 'Belum ada postingan.\nMulai bagikan sesuatu!'
          : 'Pengguna ini belum memiliki postingan.',
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 64, color: _textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              messages[_filter] ?? 'Tidak ada postingan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Error card dengan glass effect
  Widget _buildErrorCard({
    required String title,
    String? error,
    required VoidCallback onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.red.shade600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Konten untuk guest user (LOGIC UNCHANGED, styling improved)
  Widget _buildGuestContent() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login Required',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You need to be logged in to view profile',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _openLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4A2B55),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.2),
                          ),
                          child: Text(
                            'Login',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SmashRegisterPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            "Don't have an account? Register",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  String _filterHeading() {
    switch (_filter) {
      case 'bookmarked':
        return 'Postingan Tersimpan';
      case 'liked':
        return 'Postingan Disukai';
      default:
        return _viewingOwnProfile ? 'Postingan Saya' : 'Postingan';
    }
  }

  String _formatJoinedDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _shouldShowFilters() => _viewingOwnProfile;

  // FIX: Gunakan copyWith untuk update foto profil
  void _refreshPostAvatars() {
    if (!_viewingOwnProfile || _photoUrl == null || _profile == null) return;

    setState(() {
      _posts = _posts
          .map<ProfileFeedItem>(
            (p) => p.userId == _profile!.id
                ? p.copyWith(profilePhoto: _photoUrl)
                : p,
          )
          .toList();
    });
  }
}
