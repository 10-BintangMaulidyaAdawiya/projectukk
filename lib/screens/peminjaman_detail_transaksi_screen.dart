import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class PeminjamanDetailTransaksiScreen extends StatefulWidget {
  final int idPeminjaman;
  const PeminjamanDetailTransaksiScreen({
    super.key,
    required this.idPeminjaman,
  });

  @override
  State<PeminjamanDetailTransaksiScreen> createState() =>
      _PeminjamanDetailTransaksiScreenState();
}

class _PeminjamanDetailTransaksiScreenState
    extends State<PeminjamanDetailTransaksiScreen> {
  final _svc = SupabaseService();

  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.getDetailPeminjaman(widget.idPeminjaman);
      if (!mounted) return;
      setState(() => _items = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal load detail: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),

        // ✅ paksa teks + icon jadi putih
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),

        title: Text('Detail #${widget.idPeminjaman}'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Tidak ada item di transaksi ini.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final it = _items[i];

                    final alat = it['alat'] as Map<String, dynamic>?;
                    final nama = (alat?['nama_alat'] ?? 'Alat').toString();

                    final statusItem = (it['status_item'] ?? '-').toString();
                    final qty = (it['qty'] ?? 1).toString();
                    final idAlat = (it['id_alat'] ?? '-').toString();

                    return Card(
                      child: ListTile(
                        title: Text(nama),
                        subtitle: Text(
                          'ID alat: $idAlat • qty: $qty • status_item: $statusItem',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
