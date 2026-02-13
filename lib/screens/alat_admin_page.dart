import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class AlatAdminPage extends StatefulWidget {
  const AlatAdminPage({super.key});

  @override
  State<AlatAdminPage> createState() => _AlatAdminPageState();
}

class _AlatAdminPageState extends State<AlatAdminPage> {
  final _svc = SupabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _alat = [];
  List<Map<String, dynamic>> _kategori = [];

  int? _filterKategori;
  String? _filterStatus;

  static const _statusList = ['Tersedia', 'Dipinjam', 'Rusak'];
  static const String _bucketAlat = 'alat-images';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final kat = await _svc.getKategori();
      final data = await _svc.adminListAlat(
        idKategori: _filterKategori,
        status: _filterStatus,
      );

      if (!mounted) return;
      setState(() {
        _kategori = kat;
        _alat = data;
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal load: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  List<Map<String, dynamic>> get _filteredLocal {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _alat.where((row) {
      final nama = (row['nama_alat'] ?? '').toString().toLowerCase();
      final spek = (row['spesifikasi'] ?? '').toString().toLowerCase();
      return q.isEmpty || nama.contains(q) || spek.contains(q);
    }).toList();
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'tersedia') return Colors.green;
    if (s == 'dipinjam') return Colors.redAccent;
    return Colors.orange;
  }

  Future<String> _uploadFotoAlat({
    required Uint8List bytes,
    required String ext,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 100000).toString().padLeft(5, '0');
    final fileName = 'alat_${ts}_$rand.$ext';
    final filePath = 'alat/$fileName';

    await _supabase.storage.from(_bucketAlat).uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
          ),
        );

    return _supabase.storage.from(_bucketAlat).getPublicUrl(filePath);
  }

  bool _isBucketNotFoundError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('bucket not found') || msg.contains('statuscode: 404');
  }

  Future<String?> _tryUploadFotoAlat({
    required Uint8List bytes,
    required String ext,
  }) async {
    try {
      return await _uploadFotoAlat(bytes: bytes, ext: ext);
    } catch (e) {
      if (_isBucketNotFoundError(e)) {
        _snack(
          'Upload foto gagal: bucket "$_bucketAlat" belum dibuat. Data tetap disimpan tanpa foto.',
        );
        return null;
      }
      rethrow;
    }
  }

  Future<void> _dialogTambah() async {
    await _openFormSheet();
  }

  Future<void> _dialogEdit(Map<String, dynamic> row) async {
    await _openFormSheet(editRow: row);
  }

  Future<void> _openFormSheet({Map<String, dynamic>? editRow}) async {
    if (_kategori.isEmpty) {
      _snack('Kategori masih kosong. Buat kategori dulu ya.');
      return;
    }

    final isEdit = editRow != null;
    final idAlat = isEdit ? _asInt(editRow['id_alat']) : null;
    final namaCtrl =
        TextEditingController(text: isEdit ? (editRow['nama_alat'] ?? '').toString() : '');
    final spekCtrl =
        TextEditingController(text: isEdit ? (editRow['spesifikasi'] ?? '').toString() : '');
    final stokCtrl = TextEditingController(
      text: isEdit ? ((editRow['stok'] ?? 0) as num).toInt().toString() : '1',
    );

    int idKat = isEdit
        ? (_asInt(editRow['id_kategori']) ?? _asInt(_kategori.first['id_kategori'])!)
        : _asInt(_kategori.first['id_kategori'])!;
    String status = isEdit ? (editRow['status'] ?? 'Tersedia').toString() : 'Tersedia';
    String currentFotoUrl = isEdit ? (editRow['foto_url'] ?? '').toString() : '';
    Uint8List? pickedBytes;
    String pickedExt = 'jpg';

    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xffF5F7FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEdit ? 'Edit Alat #$idAlat' : 'Tambah Alat',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xff2C3E75),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (pickedBytes != null)
                          ? Image.memory(pickedBytes!, height: 140, fit: BoxFit.cover)
                          : (currentFotoUrl.isNotEmpty)
                              ? Image.network(currentFotoUrl, height: 140, fit: BoxFit.cover)
                              : Container(
                                  height: 140,
                                  color: const Color(0xffDDE3FF),
                                  child: const Center(
                                    child: Icon(Icons.image, color: Color(0xff2C3E75), size: 40),
                                  ),
                                ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final x = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (x == null) return;
                        final bytes = await x.readAsBytes();
                        final name = x.name.toLowerCase();
                        final ext = name.endsWith('.png') ? 'png' : 'jpg';
                        setLocal(() {
                          pickedBytes = bytes;
                          pickedExt = ext;
                        });
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(isEdit ? 'Ganti Foto' : 'Pilih Foto'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: namaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama alat',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stokCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stok',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: idKat,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: _kategori.map((k) {
                        final id = _asInt(k['id_kategori'])!;
                        final nama = (k['nama_kategori'] ?? '').toString();
                        return DropdownMenuItem(value: id, child: Text(nama));
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => idKat = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusList
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setLocal(() => status = v ?? 'Tersedia'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: spekCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Spesifikasi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final nama = namaCtrl.text.trim();
                                    final stok = int.tryParse(stokCtrl.text.trim()) ?? 0;
                                    if (nama.isEmpty) {
                                      _snack('Nama alat wajib diisi');
                                      return;
                                    }
                                    if (stok < 0) {
                                      _snack('Stok tidak valid');
                                      return;
                                    }

                                    setLocal(() => isSubmitting = true);
                                    if (mounted) setState(() => _saving = true);

                                    try {
                                      if (isEdit) {
                                        await _svc.adminUpdateAlat(
                                          idAlat: idAlat!,
                                          namaAlat: nama,
                                          idKategori: idKat,
                                          spesifikasi: spekCtrl.text.trim(),
                                          status: status,
                                          stok: stok,
                                        );

                                        if (pickedBytes != null) {
                                          final fotoUrl = await _tryUploadFotoAlat(
                                            bytes: pickedBytes!,
                                            ext: pickedExt,
                                          );
                                          if (fotoUrl != null && fotoUrl.isNotEmpty) {
                                            await _supabase
                                                .from('alat')
                                                .update({'foto_url': fotoUrl}).eq('id_alat', idAlat);
                                          }
                                        }
                                        if (!mounted) return;
                                        _snack('Alat diupdate');
                                      } else {
                                        String? fotoUrl;
                                        if (pickedBytes != null) {
                                          fotoUrl = await _tryUploadFotoAlat(
                                            bytes: pickedBytes!,
                                            ext: pickedExt,
                                          );
                                        }

                                        await _svc.adminCreateAlat(
                                          namaAlat: nama,
                                          idKategori: idKat,
                                          spesifikasi: spekCtrl.text.trim(),
                                          status: status,
                                          stok: stok,
                                          fotoUrl: fotoUrl,
                                        );

                                        if (!mounted) return;
                                        _snack('Alat ditambah');
                                      }

                                      await _loadAll();
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                    } catch (e) {
                                      if (!mounted) return;
                                      _snack('Gagal simpan: $e');
                                      if (ctx.mounted) {
                                        setLocal(() => isSubmitting = false);
                                      }
                                    } finally {
                                      if (mounted) setState(() => _saving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2C3E75),
                              foregroundColor: Colors.white,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(isEdit ? 'Update' : 'Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _hapus(Map<String, dynamic> row) async {
    final idAlat = _asInt(row['id_alat'])!;
    final nama = (row['nama_alat'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Alat'),
        content: Text('Yakin hapus "$nama" (#$idAlat)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
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
      await _svc.adminDeleteAlat(idAlat);
      if (!mounted) return;
      _snack('Alat dihapus');
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal hapus: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _thumb(String fotoUrl) {
    if (fotoUrl.isNotEmpty) {
      return Image.network(
        fotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.laptop_mac,
          size: 44,
          color: Color(0xff2C3E75),
        ),
      );
    }
    return const Icon(
      Icons.laptop_mac,
      size: 44,
      color: Color(0xff2C3E75),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredLocal;

    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        foregroundColor: Colors.white,
        title: const Text('Produk Admin'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Cari produk',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xff2C3E75),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _saving ? null : _dialogTambah,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
                        selected: _filterKategori == null,
                        onSelected: (_) async {
                          setState(() => _filterKategori = null);
                          await _loadAll();
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._kategori.map((k) {
                        final id = _asInt(k['id_kategori'])!;
                        final nama = (k['nama_kategori'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(nama),
                            selected: _filterKategori == id,
                            onSelected: (_) async {
                              setState(() => _filterKategori = id);
                              await _loadAll();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 34,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua Status'),
                        selected: _filterStatus == null,
                        onSelected: (_) async {
                          setState(() => _filterStatus = null);
                          await _loadAll();
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._statusList.map((s) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(s),
                            selected: _filterStatus == s,
                            onSelected: (_) async {
                              setState(() => _filterStatus = s);
                              await _loadAll();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('Produk tidak ditemukan'))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.68,
                          ),
                          itemBuilder: (context, i) {
                            final row = items[i];
                            final id = _asInt(row['id_alat']) ?? 0;
                            final nama = (row['nama_alat'] ?? '').toString();
                            final status = (row['status'] ?? '').toString();
                            final stok = ((row['stok'] ?? 0) as num).toInt();
                            final fotoUrl = (row['foto_url'] ?? '').toString();
                            final kategori = row['kategori'] as Map<String, dynamic>?;
                            final namaKat = (kategori?['nama_kategori'] ?? '-').toString();

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                    color: Color(0x22000000),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffEEF1FF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: _thumb(fotoUrl),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    nama,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff2C3E75),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    namaKat,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stok: $stok | $status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(status),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff2C3E75),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          onPressed:
                                              _saving ? null : () => _dialogEdit(row),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 18,
                                          color: Colors.white24,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          onPressed:
                                              _saving ? null : () => _hapus(row),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: $id',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
