import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:smash_mobile/profile/profile_page.dart';
import 'package:smash_mobile/screens/menu.dart';
import 'package:smash_mobile/screens/login.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            // TODO: Bagian drawer header
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              children: [
                Text(
                  'Smash Mobile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Text(
                  "Forum Padel no.1 di Indonesia",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // TODO: Bagian routing
          ListTile(
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
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              final request = context.read<CookieRequest>();
              request.logout('http://localhost:8000/authentication/logout/');
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
