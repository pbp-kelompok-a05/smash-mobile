import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/models/Filtering_entry.dart';
import 'package:smash_mobile/post/post_api.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/widgets/app_top_bar.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/post_card.dart';

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
        _item = data;
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
      appBar: AppTopBar(
        title: 'Post Detail',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Container(
        color: Colors.white,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Failed to load post'),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_item == null) {
      return const Center(child: Text('Post not found.'));
    }
    final item = _item!;
    final avatar = _resolveMediaUrl(item.profilePhoto);
    final defaultAvatar = '${_api.baseUrl}/static/images/user-profile.png';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PostCard(
        item: item,
        avatarUrl: avatar,
        defaultAvatar: defaultAvatar,
        resolveAvatar: _resolveMediaUrl,
        showMenu: true,
        currentUserId: _currentUserId,
        showFooterActions: true,
        enableInteractions: false,
        profilePageBuilder: (id) => ProfilePage(userId: id),
      ),
    );
  }
}
