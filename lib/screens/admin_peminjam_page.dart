import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class AdminPeminjamPage extends StatefulWidget {
  const AdminPeminjamPage({super.key});

  @override
  State<AdminPeminjamPage> createState() => _AdminPeminjamPageState();
}

class _AdminPeminjamPageState extends State<AdminPeminjamPage> {
  final _svc = SupabaseService();

  Future<List<Map<String, dynamic>>> _load() => _svc.adminListPeminjamRingkas();

  String _fmt(dynamic v) {
    if (v == null) return '-';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        foregroundColor: Colors.white,
        title: const Text('Data Peminjam'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('Belum ada data peminjam.'));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final r = rows[i];
                final nama = (r['nama_peminjam'] ?? '-').toString();
                final kelas = (r['kelas'] ?? '-').toString();
                final jurusan = (r['jurusan'] ?? '-').toString();
                final lastId = r['last_peminjaman_id'];
                final lastTgl = _fmt(r['last_tanggal_pinjam']);
                final items = (r['last_items'] as List?)?.cast<String>() ?? const <String>[];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Kelas: $kelas | Jurusan: $jurusan'),
                        const SizedBox(height: 10),
                        if (lastId == null)
                          const Text('Belum pernah meminjam.')
                        else ...[
                          Text('Pinjaman terakhir: #$lastId ($lastTgl)'),
                          const SizedBox(height: 4),
                          Text(
                            items.isEmpty
                                ? 'Barang dipinjam: -'
                                : 'Barang dipinjam: ${items.join(', ')}',
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
