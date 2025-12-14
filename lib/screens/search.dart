import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/post_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
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
  String? _resolvePhoto(String? url) {
    final resolved = _profileApi.resolveMediaUrl(url) ?? _profileApi.defaultAvatarUrl;
    if (url == null || url.trim().isEmpty) return resolved;
    return '$resolved?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _profileApi = ProfileApi(request: request);
    _controller = TextEditingController(text: widget.initialQuery);
    _queryTitle = widget.initialQuery;
    _loadProfileHeader();
    _performSearch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _queryTitle = query;
    });
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
  }

  Future<List<ProfileFeedItem>> _searchPosts(String query) async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    final baseUrl = _profileApi.baseUrl;
    final endpoints = [
      '$baseUrl/search/api/',
      '$baseUrl/search/api',
      '$baseUrl/post/api/search/',
      '$baseUrl/post/api/search',
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
            final avatar =
                resolve(map['profile_photo'] as String?) ?? _profileApi.defaultAvatarUrl;
            return ProfileFeedItem(
              id: map['id'] ?? 0,
              title: map['title'] ?? '',
              content: map['content'] ?? '',
              image: resolve(map['image'] as String?),
              videoLink: map['video_link'] as String?,
              user: map['user'] ?? '',
              userId: map['user_id'] ?? 0,
              createdAt:
                  DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
              commentCount: map['comment_count'] ?? 0,
              likesCount: map['likes_count'] ?? 0,
              dislikesCount: map['dislikes_count'] ?? 0,
              sharesCount: map['shares_count'] ?? 0,
              profilePhoto: avatar,
              userInteraction: null,
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
    final profileApi = ProfileApi(request: request);
    try {
      final profile = await profileApi.fetchProfile();
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
        _photoUrl = profileApi.defaultAvatarUrl;
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
      appBar: NavBar(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        showCreate: _isLoggedIn,
        isLoggedIn: _isLoggedIn,
        username: _username,
        photoUrl: _photoUrl,
        photoBytes: _photoBytes,
        searchController: _controller,
        onSearchSubmit: (_) => _performSearch(),
        onLogin: _openLogin,
        onRegister: _openRegister,
        onLogout: _handleLogout,
        onProfileTap: _openProfile,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD2F3E0), Color(0xFFFFE2E2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else if (_results.isEmpty)
                const Expanded(
                  child: Center(child: Text('No results yet.')),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final imageUrl = _profileApi.resolveMediaUrl(item.image);
                      return PostCard(
                        item: item,
                        defaultAvatar: _profileApi.defaultAvatarUrl,
                        resolveAvatar: _profileApi.resolveMediaUrl,
                        imageUrl: imageUrl,
                        showMenu: true,
                        currentUserId: _currentUserId,
                        profilePageBuilder: (id) => ProfilePage(userId: id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}
