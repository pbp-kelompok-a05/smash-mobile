import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_api.dart';
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
  String? _username;
  bool _isLoggedIn = false;

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
    final request = Provider.of<CookieRequest>(context, listen: false);
    final api = PostApi(request: request);
    try {
      final items = await api.searchPosts(query);
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

  Future<void> _loadProfileHeader() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    _isLoggedIn = request.loggedIn;
    if (!request.loggedIn) {
      setState(() {
        _photoUrl = null;
        _username = null;
      });
      return;
    }
    final profileApi = ProfileApi(request: request);
    try {
      final profile = await profileApi.fetchProfile();
      if (!mounted) return;
      setState(() {
        _photoUrl = profileApi.resolvePhotoUrl(profile.profilePhoto);
        _username = profile.username;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoUrl = profileApi.defaultAvatarUrl;
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
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      appBar: NavBar(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        showCreate: _isLoggedIn,
        isLoggedIn: _isLoggedIn,
        username: _username,
        photoUrl: _photoUrl,
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
                      final avatar =
                          _profileApi.resolveMediaUrl(item.profilePhoto) ??
                              _profileApi.defaultAvatarUrl;
                      return PostCard(
                        item: item,
                        avatarUrl: avatar,
                        imageUrl: imageUrl,
                        showMenu: false,
                        onProfileTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(userId: item.userId),
                            ),
                          );
                        },
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
