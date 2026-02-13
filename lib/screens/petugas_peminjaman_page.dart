import 'package:flutter/material.dart';

import '../services/dashboard_petugas_service.dart';

class PetugasPeminjamanPage extends StatefulWidget {
  const PetugasPeminjamanPage({super.key});

  @override
  State<PetugasPeminjamanPage> createState() => _PetugasPeminjamanPageState();
}

class _PetugasPeminjamanPageState extends State<PetugasPeminjamanPage> {
  final _service = DashboardPetugasService();
  final Set<int> _processingIds = <int>{};

  Future<List<Map<String, dynamic>>> _load() => _service.listMenunggu();

  Future<void> _proses({
    required int idPeminjaman,
    required bool setuju,
  }) async {
    setState(() => _processingIds.add(idPeminjaman));
    try {
      if (setuju) {
        await _service.setujui(idPeminjaman);
      } else {
        await _service.tolak(idPeminjaman);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            setuju
                ? 'Permintaan #$idPeminjaman disetujui'
                : 'Permintaan #$idPeminjaman ditolak',
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses #$idPeminjaman: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(idPeminjaman));
      }
    }
  }

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
        title: const Text('Persetujuan Peminjaman'),
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

          final list = snapshot.data!;
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Tidak ada permintaan menunggu.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final row = list[i];
                final id = (row['id_peminjaman'] as num).toInt();
                final peminjam = (row['peminjam'] is Map)
                    ? (row['peminjam']['nama_peminjam']?.toString() ?? '-')
                    : '-';
                final tPinjam = _fmt(row['tanggal_pinjam']);
                final tKembali = _fmt(row['tanggal_kembali_rencana']);
                final processing = _processingIds.contains(id);

                final details = (row['peminjaman_detail'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    const <Map<String, dynamic>>[];
                final itemPreview = details.take(3).map((d) {
                  final alat = (d['alat'] is Map)
                      ? (d['alat']['nama_alat']?.toString() ?? 'Alat')
                      : 'Alat';
                  final qty = (d['qty'] ?? 1).toString();
                  return '$alat x$qty';
                }).join(', ');
                final sisa = details.length > 3 ? ' +${details.length - 3} item' : '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaksi #$id',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Peminjam: $peminjam'),
                        Text('Pinjam: $tPinjam'),
                        Text('Rencana kembali: $tKembali'),
                        const SizedBox(height: 8),
                        Text(
                          details.isEmpty ? 'Item: -' : 'Item: $itemPreview$sisa',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: processing
                                    ? null
                                    : () => _proses(
                                          idPeminjaman: id,
                                          setuju: false,
                                        ),
                                icon: const Icon(Icons.close),
                                label: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: processing
                                    ? null
                                    : () => _proses(
                                          idPeminjaman: id,
                                          setuju: true,
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff2C3E75),
                                  foregroundColor: Colors.white,
                                ),
                                icon: processing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: Text(processing ? 'Proses...' : 'Setujui'),
                              ),
                            ),
                          ],
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
