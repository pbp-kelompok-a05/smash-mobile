// ignore_for_file: unnecessary_import, deprecated_member_use, curly_braces_in_flow_control_structures, unused_import, unnecessary_underscores

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smash_mobile/profile/profile_api.dart';
import 'package:smash_mobile/screens/post_list.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/screens/search.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';

/// MyHomePage - Dashboard forum diskusi Padel dengan UI modern
///
/// Fitur:
/// - Carousel gambar padel courts otomatis
/// - Info cards navigasi (Latest Posts → PostListPage, Your Hub → ProfilePage)
/// - Menu grid interaktif (Create → PostEntryFormPage)
/// - Animasi smooth dan glassmorphism effect
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  // === CONTROLLERS & KEYS ===
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late final TextEditingController _searchController;

  // === USER STATE ===
  String? _photoUrl;
  String? _username;
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;

  // === CAROUSEL CONTROLLER & TIMER ===
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

  // === MENU ITEMS (Padel Themed) ===
  final List<ItemHomepage> _menuItems = [
    ItemHomepage(
      'Latest Posts',
      Icons.article_outlined,
      const Color(0xFF5E72E4),
    ),
    ItemHomepage('Your Hub', Icons.person_pin, const Color(0xFF2DCE89)),
    ItemHomepage('Create', Icons.add_circle_outline, const Color(0xFFFB6340)),
    ItemHomepage('Logout', Icons.logout, const Color(0xFFF5365C)),
  ];

  // === CAROUSEL IMAGES (Padel Courts) ===
  final List<String> _carouselImages = [
    'https://images.unsplash.com/photo-1577223625818-75bc1f2ac0e5?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1543326727-cf6c39e8f84c?w=800&h=600&fit=crop',
    'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=800&h=600&fit=crop',
  ];

  // === LIFECYCLE METHODS ===
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _searchController = TextEditingController();
    _animationController.forward();
    _loadProfileHeader();

    // Start carousel autoplay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCarouselAutoPlay();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  // === CAROUSEL AUTOPLAY ===
  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController.hasClients && mounted) {
        final nextPage = (_currentCarouselIndex + 1) % _carouselImages.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
      }
    });
  }

  void _pauseCarousel() {
    _carouselTimer?.cancel();
  }

  void _resumeCarousel() {
    _startCarouselAutoPlay();
  }

  // === NAVIGATION & EVENT HANDLERS ===
  void _handleMenuTap(BuildContext context, ItemHomepage item) {
    switch (item.name) {
      case 'Latest Posts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostListPage()),
        );
        break;
      case 'Your Hub':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
      case 'Create':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostEntryFormPage()),
        );
        break;
      case 'Logout':
        _handleLogout();
        break;
      default:
        _showPlaceholderMessage(item.name);
    }
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

  void _openLogin() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SmashLoginPage()),
  );
  void _openRegister() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SmashRegisterPage()),
  );
  void _openProfile() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ProfilePage()),
  );
  void _openSearch(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(initialQuery: normalized)),
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    final request = context.read<CookieRequest>();
    try {
      await request.logout('https://nathanael-leander-smash.pbp.cs.ui.ac.id/authentication/logout/');
    } catch (e) {
      developer.log('Logout error: $e', name: 'AuthDebug');
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SmashLoginPage()),
          (route) => false,
        );
      }
    }
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
        _photoUrl =
            profileApi.resolveMediaUrl(profile.profilePhoto) ??
            profileApi.defaultAvatarUrl;
        _username = profile.username;
      });
    } catch (e) {
      developer.log('Profile load error: $e', name: 'ProfileDebug');
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
    final loggedInNow = request.loggedIn;
    if (_isLoggedIn != loggedInNow) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileHeader());
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAnimatedAppBar(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollStartNotification) {
            _pauseCarousel();
          } else if (scrollNotification is ScrollEndNotification) {
            _resumeCarousel();
          }
          return false;
        },
        child: _buildAnimatedBody(),
      ),
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
                searchController: _searchController,
                onSearchSubmit: _openSearch,
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
            const SizedBox(height: 32),
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
          content: 'Forum diskusi terbaru',
          icon: Icons.forum_outlined,
          color: const Color(0xFF5E72E4),
          delay: 200,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostListPage()),
          ),
        ),
        _buildAnimatedInfoCard(
          title: 'Your Hub',
          content: 'Profil & aktivitas',
          icon: Icons.person_pin_outlined,
          color: const Color(0xFF2DCE89),
          delay: 400,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
        ),
        _buildAnimatedInfoCard(
          title: 'Create',
          content: 'Buat diskusi baru',
          icon: Icons.add_circle_outline,
          color: const Color(0xFFFB6340),
          delay: 600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostEntryFormPage()),
          ),
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
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final intervalValue = Tween<double>(begin: 0, end: 1)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(delay / 1000, 1, curve: Curves.easeOut),
              ),
            )
            .value;

        return Transform.translate(
          offset: Offset(0, 30 * (1 - intervalValue)),
          child: Opacity(opacity: intervalValue, child: child),
        );
      },
      child: InfoCard(
        title: title,
        content: content,
        icon: icon,
        color: color,
        onTap: onTap,
      ),
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
            '🎾 Padel Forum',
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🏟️ Your Ultimate Padel Discussion Hub',
            style: GoogleFonts.inter(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          _buildImageCarousel(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            PageView.builder(
              controller: _carouselController,
              itemCount: _carouselImages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildCarouselImage(index);
              },
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _carouselImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: index == _currentCarouselIndex ? 22 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(5),
                      color: index == _currentCarouselIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselImage(int index) {
    return Image.network(
      _carouselImages[index],
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4A2B55).withOpacity(0.8),
                const Color(0xFF9D50BB).withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Padel Court ${index + 1}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridMenu() {
    final request = context.watch<CookieRequest>();
    final items = request.loggedIn
        ? _menuItems
        : _menuItems.where((it) => it.name.toLowerCase() != 'logout').toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
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
              scale: Tween<double>(begin: 0.8, end: 1.0)
                  .animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: interval,
                    ),
                  )
                  .value,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: interval,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: ItemCard(
            item: items[index],
            onTap: () => _handleMenuTap(context, items[index]),
          ),
        );
      },
    );
  }
}

/// Mengarahkan ke:
/// - Latest Posts: PostListPage
/// - Your Hub: ProfilePage
/// - Create: PostEntryFormPage
class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const InfoCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: MediaQuery.of(context).size.width / 3.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          ),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
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

/// Setiap item memiliki fungsi spesifik:
/// - Latest Posts: Buka forum diskusi
/// - Your Hub: Buka profil user
/// - Create: Buat post baru
/// - Logout: Keluar dari akun
class ItemCard extends StatefulWidget {
  final ItemHomepage item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.item.color.withOpacity(0.15),
                widget.item.color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.item.color.withOpacity(_isHovered ? 0.5 : 0.3),
              width: _isHovered ? 2.0 : 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.item.color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: widget.item.color.withOpacity(
                      _isHovered ? 0.25 : 0.15,
                    ),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    widget.item.icon,
                    color: widget.item.color,
                    size: 28,
                  ),
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
    );
  }
}
