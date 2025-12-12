import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/models/profile_entry.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/edit_profile.dart';
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

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _api = ProfileApi(request: request);
    _loadProfile();
    _loadPosts();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final data = await _api.fetchProfile(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = data;
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

  Future<void> _loadPosts() async {
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPosts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isLoggedIn = request.loggedIn;
    final canEdit = isLoggedIn && widget.userId == null;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: NavBar(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        isLoggedIn: isLoggedIn,
        showCreate: isLoggedIn,
        username: _profile?.username ?? 'Guest',
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
              _buildFilterChips(),
              const SizedBox(height: 18),
              const Text(
                'My Posts',
                style: TextStyle(
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
    final avatar = _api.resolveMediaUrl(_profile?.profilePhoto) ??
        _api.defaultAvatarUrl;
    return Center(
      child: Column(
        children: [
          _avatarWidget(avatar),
          const SizedBox(height: 12),
          Text(
            _profile?.username ?? '-',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _profile?.bio.isNotEmpty == true ? _profile!.bio : 'Belum ada bio',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                    setState(() => _profile = updated);
                  }
                });
              },
              child: const Text('Edit Profile'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarWidget(String? url) {
    return Container(
      width: 112,
      height: 112,
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
    return Row(
      children: [
        _chip('My Posts', 'my'),
        const SizedBox(width: 8),
        _chip('Bookmark', 'bookmarked'),
        const SizedBox(width: 8),
        _chip('Liked', 'liked'),
      ],
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
          TextButton(
            onPressed: _loadPosts,
            child: const Text('Coba lagi'),
          ),
        ],
      );
    }
    if (_posts.isEmpty) {
      return const Text(
        'Belum ada postingan.',
        style: TextStyle(color: Colors.black54),
      );
    }
    return Column(
      children: _posts
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PostCard(
                item: item,
                avatarUrl:
                    _api.resolveMediaUrl(item.profilePhoto) ?? _api.defaultAvatarUrl,
                showMenu: item.canEdit,
                onEdit: (_) {},
                onDelete: (_) {},
                onProfileTap: () {},
              ),
            ),
          )
          .toList(),
    );
  }
}
