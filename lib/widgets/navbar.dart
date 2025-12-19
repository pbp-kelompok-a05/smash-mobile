// ignore_for_file: unused_import

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smash_mobile/screens/search.dart';
import 'package:smash_mobile/widgets/default_avatar.dart'; // Import default_avatar.dart

// =============================================================================
// NAVBAR WIDGET - FIXED FOR OVERFLOW & AVATAR ERRORS
// =============================================================================
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  const NavBar({
    super.key,
    this.onMenuTap,
    this.showCreate = false,
    this.isLoggedIn = false,
    this.onCreatePost,
    this.username,
    this.photoUrl,
    this.searchController,
    this.onSearchSubmit,
    this.searchPageBuilder,
    this.onLogin,
    this.onRegister,
    this.onLogout,
    this.onProfileTap,
    this.photoBytes,
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

  @override
  Widget build(BuildContext context) {
    final controller = searchController ?? TextEditingController();
    final loggedIn = isLoggedIn;
    final resolvedUsername = loggedIn
        ? (username?.trim().isNotEmpty == true ? username!.trim() : 'User')
        : 'Guest';
    final canCreate = loggedIn && showCreate;

    void handleSearch(String value) {
      final query = value.trim();
      if (query.isEmpty) return;
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SearchPage(initialQuery: query),
        ),
      );
    }

    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, size: 26),
              onPressed: onMenuTap,
            ),
            
            // FIX: Expanded agar search field tidak overflow
            Expanded(
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 10),
                    
                    // FIX: Expanded di TextField untuk mencegah overflow
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onSubmitted: handleSearch,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 10),
            
            // FIX: Wrap action buttons dengan Flexible untuk mencegah overflow
            if (!loggedIn) ...[
              // FIX: Wrap dengan Row dan mainAxisSize.min
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onLogin,
                    child: const Text(
                      'Login',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onRegister,
                    child: const Text(
                      'Register',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // FIX: Gunakan Flexible untuk Create Post button
              if (canCreate)
                Flexible(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF8B3DFB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onCreatePost ?? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Create post coming soon')),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text(
                      'Create Post',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.mic_none),
                  onPressed: () {},
                ),
                
              const SizedBox(width: 6),
              
              // FIX: Gunakan SafeAvatar dari default_avatar.dart
              _ProfileMenu(
                isLoggedIn: loggedIn,
                username: resolvedUsername,
                photoUrl: photoUrl,
                photoBytes: photoBytes,
                onLogin: onLogin,
                onRegister: onRegister,
                onLogout: onLogout,
                onProfileTap: onProfileTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PROFILE MENU - FIXED WITH SafeAvatar
// =============================================================================
class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.isLoggedIn,
    required this.username,
    required this.photoUrl,
    required this.photoBytes,
    this.onLogin,
    this.onRegister,
    this.onLogout,
    this.onProfileTap,
  });

  final bool isLoggedIn;
  final String? username;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onLogout;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Profile menu',
      onSelected: (value) {
        switch (value) {
          case 'login':
            onLogin?.call();
            break;
          case 'register':
            onRegister?.call();
            break;
          case 'logout':
            onLogout?.call();
            break;
          case 'profile':
            onProfileTap?.call();
            break;
        }
      },
      itemBuilder: (context) {
        if (!isLoggedIn) {
          return [
            const PopupMenuItem(value: 'login', child: Text('Login')),
            const PopupMenuItem(value: 'register', child: Text('Register')),
          ];
        }
        return [
          const PopupMenuItem(value: 'profile', child: Text('Profile')),
          const PopupMenuItem(value: 'logout', child: Text('Logout')),
        ];
      },
      
      // FIX: Gunakan SafeAvatar untuk child (menghindari CircleAvatar error)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX: SafeAvatar dengan validasi URL dan bytes
            SafeAvatar(
              size: 36,
              imageUrl: photoUrl,
              backgroundColor: Colors.grey.shade200,
              borderWidth: 2,
              child: (photoBytes != null && photoBytes!.isNotEmpty)
                  ? Image.memory(
                      photoBytes!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}