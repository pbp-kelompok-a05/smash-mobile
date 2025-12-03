import 'package:flutter/material.dart';
import 'widgets/navbar.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const NavBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F6F6), Color(0xFFFFF3F4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const CircleAvatar(
                  radius: 46,
                  backgroundImage: AssetImage('assets/avatar.png'),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Abby',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hello World! Certified\npadel trainer here',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _chip('My Posts', selected: true),
                const SizedBox(width: 8),
                _chip('Bookmark'),
                const SizedBox(width: 8),
                _chip('Liked'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'My Posts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => const _PostCard()),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {},
                child: const Text(
                  'See More',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2D8CF0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Colors.transparent : Colors.grey.shade300,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF2D8CF0).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey.shade600,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/avatar.png'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Hello World!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'by Abby · 1 hour ago',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation... See More',
            style: TextStyle(fontSize: 13.5, color: Colors.black87, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _iconStat(Icons.thumb_up_alt_outlined, '10'),
              const SizedBox(width: 14),
              _iconStat(Icons.comment_outlined, '10'),
              const SizedBox(width: 14),
              _iconStat(Icons.bookmark_border, '10'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}
