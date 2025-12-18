// ignore_for_file: unused_import, unused_field

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/notifications/notifications_api.dart';
import 'package:smash_mobile/post/post_api.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/post/post_detail_page.dart';
import 'package:smash_mobile/widgets/app_top_bar.dart';
import 'package:smash_mobile/widgets/default_avatar.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late NotificationsApi _api;
  bool _loading = true;
  String? _error;
  List<NotificationItem> _items = [];
  String? _photoUrl;
  String? _username;

  @override
  void initState() {
    super.initState();
    final request = Provider.of<CookieRequest>(context, listen: false);
    _api = NotificationsApi(request: request);
    _loadProfileHeader();
    _load();
  }

  Future<void> _loadProfileHeader() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    if (!request.loggedIn) {
      setState(() {
        _photoUrl = null;
        _username = null;
      });
      return;
    }
    try {
      final profile = await _api.request.get('${_api.baseUrl}/profil/api/profile/');
      if (!mounted) return;
      if (profile is Map<String, dynamic> && profile['status'] == true) {
        final data = profile['data'] as Map?;
        final photo = data?['profile_photo'] as String?;
        final username = data?['username']?.toString();
        _photoUrl = _api.defaultAvatar;
        if (photo != null && photo.trim().isNotEmpty) {
          final resolved = _api.defaultAvatar.replaceFirst(
            '/static/images/user-profile.png',
            '',
          );
          _photoUrl = photo.startsWith('http')
              ? photo
              : '$resolved$photo'.replaceAll('//', '/');
        }
        _username = username;
      }
    } catch (_) {
      if (!mounted) return;
      _photoUrl = _api.defaultAvatar;
    }
  }

  Future<void> _load() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    if (!request.loggedIn) {
      setState(() {
        _loading = false;
        _items = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = data;
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
    final request = context.watch<CookieRequest>();
    final loggedIn = request.loggedIn;
    if (!loggedIn) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: const LeftDrawer(),
        appBar: AppTopBar(
          title: 'Notifications',
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: _buildLoginGate(),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      appBar: AppTopBar(
        title: 'Notifications',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _buildBody(),
          ),
        ),
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
            Text(
              'Failed to load notifications',
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              textAlign: TextAlign.center,
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
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No notifications yet.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _NotificationCard(
            item: item,
            defaultAvatar: _api.defaultAvatar,
          ),
        );
      },
    );
  }

  Widget _buildLoginGate() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F6F6), Color(0xFFFFF3F4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Login required to view notifications.',
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
              ElevatedButton(
                onPressed: _openLogin,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmashLoginPage()),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.defaultAvatar});

  final NotificationItem item;
  final String defaultAvatar;

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final avatar = item.actorPhoto?.trim().isNotEmpty == true
        ? item.actorPhoto!
        : defaultAvatar;
    final actor = item.actor.trim();
    String remainder = item.message.trim();
    if (actor.isNotEmpty) {
      final lowerActor = actor.toLowerCase();
      final lowerMsg = remainder.toLowerCase();
      if (lowerMsg.startsWith('@$lowerActor')) {
        remainder = remainder.substring(actor.length + 1).trimLeft();
      } else if (lowerMsg.startsWith(lowerActor)) {
        remainder = remainder.substring(actor.length).trimLeft();
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: item.actorId != null ? () => _openProfile(context) : null,
            borderRadius: BorderRadius.circular(22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                avatar,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const DefaultAvatar(size: 44),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.postTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: item.actorId != null ? () => _openProfile(context) : null,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        children: [
                          if (actor.isNotEmpty)
                            TextSpan(
                              text: '@$actor',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          if (remainder.isNotEmpty)
                            TextSpan(text: ' $remainder'),
                          const TextSpan(text: ' on '),
                          TextSpan(
                            text: '"${item.postTitle}"',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
                if (item.content != null && item.content!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.content!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTime(item.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B3DFB),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        if (item.postId != 0) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PostDetailPage(postId: item.postId),
                            ),
                          );
                        }
                      },
                      child: const Text('View post details'),
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

  void _openProfile(BuildContext context) {
    if (item.actorId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(userId: item.actorId),
      ),
    );
  }
}
