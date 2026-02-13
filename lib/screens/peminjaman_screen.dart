import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class PeminjamanScreen extends StatefulWidget {
  const PeminjamanScreen({super.key});

  @override
  State<PeminjamanScreen> createState() => _PeminjamanScreenState();
}

class _PeminjamanScreenState extends State<PeminjamanScreen> {
  final _svc = SupabaseService();

  bool _loading = true;
  bool _saving = false;

  // data alat tersedia dari DB
  List<Map<String, dynamic>> _alatTersedia = [];
  // alat yang dipilih (id_alat)
  final Set<int> _selectedAlatIds = {};

  // data peminjam (siswa) dari DB
  List<Map<String, dynamic>> _peminjamList = [];
  int? _selectedPeminjamId; // ✅ ini yang dipakai validasi

  // tanggal kembali
  DateTime _tglKembaliRencana = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      // load peminjam + alat sekaligus
      final peminjam = await _svc.getPeminjamList();
      final alat = await _svc.getAlatTersedia();

      setState(() {
        _peminjamList = peminjam;
        _alatTersedia = alat;

        _selectedAlatIds.clear();
        // jangan reset peminjam kalau sudah pernah dipilih
        _selectedPeminjamId = _selectedPeminjamId;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memuat data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAlat() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.getAlatTersedia();
      if (!mounted) return;
      setState(() {
        _alatTersedia = data;
        _selectedAlatIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memuat alat: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickTanggalKembali() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tglKembaliRencana,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _tglKembaliRencana = picked);
    }
  }

  Future<void> _submitPeminjaman() async {
    // ✅ validasi peminjam harus dipilih
    if (_selectedPeminjamId == null) {
      _showSnack('Pilih peminjam dulu');
      return;
    }

    if (_selectedAlatIds.isEmpty) {
      _showSnack('Pilih minimal 1 alat');
      return;
    }

    setState(() => _saving = true);
    try {
      final idPeminjaman = await _svc.createPeminjamanMultiItem(
        peminjamId: _selectedPeminjamId!,
        tanggalKembaliRencana: _tglKembaliRencana,
        alatIds: _selectedAlatIds.toList(),
      );

      if (!mounted) return;

      _showSnack(
        'Berhasil! id_peminjaman = $idPeminjaman (menunggu persetujuan petugas)',
      );

      // refresh alat & reset pilihan item
      await _loadAlat();
      setState(() {
        _selectedAlatIds.clear();
        // peminjam tetap dipertahankan (biar enak input berulang)
        // kalau mau reset peminjam juga, uncomment baris ini:
        // _selectedPeminjamId = null;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal simpan peminjaman: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleSelect(int idAlat, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedAlatIds.add(idAlat);
      } else {
        _selectedAlatIds.remove(idAlat);
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedAlatIds.length;

    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),

        // ✅ paksa teks + icon jadi putih semua
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),

        title: const Text('Peminjaman'),
        toolbarHeight: 70,

        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAll,
            tooltip: 'Refresh',
            iconSize: 30,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            icon: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
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
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // FORM PEMINJAMAN
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ✅ DROPDOWN PEMINJAM (bukan TextField)
                          DropdownButtonFormField<int>(
                            initialValue: _selectedPeminjamId,
                            decoration: const InputDecoration(
                              labelText: 'Peminjam (data siswa)',
                              border: OutlineInputBorder(),
                            ),
                            items: _peminjamList.map((p) {
                              final int id = p['peminjam_id'] as int;
                              final String nama =
                                  (p['nama_peminjam'] ?? 'Peminjam $id')
                                      .toString();
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text('$nama (ID: $id)'),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() => _selectedPeminjamId = v);
                            },
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tanggal kembali rencana: ${_fmtDate(_tglKembaliRencana)}',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _pickTanggalKembali,
                                icon: const Icon(Icons.date_range),
                                label: const Text('Pilih'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          ElevatedButton.icon(
                            onPressed: _saving ? null : _submitPeminjaman,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              _saving
                                  ? 'Menyimpan...'
                                  : 'Simpan Peminjaman ($selectedCount item)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // LIST ALAT TERSEDIA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alat Tersedia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Dipilih: $selectedCount'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_alatTersedia.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: Text('Tidak ada alat yang tersedia.')),
                    )
                  else
                    ..._alatTersedia.map((a) {
                      final int idAlat = a['id_alat'] as int;
                      final String nama =
                          (a['nama_alat'] ?? '').toString().trim();
                      final String status =
                          (a['status'] ?? '').toString().trim();

                      final checked = _selectedAlatIds.contains(idAlat);

                      return Card(
                        child: CheckboxListTile(
                          value: checked,
                          onChanged: (v) => _toggleSelect(idAlat, v),
                          title: Text(nama.isEmpty ? 'Alat $idAlat' : nama),
                          subtitle: Text('ID: $idAlat • Status: $status'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}


