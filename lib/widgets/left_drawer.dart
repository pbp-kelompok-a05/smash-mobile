// ignore_for_file: unnecessary_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/notifications/notifications_page.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';
import 'package:smash_mobile/screens/post_list.dart';

/// Left drawer dengan glassmorphism effect dan navigasi modern
class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final loggedIn = request.loggedIn;

    return Drawer(
      width: 280,
      backgroundColor: Colors.transparent, // Transparan untuk glass effect
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: const Color(
            0xFF4A2B55,
          ).withOpacity(0.85), // Warna ungu semi-transparan
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header dengan gradient dan logo
              _buildDrawerHeader(),

              // Menu items dengan glass effect
              _buildMenuItem(
                context: context,
                icon: Icons.home_outlined,
                title: 'Home',
                onTap: () => _navigateTo(context, const MyHomePage()),
              ),

              _buildMenuItem(
                context: context,
                icon: Icons.person_outline,
                title: 'Profile',
                onTap: () => _navigateTo(context, const ProfilePage()),
              ),

              _buildMenuItem(
                context: context,
                icon: Icons.add_circle_outline,
                title: 'Create Post',
                onTap: () => _navigateTo(context, const PostEntryFormPage()),
              ),

              _buildMenuItem(
                context: context,
                icon: Icons.newspaper_outlined,
                title: 'All Post',
                onTap: () => _navigateTo(context, const PostListPage()),
              ),

              _buildMenuItem(
                context: context,
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () =>
                    _navigateToPush(context, const NotificationsPage()),
              ),

              const Divider(color: Colors.white24, height: 1),

              if (loggedIn)
                _buildMenuItem(
                  context: context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => _handleLogout(context),
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Membangun drawer header dengan gradient dan logo modern
  Widget _buildDrawerHeader() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF4A2B55), const Color(0xFF9D50BB)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Logo icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports_tennis,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // App title
            Text(
              'Smash Mobile',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),

            // Tagline
            Text(
              "Forum Padel #1 di Indonesia",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun item menu dengan glassmorphism effect
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: iconColor ?? Colors.white70, size: 22),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.white,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Navigasi dengan pushReplacement (untuk halaman utama)
  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context); // Tutup drawer
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Navigasi dengan push (untuk halaman sekunder)
  void _navigateToPush(BuildContext context, Widget page) {
    Navigator.pop(context); // Tutup drawer
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  /// Handle logout dengan konfirmasi
  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context); // Tutup drawer

    final request = context.read<CookieRequest>();
    try {
      await request.logout('http://localhost:8000/authentication/logout/');
    } catch (_) {}

    // Navigasi ke login dan hapus semua history
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SmashLoginPage()),
      (route) => false,
    );
  }
}
