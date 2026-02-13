import 'package:flutter/material.dart';
import 'package:ukk/screens/alat_admin_page.dart';
import 'package:ukk/screens/admin_peminjam_page.dart';
import 'package:ukk/screens/admin_petugas_page.dart';
import 'package:ukk/screens/kategori_page.dart';

import 'alat_admin_page.dart';
import 'kategori_page.dart';


class AdminDashboardUI extends StatelessWidget {
  const AdminDashboardUI({super.key});

  // Dummy data (nanti tinggal ganti dari Supabase)
  final String nama = "Admin";
  final String email = "azzam@gmail.com";
  final List<String> labels = const ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"];
  final List<int> values = const [15, 10, 10, 22, 15, 20];

  @override
  Widget build(BuildContext context) {
    // NOTE: tidak pakai Scaffold di sini,
    // karena Scaffold + BottomNavigationBar ada di MainMenu
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            _headerCard(nama: nama, email: email),
            const SizedBox(height: 14),

            // ✅ MENU CEPAT ADMIN (CRUD)
            _quickMenu(context),
            const SizedBox(height: 14),

            _chartCard(labels: labels, values: values),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(child: _MiniStatCard(title: "Jumlah\nPeminjam", value: "12")),
                SizedBox(width: 12),
                Expanded(child: _MiniStatCard(title: "Jumlah\nPetugas Online", value: "3")),
              ],
            ),
            const SizedBox(height: 14),
            _topBorrowCard(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _quickMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Menu Cepat Admin",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff2C3E75),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickMenuCard(
                title: "CRUD Alat",
                subtitle: "Tambah / edit / hapus alat",
                icon: Icons.inventory_2_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlatAdminPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickMenuCard(
                title: "CRUD Kategori",
                subtitle: "Tambah / edit kategori",
                icon: Icons.category_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KategoriPage()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickMenuCard(
                title: "Data Peminjam",
                subtitle: "Nama peminjam + pinjaman terakhir",
                icon: Icons.assignment_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPeminjamPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickMenuCard(
                title: "Data Petugas",
                subtitle: "Profil petugas + kirim pesan",
                icon: Icons.support_agent_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPetugasPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerCard({required String nama, required String email}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff2C3E75),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x22000000),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "Halo $nama",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              const Text("Online", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
            ]),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Color(0xff2C3E75)),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({required List<String> labels, required List<int> values}) {
    final int maxVal = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffDDE3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart, color: Color(0xff2C3E75), size: 18),
              SizedBox(width: 8),
              Text(
                "Jumlah Barang Peminjaman Harian",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff2C3E75)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "( Per Hari Dalam 1 Minggu )",
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff2C3E75)),
          ),
          const SizedBox(height: 10),

          // Chart sederhana (tanpa package)
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final h = (values[i] / maxVal) * 160.0;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        values[i].toString(),
                        style: const TextStyle(fontSize: 10, color: Color(0xff2C3E75)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xff2C3E75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[i],
                        style: const TextStyle(fontSize: 10, color: Color(0xff2C3E75)),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBorrowCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff2C3E75),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x22000000),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text(
                "Peminjaman Paling\nBanyak",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "ROG Strix G16 2.5K\n240Hz 16\"",
                style: TextStyle(color: Colors.white70),
              ),
            ]),
          ),
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.laptop, size: 52, color: Color(0xff2C3E75)),
          ),
        ],
      ),
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 5),
              color: Color(0x22000000),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff2C3E75),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2C3E75),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  const _MiniStatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xff2C3E75),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Color(0x22000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}
