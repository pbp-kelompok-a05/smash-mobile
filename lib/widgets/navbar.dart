import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smash_mobile/screens/search.dart';
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
    final resolvedPhotoBytes = loggedIn ? photoBytes : null;
    final resolvedPhotoUrl = loggedIn ? photoUrl : null;
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
            if (!loggedIn) ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            ] else ...[
              if (canCreate)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF8B3DFB),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: const Color(0xFF8B3DFB).withOpacity(0.25),
                    elevation: 2,
                  ),
                  onPressed: onCreatePost ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Create post coming soon')),
                        );
                      },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Create Post',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.mic_none),
                  onPressed: () {},
                ),
              const SizedBox(width: 6),
              _ProfileMenu(
                isLoggedIn: loggedIn,
                username: resolvedUsername,
                photoUrl: resolvedPhotoUrl,
                photoBytes: resolvedPhotoBytes,
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
      child: _AvatarWithPlaceholder(
        photoUrl: photoUrl,
        photoBytes: photoBytes,
      ),
    );
  }
}

class _AvatarWithPlaceholder extends StatelessWidget {
  const _AvatarWithPlaceholder({required this.photoUrl, this.photoBytes});

  final String? photoUrl;
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    final hasBytes = photoBytes != null && photoBytes!.isNotEmpty;
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasBytes)
            CircleAvatar(
              radius: 18,
              backgroundImage: MemoryImage(photoBytes!),
            )
          else
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  hasPhoto ? NetworkImage(photoUrl!.trim()) : null,
              onBackgroundImageError: (_, __) {},
              backgroundColor: Colors.grey.shade200,
              child: (!hasPhoto && !hasBytes)
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }
}
