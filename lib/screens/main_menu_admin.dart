import 'package:flutter/material.dart';

import 'admin_dashboard_ui.dart';
import 'produk_page.dart';
import 'pengaturan_page.dart';

// Transaksi
import 'peminjaman_screen.dart';
import 'pengembalian_screen.dart';

class MainMenuAdmin extends StatefulWidget {
  const MainMenuAdmin({super.key});

  @override
  State<MainMenuAdmin> createState() => _MainMenuAdminState();
}

class _MainMenuAdminState extends State<MainMenuAdmin> {
  int _index = 0;

  late final List<Widget> _pages = const [
    AdminDashboardUI(),      // NOTE: ini sudah UI tanpa Scaffold (bagus)
    ProdukPage(),            // kalau ProdukPage pakai Scaffold itu OK
    TransaksiPage(),         // ini pakai Scaffold (OK)
    LaporanPage(),           // ini pakai Scaffold (OK)
    PengaturanPage(),        // kalau ini pakai Scaffold juga OK
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xff2C3E75),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: "Produk"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Transaksi"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Laporan"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Pengaturan"),
        ],
      ),
    );
  }
}

// =====================
// TransaksiPage
// =====================
class TransaksiPage extends StatelessWidget {
  const TransaksiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        title: const Text('Transaksi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuCard(
            context,
            title: 'Peminjaman',
            subtitle: 'Buat transaksi peminjaman (multi item)',
            icon: Icons.assignment_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PeminjamanScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _menuCard(
            context,
            title: 'Pengembalian',
            subtitle: 'Kembalikan barang & hitung denda',
            icon: Icons.assignment_turned_in_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PengembalianScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xff2C3E75)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

// =====================
// LaporanPage (placeholder)
// =====================
class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        title: const Text('Laporan'),
      ),
      body: const Center(
        child: Text("Laporan", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
