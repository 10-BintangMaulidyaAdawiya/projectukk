import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final _svc = SupabaseService();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.adminListKategori();
      if (!mounted) return;
      setState(() => _list = data);
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal load kategori: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _dialogTambah() async {
    final namaCtrl = TextEditingController();
    final ketCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama kategori',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ketCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );

    if (ok != true) return;

    final nama = namaCtrl.text.trim();
    if (nama.isEmpty) {
      _snack('Nama kategori wajib diisi');
      return;
    }

    setState(() => _saving = true);
    try {
      await _svc.adminCreateKategori(
        namaKategori: nama,
        keterangan: ketCtrl.text.trim(),
      );
      if (!mounted) return;
      _snack('Kategori ditambah');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal tambah: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _dialogEdit(Map<String, dynamic> row) async {
    final id = (row['id_kategori'] as num).toInt();
    final namaCtrl = TextEditingController(text: (row['nama_kategori'] ?? '').toString());
    final ketCtrl = TextEditingController(text: (row['keterangan'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Kategori #$id'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama kategori',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ketCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );

    if (ok != true) return;

    final nama = namaCtrl.text.trim();
    if (nama.isEmpty) {
      _snack('Nama kategori wajib diisi');
      return;
    }

    setState(() => _saving = true);
    try {
      await _svc.adminUpdateKategori(
        idKategori: id,
        namaKategori: nama,
        keterangan: ketCtrl.text.trim(),
      );
      if (!mounted) return;
      _snack('Kategori diupdate');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal update: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _hapus(Map<String, dynamic> row) async {
    final id = (row['id_kategori'] as num).toInt();
    final nama = (row['nama_kategori'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin hapus "$nama" (#$id)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await _svc.adminDeleteKategori(id);
      if (!mounted) return;
      _snack('Kategori dihapus');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal hapus: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        foregroundColor: Colors.white,
        title: const Text('Admin • Kategori'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _saving ? null : _dialogTambah,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Tambah',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('Belum ada kategori.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final row = _list[i];
                    final id = (row['id_kategori'] as num).toInt();
                    final nama = (row['nama_kategori'] ?? '').toString();
                    final ket = (row['keterangan'] ?? '').toString();

                    return Card(
                      child: ListTile(
                        title: Text(nama),
                        subtitle: Text('ID: $id${ket.trim().isEmpty ? "" : " • $ket"}'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: _saving ? null : () => _dialogEdit(row),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _saving ? null : () => _hapus(row),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
