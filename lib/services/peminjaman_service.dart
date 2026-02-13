import 'package:supabase_flutter/supabase_flutter.dart';

class PeminjamanService {
  final SupabaseClient _db = Supabase.instance.client;

  bool _isMissingStokColumnError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('stok') &&
        (msg.contains('column') ||
            msg.contains('schema cache') ||
            msg.contains('pgrst'));
  }

  // =========================
  // UNTUK PEMINJAM: BUAT PERMINTAAN (MENUNGGU)
  // =========================
  //
  // items: list alat yang dipinjam
  // contoh items:
  // [
  //   {'id_alat': 1, 'qty': 2},
  //   {'id_alat': 3, 'qty': 1},
  // ]
  //
  Future<int> buatPermintaan({
    required int peminjamId,
    required String tanggalPinjam, // format yyyy-mm-dd
    required String tanggalKembaliRencana, // format yyyy-mm-dd
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Item peminjaman tidak boleh kosong.');
    }

    // 1) insert header peminjaman dengan status MENUNGGU
    final header = await _db
        .from('peminjaman')
        .insert({
          'peminjam_id': peminjamId,
          'tanggal_pinjam': tanggalPinjam,
          'tanggal_kembali_rencana': tanggalKembaliRencana,
          'status': 'menunggu',
        })
        .select('id_peminjaman')
        .single();

    final int idPeminjaman = header['id_peminjaman'] as int;

    // 2) insert detail (status_item MENUNGGU)
    final detailRows = items.map((it) {
      return {
        'id_peminjaman': idPeminjaman,
        'id_alat': it['id_alat'],
        'qty': it['qty'],
        'status_item': 'menunggu',
      };
    }).toList();

    await _db.from('peminjaman_detail').insert(detailRows);

    // PENTING: jangan update alat jadi "dipinjam" di sini
    // alat baru berubah saat PETUGAS menyetujui

    return idPeminjaman;
  }

  // =========================
  // UNTUK PETUGAS: STREAM MENUNGGU (kalau kamu masih mau pakai stream)
  // =========================
  Stream<List<Map<String, dynamic>>> streamMenunggu() {
    return _db
        .from('peminjaman')
        .stream(primaryKey: ['id_peminjaman'])
        .select() // aman untuk stream
        .eq('status', 'menunggu')
        .order('id_peminjaman', ascending: false);
  }

  // =========================
  // HEADER & DETAIL (dipakai di halaman detail petugas/peminjam)
  // =========================
  Future<Map<String, dynamic>> getHeader(int idPeminjaman) async {
    final data = await _db
        .from('peminjaman')
        .select('id_peminjaman, status, tanggal_pinjam, tanggal_kembali_rencana, peminjam(nama_peminjam)')
        .eq('id_peminjaman', idPeminjaman)
        .single();

    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> getDetailItems(int idPeminjaman) async {
    try {
      final data = await _db
          .from('peminjaman_detail')
          .select('id_detail, id_alat, qty, status_item, alat(nama_alat, stok, status)')
          .eq('id_peminjaman', idPeminjaman)
          .order('id_detail', ascending: true);

      final rows =
          (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      for (final row in rows) {
        final alat = Map<String, dynamic>.from(row['alat'] as Map? ?? {});
        alat['stok'] = (alat['stok'] as num?)?.toInt() ?? 1;
        row['alat'] = alat;
      }
      return rows;
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;

      final data = await _db
          .from('peminjaman_detail')
          .select('id_detail, id_alat, qty, status_item, alat(nama_alat, status)')
          .eq('id_peminjaman', idPeminjaman)
          .order('id_detail', ascending: true);

      final rows =
          (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      for (final row in rows) {
        final alat = Map<String, dynamic>.from(row['alat'] as Map? ?? {});
        alat['stok'] = 1;
        row['alat'] = alat;
      }
      return rows;
    }
  }

  // =========================
  // UNTUK PETUGAS: APPROVE (SETUJUI)
  // =========================
  Future<void> approve(int idPeminjaman) async {
    try {
      final details = await _db
          .from('peminjaman_detail')
          .select('id_alat, qty, alat:id_alat(nama_alat, stok, status)')
          .eq('id_peminjaman', idPeminjaman);

      for (final row in (details as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final idAlat = (map['id_alat'] as num).toInt();
        final qty = (map['qty'] as num?)?.toInt() ?? 0;
        final alat = Map<String, dynamic>.from(map['alat'] as Map? ?? {});
        final namaAlat = (alat['nama_alat'] ?? 'ID $idAlat').toString();
        final stok = (alat['stok'] as num?)?.toInt() ?? 0;

        if (qty <= 0) {
          throw Exception('Qty tidak valid pada alat $namaAlat');
        }
        if (stok < qty) {
          throw Exception(
            'Stok $namaAlat tidak cukup. Tersedia: $stok, diminta: $qty',
          );
        }

        final stokBaru = stok - qty;
        final statusAlatBaru = stokBaru > 0 ? 'Tersedia' : 'Dipinjam';
        await _db
            .from('alat')
            .update({'stok': stokBaru, 'status': statusAlatBaru})
            .eq('id_alat', idAlat);
      }
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;
      // fallback schema lama tanpa kolom stok: hanya ubah status alat
      final details = await _db
          .from('peminjaman_detail')
          .select('id_alat')
          .eq('id_peminjaman', idPeminjaman);

      for (final row in (details as List)) {
        final idAlat = (row['id_alat'] as num).toInt();
        await _db.from('alat').update({'status': 'Dipinjam'}).eq('id_alat', idAlat);
      }
    }

    // 1) header disetujui
    await _db
        .from('peminjaman')
        .update({'status': 'disetujui'})
        .eq('id_peminjaman', idPeminjaman);

    // 2) detail jadi dipinjam
    await _db
        .from('peminjaman_detail')
        .update({'status_item': 'dipinjam'})
        .eq('id_peminjaman', idPeminjaman);
  }

  // =========================
  // UNTUK PETUGAS: TOLAK
  // =========================
  Future<void> reject(int idPeminjaman) async {
    await _db
        .from('peminjaman')
        .update({'status': 'ditolak'})
        .eq('id_peminjaman', idPeminjaman);

    await _db
        .from('peminjaman_detail')
        .update({'status_item': 'ditolak'})
        .eq('id_peminjaman', idPeminjaman);
  }
}

extension on SupabaseStreamFilterBuilder {
  SupabaseStreamFilterBuilder select() => this;
}
