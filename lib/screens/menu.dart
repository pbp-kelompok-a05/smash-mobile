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
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';

/// Halaman dashboard utama aplikasi dengan UI modern dan animasi
/// 
/// Fitur Utama:
/// 1. Carousel gambar otomatis dengan gambar lokal/placeholder
/// 2. Menu grid interaktif
/// 3. Animasi smooth pada semua komponen
/// 4. Login state management
/// 5. Optimized image loading dengan cache
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

  // === USER STATE ===
  String? _photoUrl;
  String? _username;
  bool _isLoggedIn = false;
  bool _isLoggingOut = false;

  // === CAROUSEL CONTROLLER & TIMER ===
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

  // === MENU ITEMS ===
  final List<ItemHomepage> _menuItems = [
    ItemHomepage('All Posts', Icons.article_outlined, const Color(0xFF5E72E4)),
    ItemHomepage('My Posts', Icons.person_outline, const Color(0xFF2DCE89)),
    ItemHomepage(
      'Create Post',
      Icons.add_circle_outline,
      const Color(0xFFFB6340),
    ),
    ItemHomepage('Logout', Icons.logout, const Color(0xFFF5365C)),
  ];

  // Menggunakan gambar dari Unsplash dengan format dan ukuran yang sesuai
  final List<String> _carouselImages = [
    'https://i.pinimg.com/1200x/7e/b4/c3/7eb4c39e416a94f38b31a48df5e1bf69.jpg',
    'https://images.unsplash.com/photo-1577223625818-75bc1f2ac0e5?w=800&h=600&fit=crop&auto=format&q=80', // Football 2
    'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&h=600&fit=crop&auto=format&q=80', // Football 3
    'https://images.unsplash.com/photo-1543326727-cf6c39e8f84c?w=800&h=600&fit=crop&auto=format&q=80', // Football 4
  ];

  // === LIFECYCLE METHODS ===
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
    _loadProfileHeader();

    // Start carousel autoplay dengan delay untuk memastikan widget sudah terbangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCarouselAutoPlay();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  // === CAROUSEL AUTOPLAY ===
  void _startCarouselAutoPlay() {
    _carouselTimer?.cancel(); // Cancel existing timer
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

  // ✅ Function untuk pause/resume carousel saat user interaksi
  void _pauseCarousel() {
    _carouselTimer?.cancel();
  }

  void _resumeCarousel() {
    _startCarouselAutoPlay();
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

    if (item.name == 'All Posts') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostListPage()),
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

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    final request = context.read<CookieRequest>();
    try {
      await request.logout('http://localhost:8000/authentication/logout/');
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
        _photoUrl = profileApi.resolveMediaUrl(profile.profilePhoto) ??
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

    // Update state jika status login berubah
    if (_isLoggedIn != request.loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileHeader());
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const LeftDrawer(),
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAnimatedAppBar(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          // Pause carousel saat user scroll untuk pengalaman yang lebih baik
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
          const SizedBox(height: 8),
          Text(
            '⚽ Your Ultimate Football Store',
            style: GoogleFonts.inter(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          // ✅ Image carousel dengan optimasi performa
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
            // PageView untuk gambar
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

            // Gradient overlay untuk readability dan depth
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

            // Enhanced indicator dots
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
                      boxShadow: [
                        if (index == _currentCarouselIndex)
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Navigation arrows dengan efek glassmorphism
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildGlassButton(
                  icon: Icons.chevron_left,
                  onPressed: () {
                    if (_currentCarouselIndex > 0) {
                      _carouselController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildGlassButton(
                  icon: Icons.chevron_right,
                  onPressed: () {
                    if (_currentCarouselIndex < _carouselImages.length - 1) {
                      _carouselController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ),

            // Counter indicator (misal: 1/4)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentCarouselIndex + 1}/${_carouselImages.length}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk glass button pada carousel
  Widget _buildGlassButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Widget untuk setiap gambar dalam carousel dengan optimasi
  Widget _buildCarouselImage(int index) {
    final imageUrl = _carouselImages[index];

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // ✅ OPTIMASI 1: Gunakan headers untuk menghindari CORS issues
      headers: const {
        'User-Agent': 'Mozilla/5.0 (compatible; FlutterApp/1.0)',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
      },
      // ✅ OPTIMASI 2: Cache strategy yang lebih baik
      cacheWidth: 800,
      cacheHeight: 600,
      // ✅ OPTIMASI 3: Loading builder dengan skeleton yang lebih menarik
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: const Color(0xFF5E72E4),
                    strokeWidth: 3,
                    backgroundColor: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading football image...',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⚽',
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        );
      },
      // ✅ OPTIMASI 4: Enhanced error builder dengan fallback yang menarik
      errorBuilder: (context, error, stackTrace) {
        developer.log(
          'Carousel image error at index $index: $error\nURL: $imageUrl',
          name: 'CarouselDebug',
        );
        
        // Fallback ke gradient container dengan ikon
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(
                    Icons.sports_tennis,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Padel ${index + 1}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '🎾 🎾 🎾',
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        );
      },
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
            item: _menuItems[index],
            onTap: () => _handleMenuTap(context, _menuItems[index]),
          ),
        );
      },
    );
  }
}

/// Widget kartu informasi dengan glassmorphism effect
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

/// Widget kartu menu interaktif dengan efek hover
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
            color: widget.item.color.withOpacity(0.08),
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
                    color: widget.item.color.withOpacity(_isHovered ? 0.2 : 0.15),
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