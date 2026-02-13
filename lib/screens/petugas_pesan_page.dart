import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class PetugasPesanPage extends StatefulWidget {
  const PetugasPesanPage({super.key});

  @override
  State<PetugasPesanPage> createState() => _PetugasPesanPageState();
}

class _PetugasPesanPageState extends State<PetugasPesanPage> {
  final _svc = SupabaseService();

  Future<List<Map<String, dynamic>>> _load() => _svc.petugasGetPesanMasuk();

  String _fmt(dynamic v) {
    if (v == null) return '-';
    final s = v.toString();
    if (s.length >= 16) return s.substring(0, 16).replaceFirst('T', ' ');
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        foregroundColor: Colors.white,
        title: const Text('Pesan Admin'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat pesan.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Belum ada pesan dari admin.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final r = rows[i];
                final isi = (r['isi_pesan'] ?? '').toString();
                final createdAt = _fmt(r['created_at']);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pesan dari Admin',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(isi.isEmpty ? '-' : isi),
                        const SizedBox(height: 8),
                        Text(
                          createdAt,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
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
