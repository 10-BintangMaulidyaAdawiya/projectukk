import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'peminjaman_detail_transaksi_screen.dart';

class PeminjamanRiwayatScreen extends StatefulWidget {
  const PeminjamanRiwayatScreen({super.key});

  @override
  State<PeminjamanRiwayatScreen> createState() => _PeminjamanRiwayatScreenState();
}

class _PeminjamanRiwayatScreenState extends State<PeminjamanRiwayatScreen> {
  final _svc = SupabaseService();
  bool _loading = true;
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.getRiwayatPeminjamanSaya();
      if (!mounted) return;
      setState(() => _list = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal load riwayat: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(dynamic d) => (d ?? '').toString(); // date dari supabase biasanya string

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        title: const Text('Riwayat Peminjaman'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('Belum ada transaksi peminjaman.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = _list[i];
                    final id = p['id_peminjaman'] as int;
                    final status = (p['status'] ?? '').toString();

                    return Card(
                      child: ListTile(
                        title: Text('Transaksi #$id'),
                        subtitle: Text(
                          'Pinjam: ${_fmt(p['tanggal_pinjam'])}\n'
                          'Kembali: ${_fmt(p['tanggal_kembali_rencana'])}\n'
                          'Status: $status',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PeminjamanDetailTransaksiScreen(
                                idPeminjaman: id,
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
