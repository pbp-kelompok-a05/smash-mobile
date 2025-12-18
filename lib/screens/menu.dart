// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';

/// Halaman dashboard utama aplikasi dengan UI modern dan animasi
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  // === CONTROLLERS & KEYS ===
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;

  // === USER STATE ===
  String? _photoUrl;
  String? _username;
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;

  // === MENU ITEMS ===
  final List<ItemHomepage> _menuItems = [
    ItemHomepage('All Posts', Icons.article_outlined, const Color(0xFF5E72E4)),
    ItemHomepage('My Posts', Icons.person_outline, const Color(0xFF2DCE89)),
    ItemHomepage('Create Post', Icons.add_circle_outline, const Color(0xFFFB6340)),
    ItemHomepage('Logout', Icons.logout, const Color(0xFFF5365C)),
  ];

  // === LIFECYCLE METHODS ===
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
    _loadProfileHeader();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // === NAVIGATION & EVENT HANDLERS ===
  void _handleMenuTap(BuildContext context, ItemHomepage item) {
    // Navigasi ke halaman form post
    if (item.name == 'Create Post') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostEntryFormPage()),
      );
      return;
    }

    // Handle logout
    if (item.name == 'Logout') {
      _handleLogout();
      return;
    }

    // Placeholder untuk menu lain
    _showPlaceholderMessage(item.name);
  }

  void _showPlaceholderMessage(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$itemName is coming soon',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _openLogin() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmashLoginPage()));
  void _openRegister() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmashRegisterPage()));
  void _openProfile() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    final request = context.read<CookieRequest>();
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

  // === DATA LOADING ===
  Future<void> _loadProfileHeader() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    
    if (!request.loggedIn) {
      setState(() {
        _isLoggedIn = false;
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
        _isLoggedIn = true;
        _photoUrl = profileApi.resolveMediaUrl(profile.profilePhoto) ?? profileApi.defaultAvatarUrl;
        _username = profile.username;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = true;
        _photoUrl = profileApi.defaultAvatarUrl;
      });
    }
  }

  // === UI BUILDERS ===
  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    
    // Update state jika status login berubah
    if (_isLoggedIn != request.loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileHeader());
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(), 
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAnimatedAppBar(), 
      body: _buildAnimatedBody(),
    );
  }

  /// Membangun AppBar dengan animasi slide-down
  PreferredSizeWidget _buildAnimatedAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _animationController.value)),
            child: Opacity(
              opacity: _animationController.value,
              child: NavBar(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                isLoggedIn: _isLoggedIn,
                showCreate: _isLoggedIn,
                photoUrl: _photoUrl,
                photoBytes: null,
                username: _username,
                onLogin: _openLogin,
                onRegister: _openRegister,
                onLogout: _handleLogout,
                onProfileTap: _openProfile,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBody() {
    return FadeTransition(
      opacity: _animationController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCards(),
            const SizedBox(height: 32),
            _buildGradientTitle(),
            const SizedBox(height: 24),
            _buildGridMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildAnimatedInfoCard(
          title: 'Latest Posts',
          content: 'Newest discussions',
          icon: Icons.forum,
          color: const Color(0xFF5E72E4),
          delay: 200,
        ),
        _buildAnimatedInfoCard(
          title: 'Your Hub',
          content: 'Access your profile',
          icon: Icons.person_pin,
          color: const Color(0xFF2DCE89),
          delay: 400,
        ),
        _buildAnimatedInfoCard(
          title: 'Create',
          content: 'Share a post',
          icon: Icons.create,
          color: const Color(0xFFFB6340),
          delay: 600,
        ),
      ],
    );
  }

  Widget _buildAnimatedInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final intervalValue = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delay / 1000, 1, curve: Curves.easeOut),
          ),
        ).value;
        
        return Transform.translate(
          offset: Offset(0, 30 * (1 - intervalValue)),
          child: Opacity(opacity: intervalValue, child: child),
        );
      },
      child: InfoCard(title: title, content: content, icon: icon, color: color),
    );
  }

  Widget _buildGradientTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF5E72E4), Color(0xFF9D50BB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Column(
        children: [
          Text(
            'WELCOME TO',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🏆 Smash',
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '⚽ Your Ultimate Football Store',
            style: GoogleFonts.inter(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final interval = Interval(
              index * 0.1,
              0.65 + index * 0.1,
              curve: Curves.easeOut,
            );
            return Transform.scale(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _animationController, curve: interval),
              ).value,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: _animationController, curve: interval),
                ),
                child: child,
              ),
            );
          },
          child: ItemCard(item: _menuItems[index], onTap: () => _handleMenuTap(context, _menuItems[index])),
        );
      },
    );
  }
}

/// Widget kartu informasi
class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      color: color.withOpacity(0.1),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 3.5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                content,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model item menu dashboard
class ItemHomepage {
  final String name;
  final IconData icon;
  final Color color;

  ItemHomepage(this.name, this.icon, this.color);
}

/// Widget kartu menu dengan efek hover
class ItemCard extends StatefulWidget {
  final ItemHomepage item;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isHovered = false;

  void _onEnter(PointerEvent event) => setState(() => _isHovered = true);
  void _onExit(PointerEvent event) => setState(() => _isHovered = false);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        child: Material(
          color: widget.item.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: widget.item.color.withOpacity(0.2),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: widget.item.color.withOpacity(0.3), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: widget.item.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Icon(widget.item.icon, color: widget.item.color, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.item.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}