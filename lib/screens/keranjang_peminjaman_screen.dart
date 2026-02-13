import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/supabase_service.dart';

class KeranjangPeminjamanScreen extends StatefulWidget {
  const KeranjangPeminjamanScreen({super.key});

  @override
  State<KeranjangPeminjamanScreen> createState() =>
      _KeranjangPeminjamanScreenState();
}

class _KeranjangPeminjamanScreenState extends State<KeranjangPeminjamanScreen> {
  final _svc = SupabaseService();

  bool _loading = true;
  bool _submitting = false;

  List<Map<String, dynamic>> _peminjamList = [];
  int? _selectedPeminjamId;
  DateTime _tglKembali = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    _loadPeminjam();
  }

  Future<void> _loadPeminjam() async {
    setState(() => _loading = true);
    try {
      final list = await _svc.getPeminjamList();
      if (!mounted) return;
      setState(() {
        _peminjamList = list;
        if (_selectedPeminjamId == null && list.isNotEmpty) {
          _selectedPeminjamId = list.first['peminjam_id'] as int;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat peminjam: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tglKembali,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _tglKembali = picked);
    }
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kosong')),
      );
      return;
    }
    if (_selectedPeminjamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih peminjam dulu')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final items = cart.items
          .map((e) => {'id_alat': e.idAlat, 'qty': e.qty})
          .toList();

      final idPeminjaman = await _svc.createPeminjamanWithItems(
        peminjamId: _selectedPeminjamId!,
        tanggalKembaliRencana: _tglKembali,
        items: items,
      );

      cart.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil! id_peminjaman = $idPeminjaman (menunggu persetujuan petugas)',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final canSubmit = !_submitting &&
        !_loading &&
        _selectedPeminjamId != null &&
        cart.items.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        foregroundColor: Colors.white,
        title: const Text('Detail Peminjaman (Keranjang)'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPeminjam,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedPeminjamId,
                      decoration: const InputDecoration(
                        labelText: 'Peminjam (data siswa)',
                        border: OutlineInputBorder(),
                      ),
                      items: _peminjamList.map((p) {
                        final id = p['peminjam_id'] as int;
                        final nama = (p['nama_peminjam'] ?? '').toString();
                        final kelas = (p['kelas'] ?? '').toString();
                        final jurusan = (p['jurusan'] ?? '').toString();
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('$nama | $kelas | $jurusan'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedPeminjamId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Tanggal kembali (rencana)'),
                    subtitle:
                        Text(_tglKembali.toIso8601String().substring(0, 10)),
                    trailing: const Icon(Icons.date_range),
                    onTap: _pickTanggal,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Barang dipinjam',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (cart.items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Keranjang kosong'),
                    ),
                  )
                else
                  ...cart.items.map((it) {
                    return Card(
                      child: ListTile(
                        title: Text(it.namaAlat),
                        subtitle:
                            Text('ID: ${it.idAlat} | qty: ${it.qty} | stok: ${it.stok}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => cart.removeItem(it.idAlat),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2C3E75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Konfirmasi Peminjaman'),
                  ),
                ),
              ],
            ),
    );
  }
}
