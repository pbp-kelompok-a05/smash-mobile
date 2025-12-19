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
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/widgets/post_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId});

  final int? userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ProfileApi _api;

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

  String _resolvedPhoto(String? url) {
    if (url == null || url.trim().isEmpty) return _api.defaultAvatarUrl;
    final resolved = _api.resolveMediaUrl(url);
    if (resolved == null || resolved.isEmpty) return _api.defaultAvatarUrl;
    final cacheBust = DateTime.now().millisecondsSinceEpoch;
    return '$resolved?v=$cacheBust';
  }

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _api = ProfileApi(request: request);
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
    } catch (_) {
      // silently ignore; only used to detect self profile
    }
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
        _posts = entry.data;
        _refreshPostAvatars();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString();
      });
      // Log to console for debugging backend response issues.
      // ignore: avoid_print
      print('Load posts failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingPosts = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isLoggedIn = request.loggedIn;
    final canEdit = isLoggedIn && _viewingOwnProfile;

    if (!isLoggedIn) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: NavBar(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        isLoggedIn: false,
        showCreate: false,
        username: 'Guest',
        photoUrl: _navPhotoUrl ?? _photoUrl,
        onLogin: _openLogin,
        onRegister: _openRegister,
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF6F6F6), Color(0xFFFFF3F4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _buildGuestWarning(),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: NavBar(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        isLoggedIn: isLoggedIn,
        showCreate: isLoggedIn,
        username: _navUsername ?? _profile?.username ?? 'Guest',
        photoUrl: _navPhotoUrl ?? _photoUrl,
        photoBytes: _photoBytes,
        onLogin: _openLogin,
        onRegister: _openRegister,
        onLogout: _handleLogout,
        onCreatePost: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create post coming soon.')),
          );
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F6F6), Color(0xFFFFF3F4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadProfile();
            await _loadPosts();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildHeader(canEdit),
              const SizedBox(height: 18),
              if (_shouldShowFilters()) ...[
                _buildFilterChips(),
                const SizedBox(height: 18),
              ],
              Text(
                _filterHeading(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildPostsList(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool canEdit) {
    if (_loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_profileError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gagal memuat profil',
            style: TextStyle(color: Colors.red.shade700),
          ),
          TextButton(
            onPressed: _loadProfile,
            child: const Text('Coba lagi'),
          ),
        ],
      );
    }
    final avatar =
        _photoUrl ?? _api.resolveMediaUrl(_profile?.profilePhoto) ?? _api.defaultAvatarUrl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatarWidget(avatar, radius: 58),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_viewingOwnProfile) ...[
                const Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                _profile?.username ?? '-',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _profile?.bio.isNotEmpty == true
                    ? _profile!.bio
                    : 'Belum ada bio',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.1,
                ),
              ),
              if (canEdit) ...[
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (_profile == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(
                          profile: _profile,
                          api: _api,
                        ),
                      ),
                    ).then((updated) {
                      if (updated is ProfileData) {
                        setState(() {
                          _profile = updated;
                          _photoUrl = _resolvedPhoto(updated.profilePhoto);
                          _refreshPostAvatars();
                        });
                      }
                    });
                  },
                  child: const Text('Edit Profile'),
                ),
              ],
              if (!_viewingOwnProfile && _profile?.joinedOn != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Joined on ${_formatJoinedDate(_profile!.joinedOn!)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarWidget(String? url, {double radius = 52}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFE8E8E8), Color(0xFFF6F6F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipOval(
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _placeholderAvatar(),
              )
            : _placeholderAvatar(),
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 48, color: Colors.grey.shade600),
    );
  }

  Widget _buildFilterChips() {
    // Hide filters on other users' profiles.
    if (!_shouldShowFilters()) return const SizedBox.shrink();

    final filters = [
      {'label': 'My Posts', 'value': 'my'},
      {'label': 'Bookmark', 'value': 'bookmarked'},
      {'label': 'Liked', 'value': 'liked'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  filter['label'] ?? '',
                  filter['value'] ?? 'my',
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _chip(String label, String filterValue) {
    final selected = _filter == filterValue;
    return GestureDetector(
      onTap: () {
        if (_filter == filterValue) return;
        setState(() => _filter = filterValue);
        _loadPosts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D8CF0) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2D8CF0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_loadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_postsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gagal memuat postingan',
            style: TextStyle(color: Colors.red.shade700),
          ),
          if (_postsError != null)
            Text(
              _postsError!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          TextButton(
            onPressed: _loadPosts,
            child: const Text('Coba lagi'),
          ),
        ],
      );
    }
    if (_posts.isEmpty) {
      return Text(
        _emptyPostsMessage(),
        style: const TextStyle(color: Colors.black54),
      );
    }
    return Column(
      children: _posts
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PostCard(
                item: item,
                avatarUrl: _api.resolveMediaUrl(item.profilePhoto),
                defaultAvatar: _api.defaultAvatarUrl,
                resolveAvatar: _api.resolveMediaUrl,
                showMenu: true,
                currentUserId: _navUserId,
                onEdit: (_) {},
                onDelete: (_) {},
                profilePageBuilder: (id) => ProfilePage(userId: id),
              ),
            ),
          )
          .toList(),
    );
  }

  String _filterHeading() {
    switch (_filter) {
      case 'bookmarked':
        return 'Bookmarked Posts';
      case 'liked':
        return 'Liked Posts';
      default:
        return widget.userId == null ? 'My Posts' : 'Posts';
    }
  }

  String _emptyPostsMessage() {
    switch (_filter) {
      case 'bookmarked':
        return 'Belum ada postingan tersimpan.';
      case 'liked':
        return 'Belum ada postingan yang disukai.';
      default:
        return widget.userId == null
            ? 'Belum ada postingan.'
            : 'Pengguna ini belum memiliki postingan.';
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
      'Dec'
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    return '$month $day, $year';
  }

  bool _shouldShowFilters() => _viewingOwnProfile;

  void _refreshPostAvatars() {
    if (!_viewingOwnProfile || _photoUrl == null || _profile == null) return;
    final me = _profile!.id;
    _posts = _posts
        .map(
          (p) => p.userId == me
              ? ProfileFeedItem(
                  id: p.id,
                  title: p.title,
                  content: p.content,
                  image: p.image,
                  videoLink: p.videoLink,
                  user: p.user,
                  userId: p.userId,
                  createdAt: p.createdAt,
                  commentCount: p.commentCount,
                  likesCount: p.likesCount,
                  dislikesCount: p.dislikesCount,
                  sharesCount: p.sharesCount,
                  profilePhoto: _photoUrl,
                  userInteraction: p.userInteraction,
                  isSaved: p.isSaved,
                  canEdit: p.canEdit,
                )
              : p,
        )
        .toList();
  }

  Widget _buildGuestWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Login required to view profile.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _openLogin,
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
