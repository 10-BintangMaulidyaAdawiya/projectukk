import 'package:flutter/material.dart';
import '../services/dashboard_petugas_service.dart';
import 'petugas_peminjaman_page.dart';

class DashboardPetugasPage extends StatefulWidget {
  const DashboardPetugasPage({super.key});

  @override
  State<DashboardPetugasPage> createState() => _DashboardPetugasPageState();
}

class _DashboardPetugasPageState extends State<DashboardPetugasPage> {
  final service = DashboardPetugasService();

  Future<Map<String, int>> loadCounts() async {
    final menunggu = await service.countByStatus('menunggu');
    final dipinjam = await service.countByStatus('disetujui');
    final selesai = await service.countByStatus('selesai');
    final terlambat = await service.countTerlambat(); // opsional tapi bagus

    return {
      'menunggu': menunggu,
      'dipinjam': dipinjam,
      'selesai': selesai,
      'terlambat': terlambat,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Petugas')),
      body: FutureBuilder<Map<String, int>>(
        future: loadCounts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final c = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _DashCard(
                  title: 'Menunggu Persetujuan',
                  value: c['menunggu']!,
                  subtitle: 'Klik untuk lihat daftar',
                  icon: Icons.assignment_late_outlined,
                  onTap: () {
                    // Ini menuju halaman peminjaman menunggu (yang sudah kita buat)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PetugasPeminjamanPage()),
                    );
                  },
                ),
                _DashCard(
                  title: 'Sedang Dipinjam',
                  value: c['dipinjam']!,
                  subtitle: 'Yang sudah disetujui, belum selesai',
                  icon: Icons.inventory_2_outlined,
                  onTap: () {
                    // nanti kita buat halaman "Pengembalian" list status disetujui
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nanti arahkan ke halaman Pengembalian')),
                    );
                  },
                ),
                _DashCard(
                  title: 'Terlambat',
                  value: c['terlambat']!,
                  subtitle: 'Status disetujui & lewat rencana kembali',
                  icon: Icons.warning_amber_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nanti arahkan ke list terlambat')),
                    );
                  },
                ),
                _DashCard(
                  title: 'Selesai',
                  value: c['selesai']!,
                  subtitle: 'Transaksi sudah dikembalikan',
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nanti arahkan ke riwayat/laporan')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(
          value.toString(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}
