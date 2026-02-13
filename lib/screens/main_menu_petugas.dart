import 'package:flutter/material.dart';
import 'dashboard_petugas_page.dart'; // Beranda dashboard
import 'petugas_pengaturan_page.dart'; // Akun / Pengaturan
import 'petugas_peminjaman_page.dart';
import 'pengembalian_screen.dart';
import 'petugas_pesan_page.dart';

class MainMenuPetugas extends StatefulWidget {
  const MainMenuPetugas({super.key});

  @override
  State<MainMenuPetugas> createState() => _MainMenuPetugasState();
}

class _MainMenuPetugasState extends State<MainMenuPetugas> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardPetugasPage(),
    PetugasRiwayatPage(),
    PetugasPesanPage(),
    PetugasPengaturanPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Pesan'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Akun'),
        ],
      ),
    );
  }
}

// =====================
// HALAMAN TRANSAKSI PETUGAS
// =====================
class PetugasRiwayatPage extends StatelessWidget {
  const PetugasRiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        title: const Text('Transaksi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _menuCard(
              context,
              title: 'Peminjaman',
              subtitle: 'Setujui / tolak permintaan peminjaman',
              icon: Icons.assignment_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PetugasPeminjamanPage()),
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
            const SizedBox(height: 20),
            const Text(
              'Riwayat transaksi nanti bisa kamu tampilkan di halaman ini juga.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
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
