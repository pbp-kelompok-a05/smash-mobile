import 'package:flutter/material.dart';
import 'package:smash_mobile/widgets/left_drawer.dart';

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  // Menambahkan class ItemHomePage yang berisi tombol-tombol tertentu
  // Implementasi tombol-tombol yang sudah dibuat tadi
  final List<ItemHomepage> items = [
    ItemHomepage("All Products", Icons.list, Colors.blue),
    ItemHomepage("My Products", Icons.shopping_bag, Colors.green),
    ItemHomepage("Create Product", Icons.add_circle, Colors.red),
    ItemHomepage("Logout", Icons.logout, Colors.red),
  ];

  void _handleMenuTap(BuildContext context, ItemHomepage item) {
    var message = '${item.name} is coming soon';
    if (item.name == 'Logout') {
      message = 'Logout placeholder';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Mengintegrasikan infocard dan itemcard untuk ditampilkan di MyHomePage
  @override
  Widget build(BuildContext context) {
    // Scaffold menyediakan struktur dasar halaman dengan AppBar dan body.
    return Scaffold(
      drawer: const LeftDrawer(),
      backgroundColor: Colors.grey[900],
      // AppBar adalah bagian atas halaman yang menampilkan judul.
      appBar: AppBar(
        // Judul aplikasi "Smash" dengan teks putih dan tebal.
        title: const Text(
          'Smash 🎾',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // Warna latar belakang AppBar diambil dari skema warna tema aplikasi.
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      // Body halaman dengan padding di sekelilingnya.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        // Menyusun widget secara vertikal dalam sebuah kolom.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Row untuk menampilkan 3 InfoCard secara horizontal.
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: const [
                InfoCard(
                  title: 'Latest Posts',
                  content: 'Catch up with the newest discussions.',
                ),
                InfoCard(
                  title: 'Your Hub',
                  content: 'Access your padel profile quickly.',
                ),
                InfoCard(
                  title: 'Create',
                  content: 'Share a new post with the community.',
                ),
              ],
            ),

            // Memberikan jarak vertikal 16 unit.
            const SizedBox(height: 16.0),

            // Menempatkan widget berikutnya di tengah halaman.
            Center(
              child: Column(
                // Menyusun teks dan grid item secara vertikal.
                children: [
                  // Menampilkan teks sambutan dengan gaya tebal dan ukuran 18.
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: const [
                        Text(
                          'WELCOME TO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            letterSpacing: 2.0,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "🏆Smash🏆",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24.0,
                            color: Colors.amber,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Your Ultimate Football Store",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 14.0,
                            color: Colors.grey,
                          ),
                        )
                      ],
                    ),
                  ),

                  // Grid untuk menampilkan ItemCard dalam bentuk grid 3 kolom.
                  GridView.count(
                    primary: true,
                    padding: const EdgeInsets.all(20),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 3,
                    // Agar grid menyesuaikan tinggi kontennya.
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: items
                        .map(
                          (item) => ItemCard(
                            item: item,
                            onTap: () => _handleMenuTap(context, item),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const InfoCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 3.5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Text(content, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemHomepage {
  final String name;
  final IconData icon;
  final Color color;

  ItemHomepage(this.name, this.icon, this.color);
}

class ItemCard extends StatelessWidget {
  final ItemHomepage item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
