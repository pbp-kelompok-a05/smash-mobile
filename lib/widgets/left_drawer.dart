import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/screens/login.dart';
import 'package:smash_mobile/notifications/notifications_page.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Smash Mobile',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Forum Padel no.1 di Indonesia",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // TODO: Bagian routing
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            // Bagian routing ke halaman MyHomePage
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage()),
              );
            },
          ),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            // Bagian routing ke halaman ProfilePage
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsPage(),
                ),
              );
            },
          ),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              final request = context.read<CookieRequest>();
              try {
                await request.logout('http://localhost:8000/authentication/logout/');
              } catch (_) {}
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SmashLoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
