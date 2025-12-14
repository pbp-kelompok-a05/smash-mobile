import 'package:flutter/material.dart';

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
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchSubmit;
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;
  final VoidCallback? onLogout;
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final controller = searchController ?? TextEditingController();

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
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onSubmitted: onSearchSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoggedIn && showCreate)
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F0FE),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onCreatePost ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Create post coming soon')),
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
              isLoggedIn: isLoggedIn,
              username: username,
              photoUrl: photoUrl,
              onLogin: onLogin,
              onRegister: onRegister,
              onLogout: onLogout,
              onProfileTap: onProfileTap,
            ),
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
    this.onLogin,
    this.onRegister,
    this.onLogout,
    this.onProfileTap,
  });

  final bool isLoggedIn;
  final String? username;
  final String? photoUrl;
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : const AssetImage('assets/avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 6),
            Text(
              username ?? 'Guest',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}
