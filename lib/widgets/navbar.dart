// ignore_for_file: unused_import, deprecated_member_use, unused_element

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/screens/post_form_entry.dart';
import 'package:smash_mobile/widgets/default_avatar.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({
    super.key,
    this.onMenuTap,
    this.showCreate = false,
    this.isLoggedIn = false,
    this.onCreatePost,
    this.username,
    this.photoUrl,
    this.photoBytes,
    this.searchController,
    this.onSearchSubmit,
    this.searchPageBuilder,
    this.onLogin,
    this.onRegister,
    this.onLogout,
    this.onProfileTap,
  });

  final VoidCallback? onMenuTap;
  final bool showCreate;
  final bool isLoggedIn;
  final VoidCallback? onCreatePost;
  final String? username;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmit;
  final Widget Function(String query)? searchPageBuilder;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onLogout;
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  /// Resolve username (Guest/User/Custom)
  String _resolveUsername() {
    if (!isLoggedIn) return 'Guest';
    final name = username?.trim();
    return (name != null && name.isNotEmpty) ? name : 'User';
  }

  /// Handle search submit
  void _handleSearch(String value, BuildContext context) {
    final query = value.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    
    if (onSearchSubmit != null) {
      onSearchSubmit!(query);
      return;
    }
    if (searchPageBuilder != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => searchPageBuilder!(query)),
      );
      return;
    }
  }

  /// Navigasi default ke halaman create post
  void _navigateToCreatePost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostEntryFormPage()),
    );
  }

  /// Navigasi default ke halaman profil
  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUsername = _resolveUsername();
    final canCreate = isLoggedIn && showCreate;

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.purple.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Animated menu icon
            if (onMenuTap != null)
              _AnimatedMenuIcon(onTap: onMenuTap!)
            else
              const SizedBox(width: 12),
            
            const SizedBox(width: 12),
            
            // Glassmorphism search field
            Expanded(
              child: _SearchField(
                controller: searchController,
                onSubmitted: (value) => _handleSearch(value, context),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Action buttons section
            if (!isLoggedIn)
              _AuthButtons(onLogin: onLogin, onRegister: onRegister)
            else ...[
              // Create Post button dengan gradient
              if (canCreate)
                _CreatePostButton(onPressed: onCreatePost ?? () => _navigateToCreatePost(context)),
              
              const SizedBox(width: 8),
              
              // Profile menu dengan avatar
              _ProfileMenu(
                username: resolvedUsername,
                photoUrl: photoUrl,
                photoBytes: photoBytes,
                onProfileTap: onProfileTap ?? () => _navigateToProfile(context),
                onLogout: onLogout,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget search field dengan glassmorphism effect
class _SearchField extends StatelessWidget {
  const _SearchField({
    this.controller,
    required this.onSubmitted,
  });

  final TextEditingController? controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          if (controller != null)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (context, value, child) {
                if (value.text.isNotEmpty) {
                  return IconButton(
                    icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7), size: 20),
                    onPressed: () => controller!.clear(),
                    splashRadius: 20,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }
}

/// Widget untuk tombol auth (login/register)
class _AuthButtons extends StatelessWidget {
  const _AuthButtons({
    this.onLogin,
    this.onRegister,
  });

  final VoidCallback? onLogin;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.white.withOpacity(0.8)),
          ),
          onPressed: onLogin,
          child: const Text(
            'Login',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: Colors.purple.shade700,
          ),
          onPressed: onRegister,
          child: const Text(
            'Register',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget untuk tombol Create Post dengan gradient
class _CreatePostButton extends StatelessWidget {
  const _CreatePostButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.pink.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
        label: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Widget untuk menu profil dengan avatar
class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.username,
    required this.photoUrl,
    required this.photoBytes,
    this.onProfileTap,
    this.onLogout,
  });

  final String username;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Profile menu',
      onSelected: (value) {
        switch (value) {
          case 'profile':
            onProfileTap?.call();
            break;
          case 'logout':
            onLogout?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: const Icon(Icons.person, size: 20),
            title: Text(username, style: const TextStyle(fontSize: 14)),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: const Icon(Icons.logout, size: 20, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
            dense: true,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _UserAvatar(
              photoUrl: photoUrl,
              photoBytes: photoBytes,
              username: username,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Widget avatar user dengan validasi multi-level
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.photoUrl,
    required this.photoBytes,
    required this.username,
  });

  final String? photoUrl;
  final Uint8List? photoBytes;
  final String username;

  @override
  Widget build(BuildContext context) {
    // Prioritas 1: photoBytes dari memory
    if (photoBytes != null && photoBytes!.isNotEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.memory(
            photoBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackAvatar();
            },
          ),
        ),
      );
    }
    
    // Prioritas 2: photoUrl dari network
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return SafeAvatar(
        size: 36,
        imageUrl: photoUrl,
        backgroundColor: Colors.grey.shade200,
        borderWidth: 2,
        borderColor: Colors.white,
      );
    }
    
    // Prioritas 3: fallback dengan inisial
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// Widget menu icon animasi
class _AnimatedMenuIcon extends StatefulWidget {
  const _AnimatedMenuIcon({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_AnimatedMenuIcon> createState() => _AnimatedMenuIconState();
}

class _AnimatedMenuIconState extends State<_AnimatedMenuIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value * 3.14,
            child: const Icon(
              Icons.menu,
              size: 26,
              color: Colors.white,
            ),
          );
        },
      ),
      onPressed: _handleTap,
    );
  }
}