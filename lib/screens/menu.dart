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
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/register.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';
import 'package:smash_mobile/widgets/navbar.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';

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

  // === CAROUSEL CONTROLLER & TIMER ===
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

  // === YOUTUBE CONTROLLER ===
  late YoutubePlayerController _youtubeController;

  // === MENU ITEMS ===
  final List<ItemHomepage> _menuItems = [
    ItemHomepage('All Posts', Icons.article_outlined, const Color(0xFF5E72E4)),
    ItemHomepage('My Posts', Icons.person_outline, const Color(0xFF2DCE89)),
    ItemHomepage('Create Post', Icons.add_circle_outline, const Color(0xFFFB6340)),
    ItemHomepage('Logout', Icons.logout, const Color(0xFFF5365C)),
  ];

  // Untuk saat ini menggunakan gambar placeholder dari Unsplash
  final List<String> _carouselImages = [
    'https://cdnpro.eraspace.com/media/mageplaza/blog/post/p/a/padel_-_primary.jpg', 
    'https://images.unsplash.com/photo-1552674605-db6ceb900c70?w=800&h=600&fit=crop', 
    'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?w=800&h=600&fit=crop', 
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
    
    // Initialize YouTube controller dengan video ID dari URL
    _youtubeController = YoutubePlayerController(
      initialVideoId: 'T936NUtQZ-0',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        loop: false,
        hideControls: false,
      ),
    );

    // Start carousel autoplay
    _startCarouselAutoPlay();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _youtubeController.dispose();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  // === CAROUSEL AUTOPLAY ===
  void _startCarouselAutoPlay() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_carouselController.hasClients) {
        final nextPage = (_currentCarouselIndex + 1) % _carouselImages.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // === NAVIGATION & EVENT HANDLERS ===
  void _handleMenuTap(BuildContext context, ItemHomepage item) {
    // Navigasi ke halaman form post
    if (item.name == 'Create Post') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PostEntryFormPage()));
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
        content: Text('$itemName is coming soon', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
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
          const SizedBox(height: 8),
          Text(
            '⚽ Your Ultimate Football Store',
            style: GoogleFonts.inter(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24), // Spasi tambahan
            
          // NEW: Auto-scrolling image carousel
          _buildImageCarousel(),
        ],
      ),
    );
  }

  // NEW: Widget carousel foto bergeser otomatis
  Widget _buildImageCarousel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
              itemBuilder: (context, index) {
                final imageUrl = _carouselImages[index];
                developer.log('Loading image: $imageUrl', name: 'CarouselDebug'); // DEBUG LOG
                
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      developer.log('Image loaded: $imageUrl', name: 'CarouselDebug'); // DEBUG LOG
                      return child;
                    }
                    developer.log('Image loading: $imageUrl - ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}', name: 'CarouselDebug'); // DEBUG LOG
                    return Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    developer.log('Image error: $imageUrl - $error', name: 'CarouselDebug'); // DEBUG LOG
                    return Container(
                      color: Colors.red.withOpacity(0.1),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: GoogleFonts.inter(color: Colors.red.shade400, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'URL: ${imageUrl.substring(0, 30)}...',
                              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Indicator dots
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _carouselImages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentCarouselIndex
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
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