// ignore_for_file: deprecated_member_use, unused_local_variable

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman utama aplikasi yang menampilkan dashboard interaktif
/// dengan animasi, gradient, dan layout modern.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  /// Key untuk mengontrol scaffold (drawer)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// Data profil pengguna
  String? _photoUrl;
  String? _username;
  Uint8List? _photoBytes;
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;

  /// Controller untuk animasi fade-in
  late AnimationController _animationController;

  /// Daftar menu utama dengan ikon dan warna tema
  final List<ItemHomepage> _menuItems = [
    ItemHomepage("All Products", Icons.list, const Color(0xFF5E72E4)),
    ItemHomepage("My Products", Icons.shopping_bag, const Color(0xFF2DCE89)),
    ItemHomepage("Create Product", Icons.add_circle, const Color(0xFFFB6340)),
    ItemHomepage("Logout", Icons.logout, const Color(0xFFF5365C)),
  ];

  @override
  void initState() {
    super.initState();
    // Setup animasi controller dengan durasi 1 detik
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward(); // Mulai animasi
    _loadProfileHeader();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Menangani tap pada item menu
  /// [item] - Item yang dipilih oleh pengguna
  void _handleMenuTap(BuildContext context, ItemHomepage item) {
    // Tampilkan snackbar dengan animasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.name} is coming soon',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Navigasi ke halaman login
  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SmashLoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Navigasi ke halaman register
  void _openRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmashRegisterPage()),
    );
  }

  /// Navigasi ke halaman profil
  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ProfilePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  /// Memuat data profil pengguna dari API
  /// Mengambil foto profil dan username untuk ditampilkan di navbar
  Future<void> _loadProfileHeader() async {
    final request = Provider.of<CookieRequest>(context, listen: false);
    final logged = request.loggedIn;
    
    if (!logged) {
      setState(() {
        _isLoggedIn = false;
        _photoUrl = null;
        _username = null;
        _photoBytes = null;
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
        _photoBytes = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = true;
        _photoUrl = profileApi.defaultAvatarUrl;
        _photoBytes = null;
      });
    }
  }

  /// Menangani proses logout dengan konfirmasi
  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    final request = context.read<CookieRequest>();
    try {
      await request.logout('http://localhost:8000/authentication/logout/');
    } catch (_) {}

    if (!mounted) return;
    _isLoggingOut = false;
    
    // Navigasi ke login dan hapus semua route sebelumnya
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SmashLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    
    // Reload profil jika status login berubah
    if (_isLoggedIn != request.loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadProfileHeader();
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      backgroundColor: const Color(0xFF0F0F0F), // Warna background gelap modern
      
      // AppBar custom dengan gradient
      appBar: PreferredSize(
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
                  photoBytes: _photoBytes,
                  username: _username,
                  onLogin: () => _openLogin(context),
                  onRegister: () => _openRegister(context),
                  onLogout: _handleLogout,
                  onProfileTap: () => _openProfile(context),
                ),
              ),
            );
          },
        ),
      ),
      
      // Body dengan animasi fade-in
      body: FadeTransition(
        opacity: _animationController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Cards dengan animasi staggered
              _buildInfoCards(),
              const SizedBox(height: 32),
              
              // Judul dengan gradient
              _buildGradientTitle(),
              const SizedBox(height: 24),
              
              // Grid Menu
              _buildGridMenu(),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun widget InfoCards dengan layout responsif
  Widget _buildInfoCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildAnimatedInfoCard(
              title: 'Latest Posts',
              content: 'Catch up with the newest discussions.',
              icon: Icons.forum,
              color: const Color(0xFF5E72E4),
              delay: 200,
            ),
            _buildAnimatedInfoCard(
              title: 'Your Hub',
              content: 'Access your padel profile quickly.',
              icon: Icons.person_pin,
              color: const Color(0xFF2DCE89),
              delay: 400,
            ),
            _buildAnimatedInfoCard(
              title: 'Create',
              content: 'Share a new post with the community.',
              icon: Icons.create,
              color: const Color(0xFFFB6340),
              delay: 600,
            ),
          ],
        );
      },
    );
  }

  /// Membangun animasi untuk setiap InfoCard
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
        final value = _animationController.value;
        final intervalValue = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
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

  /// Membangun judul dengan efek gradient
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

  /// Membangun grid menu dengan animasi
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
          child: ItemCard(
            item: _menuItems[index],
            onTap: () => _handleMenuTap(context, _menuItems[index]),
          ),
        );
      },
    );
  }
}

/// Widget untuk menampilkan informasi singkat dengan ikon dan warna tema
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
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
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

/// Model untuk item menu homepage
class ItemHomepage {
  final String name;
  final IconData icon;
  final Color color;

  ItemHomepage(this.name, this.icon, this.color);
}

/// Widget untuk menampilkan kartu menu interaktif dengan efek hover
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
                border: Border.all(
                  color: widget.item.color.withOpacity(0.3),
                  width: 1.5,
                ),
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