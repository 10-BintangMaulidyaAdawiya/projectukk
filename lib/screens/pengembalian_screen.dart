import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class PengembalianScreen extends StatefulWidget {
  const PengembalianScreen({super.key});

  @override
  State<PengembalianScreen> createState() => _PengembalianScreenState();
}

class _PengembalianScreenState extends State<PengembalianScreen> {
  final _svc = SupabaseService();
  static const int _dendaPerHari = 5000;

  bool _loading = true;
  bool _submitting = false;

  List<Map<String, dynamic>> _peminjamanAktif = [];
  int? _selectedPeminjamanId;
  List<Map<String, dynamic>> _detailItems = [];
  Set<int> _returnedAlatIds = <int>{};
  final Set<int> _selectedAlatIdsToReturn = {};

  String _kondisi = 'baik';
  int _hariTerlambat = 0;
  int _estimasiDenda = 0;

  @override
  void initState() {
    super.initState();
    _loadPeminjamanAktifMilikSaya();
  }

  Future<void> _loadPeminjamanAktifMilikSaya() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.getPeminjamanAktifSaya(
        statuses: const ['aktif', 'disetujui'],
      );

      if (!mounted) return;
      setState(() {
        _peminjamanAktif = data;
        _selectedPeminjamanId = null;
        _detailItems = [];
        _returnedAlatIds = <int>{};
        _selectedAlatIdsToReturn.clear();
        _hariTerlambat = 0;
        _estimasiDenda = 0;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memuat peminjaman aktif: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDetailItems(int idPeminjaman) async {
    setState(() {
      _selectedPeminjamanId = idPeminjaman;
      _detailItems = [];
      _returnedAlatIds = <int>{};
      _selectedAlatIdsToReturn.clear();
      _loading = true;
    });

    try {
      final results = await Future.wait([
        _svc.getPeminjamanDetail(idPeminjaman),
        _svc.getReturnedAlatIdsByPeminjaman(idPeminjaman),
      ]);
      final data = results[0] as List<Map<String, dynamic>>;
      final returnedIds = results[1] as Set<int>;
      _hitungEstimasiDenda();

      if (!mounted) return;
      setState(() {
        _detailItems = data;
        _returnedAlatIds = returnedIds;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memuat detail peminjaman: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleReturn(int idAlat, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedAlatIdsToReturn.add(idAlat);
      } else {
        _selectedAlatIdsToReturn.remove(idAlat);
      }
    });
  }

  Future<void> _submitPengembalian() async {
    if (_selectedPeminjamanId == null) {
      _showSnack('Pilih transaksi peminjaman dulu');
      return;
    }
    if (_selectedAlatIdsToReturn.isEmpty) {
      _showSnack('Pilih minimal 1 item yang mau dikembalikan');
      return;
    }

    setState(() => _submitting = true);

    try {
      final selectedPeminjaman = _selectedPeminjaman;
      if (selectedPeminjaman == null) {
        throw Exception('Data peminjaman tidak ditemukan');
      }

      final tanggalRencana =
          _parseDate(selectedPeminjaman['tanggal_kembali_rencana']);
      if (tanggalRencana == null) {
        throw Exception('tanggal_kembali_rencana tidak valid');
      }

      final dendaFallback = _svc.hitungDendaKeterlambatan(
        tanggalKembaliRencana: tanggalRencana,
        dendaPerHari: _dendaPerHari,
      );

      final toReturn =
          _selectedAlatIdsToReturn.where((id) => !_returnedAlatIds.contains(id)).toList();
      if (toReturn.isEmpty) {
        throw Exception('Semua item yang dipilih sudah tercatat dikembalikan');
      }

      final idPengembalian = await _svc.createPengembalianHeader(
        idPeminjaman: _selectedPeminjamanId!,
        keterangan: 'pengembalian oleh peminjam',
      );

      for (final idAlat in toReturn) {
        await _svc.returnItem(
          idPengembalian: idPengembalian,
          idAlat: idAlat,
          kondisi: _kondisi,
        );
      }

      final header = await _svc.getPengembalianById(idPengembalian);
      final dendaDb = _asInt(header['denda']) ?? 0;
      var dendaFinal = dendaDb;

      if (dendaFinal <= 0 && dendaFallback > 0) {
        await _svc.updatePengembalianDenda(
          idPengembalian: idPengembalian,
          denda: dendaFallback,
        );
        dendaFinal = dendaFallback;
      }

      if (!mounted) return;
      _showSnack(
        'Berhasil! ID pengembalian: $idPengembalian, denda: Rp$dendaFinal',
      );

      await _loadPeminjamanAktifMilikSaya();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal pengembalian: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Map<String, dynamic>? get _selectedPeminjaman {
    if (_selectedPeminjamanId == null) return null;
    for (final row in _peminjamanAktif) {
      if ((row['id_peminjaman'] as num?)?.toInt() == _selectedPeminjamanId) {
        return row;
      }
    }
    return null;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  void _hitungEstimasiDenda() {
    final p = _selectedPeminjaman;
    final tglRencana = _parseDate(p?['tanggal_kembali_rencana']);
    if (tglRencana == null) {
      _hariTerlambat = 0;
      _estimasiDenda = 0;
      return;
    }

    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final rencanaDate = DateTime(
      tglRencana.year,
      tglRencana.month,
      tglRencana.day,
    );
    final hari = nowDate.difference(rencanaDate).inDays;
    _hariTerlambat = hari > 0 ? hari : 0;
    _estimasiDenda = _hariTerlambat * _dendaPerHari;
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '-';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedAlatIdsToReturn.length;

    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        foregroundColor: Colors.white,
        title: const Text('Pengembalian (Peminjam)'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadPeminjamanAktifMilikSaya,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Peminjaman Aktif Saya',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_peminjamanAktif.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada peminjaman yang aktif.'),
                    ),
                  )
                else
                  Card(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedPeminjamanId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Transaksi (id_peminjaman)',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: _peminjamanAktif.map((p) {
                        final id = p['id_peminjaman'] as int;
                        final peminjam =
                            (p['peminjam']?['nama_peminjam'] ?? '-').toString();
                        final tPinjam = _fmtDate(p['tanggal_pinjam']);
                        final tRencana = _fmtDate(p['tanggal_kembali_rencana']);
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('#$id | $peminjam | $tPinjam -> $tRencana'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        _loadDetailItems(v);
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Kondisi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _kondisi,
                      items: const [
                        DropdownMenuItem(value: 'baik', child: Text('baik')),
                        DropdownMenuItem(value: 'rusak', child: Text('rusak')),
                        DropdownMenuItem(value: 'hilang', child: Text('hilang')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _kondisi = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Checklist item yang dikembalikan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_selectedPeminjamanId == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Pilih transaksi dulu untuk melihat item.'),
                    ),
                  )
                else if (_detailItems.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Tidak ada item pada transaksi ini.'),
                    ),
                  )
                else
                  ..._detailItems.map((d) {
                    final int idAlat = d['id_alat'] as int;
                    final String statusItem =
                        (d['status_item'] ?? '').toString();

                    final alat = d['alat'] as Map<String, dynamic>?;
                    final String namaAlat =
                        (alat?['nama_alat'] ?? 'Alat $idAlat').toString();
                    final String statusAlat =
                        (alat?['status'] ?? '-').toString();

                    final bool alreadyReturned = statusItem.toLowerCase() == 'dikembalikan' ||
                        _returnedAlatIds.contains(idAlat);
                    final bool checked =
                        _selectedAlatIdsToReturn.contains(idAlat);

                    return Card(
                      child: CheckboxListTile(
                        value: checked,
                        onChanged: alreadyReturned
                            ? null
                            : (v) => _toggleReturn(idAlat, v),
                        title: Text(namaAlat),
                        subtitle: Text(
                          'ID: $idAlat | status_item: ${alreadyReturned ? 'dikembalikan' : statusItem} | alat.status: $statusAlat',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    title: const Text('Estimasi denda keterlambatan'),
                    subtitle: Text(
                      '$_hariTerlambat hari x Rp$_dendaPerHari/hari',
                    ),
                    trailing: Text(
                      'Rp$_estimasiDenda',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitPengembalian,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.assignment_turned_in_outlined),
                  label: Text(
                    _submitting
                        ? 'Memproses...'
                        : 'Ajukan Pengembalian ($selectedCount item)',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Catatan: denda dihitung otomatis saat pengembalian. Jika trigger database belum aktif, aplikasi memakai fallback Rp5000/hari keterlambatan.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
    );
  }
}
