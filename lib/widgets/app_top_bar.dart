// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// AppTopBar - Modern app bar dengan gradient dan animasi
///
/// Widget ini menggantikan AppBar bawaan dengan design yang lebih menarik:
/// - Gradient background (biru ke ungu)
/// - Animasi ikon menu (berputar saat ditekan)
/// - Typography yang lebih clean
/// - Shadow yang lebih halus
///
/// Cara pakai:
/// ```dart
/// AppTopBar(
///   title: 'Home',
///   onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
///   actions: [
///     IconButton(icon: Icon(Icons.search), onPressed: () {}),
///   ],
/// )
/// ```
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onMenuTap,
    this.actions,
    this.leading,
  });

  /// Judul yang ditampilkan di tengah/top
  final String title;

  /// Callback saat ikon menu ditekan
  final VoidCallback? onMenuTap;

  /// Widget tambahan di kanan (seperti search, notif)
  final List<Widget>? actions;

  /// Widget kustom di kiri (ganti icon menu)
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: preferredSize.height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade600, Colors.purple.shade600],
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading area: fixed-width container to keep icon centered
            Container(
              width: 56,
              alignment: Alignment.center,
              child:
                  leading ??
                  (onMenuTap != null
                      ? _AnimatedMenuIcon(onTap: onMenuTap!)
                      : const SizedBox.shrink()),
            ),

            // Title dengan typography yang lebih baik
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Actions
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

/// Ikon menu animasi yang berputar saat ditekan
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
    _animation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value * 3.14, // 180 derajat
            child: const Icon(Icons.menu, size: 28, color: Colors.white),
          );
        },
      ),
      onPressed: _handleTap,
    );
  }
}
