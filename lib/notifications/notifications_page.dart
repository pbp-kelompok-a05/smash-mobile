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
import 'package:google_fonts/google_fonts.dart';
import 'package:smash_mobile/screens/register.dart';

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
    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Notifications',
                    style: TextStyle(
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
                  if (!loggedIn)
                    TextButton(
                      onPressed: _openLogin,
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ];
          },
          body: loggedIn ? _buildLoggedInBody() : _buildLoginGate(),
        ),
      ),
    );
  }

  Widget _buildLoggedInBody() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 120),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load notifications',
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
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
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 140),
          Center(
            child: Text(
              'No notifications yet.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
              child: const Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Colors.white,
                ),
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
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
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
                    'You need to be logged in to view your notifications',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openLogin,
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(
                      'Login',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    );
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SmashLoginPage(redirectTo: NotificationsPage()),
      ),
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
    final local = dt.toLocal();
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
    final day = local.day;
    final month = months[local.month - 1];
    final year = local.year;
    final sameYear = year == now.year;
    return sameYear ? '$month $day' : '$month $day $year';
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: Colors.white.withOpacity(0.15),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: item.actorId != null ? () => _openProfile(context) : null,
                borderRadius: BorderRadius.circular(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    avatar,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const DefaultAvatar(size: 48),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.postTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap:
                            item.actorId != null ? () => _openProfile(context) : null,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            children: [
                              if (actor.isNotEmpty)
                                TextSpan(
                                  text: '@$actor',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (remainder.isNotEmpty)
                                TextSpan(text: ' $remainder'),
                              const TextSpan(text: ' on '),
                              TextSpan(
                                text: '"${item.postTitle}"',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (item.content != null && item.content!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.content!,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(item.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          if (item.postId != 0) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PostDetailPage(postId: item.postId),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'View post details',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
