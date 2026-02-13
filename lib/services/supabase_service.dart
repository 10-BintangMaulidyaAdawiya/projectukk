import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isMissingStokColumnError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('stok') &&
        (msg.contains('column') ||
            msg.contains('schema cache') ||
            msg.contains('pgrst'));
  }

  List<Map<String, dynamic>> _withDefaultStokList(dynamic data) {
    final rows = List<Map<String, dynamic>>.from(data);
    return rows.map((row) {
      final out = Map<String, dynamic>.from(row);
      out['stok'] = (out['stok'] as num?)?.toInt() ?? 1;
      return out;
    }).toList();
  }

  Map<String, dynamic> _withDefaultStokRow(dynamic row) {
    final out = Map<String, dynamic>.from(row);
    out['stok'] = (out['stok'] as num?)?.toInt() ?? 1;
    return out;
  }

  bool _isMissingTableError(Object e, String tableName) {
    final msg = e.toString().toLowerCase();
    return msg.contains(tableName.toLowerCase()) &&
        (msg.contains('does not exist') ||
            msg.contains('relation') ||
            msg.contains('42p01') ||
            msg.contains('pgrst205') ||
            msg.contains('could not find the table'));
  }

  bool _isRlsPolicyError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('42501') ||
        msg.contains('row-level security') ||
        msg.contains('rls') ||
        msg.contains('unauthorized');
  }

  // =========================
  // AUTH
  // =========================
  Future<AuthResponse> login(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // OPTIONAL DEBUG (cek login)
  void debugSession() {
    final user = supabase.auth.currentUser;
    final session = supabase.auth.currentSession;
    debugPrint("DEBUG USER ID: ${user?.id}");
    debugPrint("DEBUG SESSION: ${session != null}");
  }

  // =========================
  // USERS PROFILE
  // =========================
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final data = await supabase
        .from('users_profile')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return data == null ? null : Map<String, dynamic>.from(data);
  }

  // =========================
  // ADMIN - DATA PEMINJAM (ringkas)
  // =========================
  Future<List<Map<String, dynamic>>> adminListPeminjamRingkas() async {
    final peminjamRows = await getPeminjamList();
    final pinjamRows = await supabase
        .from('peminjaman')
        .select(
          'id_peminjaman, peminjam_id, tanggal_pinjam, status, '
          'peminjaman_detail(qty, alat(nama_alat))',
        )
        .order('id_peminjaman', ascending: false);

    final latestByPeminjam = <int, Map<String, dynamic>>{};
    for (final row in List<Map<String, dynamic>>.from(pinjamRows)) {
      final idPeminjam = (row['peminjam_id'] as num?)?.toInt();
      if (idPeminjam == null) continue;
      latestByPeminjam.putIfAbsent(idPeminjam, () => Map<String, dynamic>.from(row));
    }

    final out = <Map<String, dynamic>>[];
    for (final p in peminjamRows) {
      final pid = (p['peminjam_id'] as num?)?.toInt();
      final latest = pid == null ? null : latestByPeminjam[pid];
      final items = <String>[];
      if (latest != null) {
        final details = (latest['peminjaman_detail'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
        for (final d in details) {
          final alat = (d['alat'] as Map<String, dynamic>?) ?? {};
          final namaAlat = (alat['nama_alat'] ?? '-').toString();
          final qty = (d['qty'] as num?)?.toInt() ?? 1;
          items.add('$namaAlat x$qty');
        }
      }

      out.add({
        ...p,
        'last_peminjaman_id': latest?['id_peminjaman'],
        'last_tanggal_pinjam': latest?['tanggal_pinjam'],
        'last_status': latest?['status'],
        'last_items': items,
      });
    }

    return out;
  }

  // =========================
  // ADMIN/PETUGAS - DATA PETUGAS + PESAN
  // =========================
  Future<List<Map<String, dynamic>>> adminListPetugas() async {
    final rows = await supabase
        .from('users_profile')
        .select()
        .eq('role', 'petugas')
        .order('nama');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> adminKirimPesanKePetugas({
    required String petugasUserId,
    required String isiPesan,
  }) async {
    final admin = supabase.auth.currentUser;
    if (admin == null) throw Exception('User admin belum login.');

    try {
      await supabase.from('pesan_admin_petugas').insert({
        'admin_user_id': admin.id,
        'petugas_user_id': petugasUserId,
        'isi_pesan': isiPesan.trim(),
        'status_baca': false,
      });
    } catch (e) {
      if (_isMissingTableError(e, 'pesan_admin_petugas')) {
        throw Exception(
          'Tabel pesan_admin_petugas belum ada. Buat tabelnya dulu di Supabase.',
        );
      }
      if (_isRlsPolicyError(e)) {
        throw Exception(
          'Akses ditolak oleh RLS. Aktifkan policy INSERT untuk admin pada tabel pesan_admin_petugas.',
        );
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> petugasGetPesanMasuk() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User petugas belum login.');

    try {
      final rows = await supabase
          .from('pesan_admin_petugas')
          .select()
          .eq('petugas_user_id', user.id)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      if (_isMissingTableError(e, 'pesan_admin_petugas')) {
        return [];
      }
      if (_isRlsPolicyError(e)) {
        throw Exception(
          'Akses ditolak oleh RLS. Aktifkan policy SELECT untuk petugas pada tabel pesan_admin_petugas.',
        );
      }
      rethrow;
    }
  }

  // =========================
  // 1) ALAT (UMUM)
  // =========================
  Future<List<Map<String, dynamic>>> getAlat({
    String? status,
    int? idKategori,
  }) async {
    try {
      dynamic q = supabase
          .from('alat')
          .select('id_alat, nama_alat, id_kategori, spesifikasi, status, stok, foto_url');

      if (status != null && status.trim().isNotEmpty) q = q.eq('status', status);
      if (idKategori != null) q = q.eq('id_kategori', idKategori);

      final data = await q.order('id_alat');
      return _withDefaultStokList(data);
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;

      dynamic q = supabase
          .from('alat')
          .select('id_alat, nama_alat, id_kategori, spesifikasi, status, foto_url');

      if (status != null && status.trim().isNotEmpty) q = q.eq('status', status);
      if (idKategori != null) q = q.eq('id_kategori', idKategori);

      final data = await q.order('id_alat');
      return _withDefaultStokList(data);
    }
  }

  Future<List<Map<String, dynamic>>> getAlatTersedia() async {
    return getAlat(status: 'Tersedia');
  }

  Future<Map<String, dynamic>> getAlatById(int idAlat) async {
    try {
      final data = await supabase
          .from('alat')
          .select('id_alat, nama_alat, id_kategori, spesifikasi, status, stok, foto_url')
          .eq('id_alat', idAlat)
          .single();

      return _withDefaultStokRow(data);
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;

      final data = await supabase
          .from('alat')
          .select('id_alat, nama_alat, id_kategori, spesifikasi, status, foto_url')
          .eq('id_alat', idAlat)
          .single();

      return _withDefaultStokRow(data);
    }
  }

  // alias untuk kode lama
  Future<Map<String, dynamic>> fetchAlatById(int idAlat) async {
    return getAlatById(idAlat);
  }

  // =========================
  // 2) KATEGORI (UMUM)
  // =========================
  Future<List<Map<String, dynamic>>> getKategori() async {
    final data = await supabase
        .from('kategori')
        .select('id_kategori, nama_kategori, keterangan')
        .order('nama_kategori');

    return List<Map<String, dynamic>>.from(data);
  }

  // =========================
  // 3) PEMINJAM (data siswa)
  // =========================
  Future<List<Map<String, dynamic>>> getPeminjamList() async {
    final data = await supabase
        .from('peminjam')
        .select('peminjam_id, nama_peminjam, kelas, jurusan')
        .order('nama_peminjam');

    return List<Map<String, dynamic>>.from(data);
  }

  // alias untuk kode lama (keranjang)
  Future<List<Map<String, dynamic>>> fetchPeminjamList() async {
    return getPeminjamList();
  }

  // =========================
  // 4) BUAT PEMINJAMAN MULTI ITEM (RPC)
  // =========================
  // DB function: public.create_peminjaman_with_items(...)
  // params yang ADA di DB kamu:
  // - p_items
  // - p_peminjam_id
  // - p_tanggal_kembali_rencana
  Future<int> createPeminjamanMultiItem({
    required int peminjamId,
    required DateTime tanggalKembaliRencana,
    required List<int> alatIds,
  }) async {
    if (alatIds.isEmpty) {
      throw Exception('Minimal pilih 1 alat.');
    }

    final items = alatIds.map((id) => {'id_alat': id, 'qty': 1}).toList();
    return createPeminjamanWithItems(
      peminjamId: peminjamId,
      tanggalKembaliRencana: tanggalKembaliRencana,
      items: items,
    );
  }

  // dipakai oleh KeranjangPeminjamanScreen (items dari cart)
  Future<int> createPeminjamanWithItems({
    required int peminjamId,
    required DateTime tanggalKembaliRencana,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Keranjang kosong.');
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User belum login.');
    }

    final cleanedItems = items.map((e) {
      final idAlat = e['id_alat'];
      final qty = e['qty'] ?? 1;
      if (idAlat == null) throw Exception('Item tidak punya id_alat: $e');
      final qtyInt = (qty is int) ? qty : int.tryParse(qty.toString()) ?? 0;
      if (qtyInt <= 0) throw Exception('Qty tidak valid untuk id_alat=$idAlat');
      return {'id_alat': idAlat, 'qty': qtyInt};
    }).toList();

    final tglKembali =
        tanggalKembaliRencana.toIso8601String().substring(0, 10);

    final idAlatList = cleanedItems
        .map((e) => (e['id_alat'] as num).toInt())
        .toSet()
        .toList();
    dynamic alatRows;
    var stokColumnExists = true;
    try {
      alatRows = await supabase
          .from('alat')
          .select('id_alat, nama_alat, stok, status')
          .inFilter('id_alat', idAlatList);
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;
      stokColumnExists = false;
      alatRows = await supabase
          .from('alat')
          .select('id_alat, nama_alat, status')
          .inFilter('id_alat', idAlatList);
    }

    final stokMap = <int, Map<String, dynamic>>{};
    for (final row in _withDefaultStokList(alatRows)) {
      final id = (row['id_alat'] as num).toInt();
      stokMap[id] = row;
    }

    for (final item in cleanedItems) {
      final idAlat = (item['id_alat'] as num).toInt();
      final qty = item['qty'] as int;
      final alat = stokMap[idAlat];
      if (alat == null) {
        throw Exception('Alat dengan id=$idAlat tidak ditemukan');
      }
      if (!stokColumnExists && qty > 1) {
        throw Exception(
          'Database belum punya kolom stok. Qty > 1 belum didukung sebelum kolom stok ditambahkan.',
        );
      }
      final stok = (alat['stok'] as num?)?.toInt() ?? 0;
      if (stok < qty) {
        final nama = (alat['nama_alat'] ?? 'ID $idAlat').toString();
        throw Exception('Stok $nama tidak cukup. Tersedia: $stok, diminta: $qty');
      }
    }

    final header = await supabase
        .from('peminjaman')
        .insert({
          'peminjam_id': peminjamId,
          'user_id': user.id,
          'tanggal_pinjam': DateTime.now().toIso8601String().substring(0, 10),
          'tanggal_kembali_rencana': tglKembali,
          'status': 'menunggu',
        })
        .select('id_peminjaman')
        .single();

    final idPeminjaman = (header['id_peminjaman'] as num).toInt();
    final detailRows = cleanedItems.map((item) {
      return {
        'id_peminjaman': idPeminjaman,
        'id_alat': item['id_alat'],
        'qty': item['qty'],
        'status_item': 'menunggu',
      };
    }).toList();

    await supabase.from('peminjaman_detail').insert(detailRows);
    return idPeminjaman;
  }

  // =========================
  // 5) LIST PEMINJAMAN AKTIF (milik user login)
  // =========================
  Future<List<Map<String, dynamic>>> getPeminjamanAktifSaya({
    List<String>? statuses,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login.');
    final statusFilter = statuses ?? ['menunggu', 'aktif', 'disetujui'];

    final data = await supabase
        .from('peminjaman')
        .select(
          'id_peminjaman, user_id, tanggal_pinjam, tanggal_kembali_rencana, status, peminjam:peminjam_id(nama_peminjam)',
        )
        .eq('user_id', user.id)
        .inFilter('status', statusFilter)
        .order('id_peminjaman', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // =========================
  // 6) RIWAYAT PEMINJAMAN (milik user login)
  // =========================
  Future<List<Map<String, dynamic>>> getRiwayatPeminjamanSaya() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login.');

    final data = await supabase
        .from('peminjaman')
        .select(
          'id_peminjaman, user_id, tanggal_pinjam, tanggal_kembali_rencana, status, peminjam:peminjam_id(nama_peminjam)',
        )
        .eq('user_id', user.id)
        .order('id_peminjaman', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // =========================
  // 7) DETAIL ITEM PEMINJAMAN
  // =========================
  Future<List<Map<String, dynamic>>> getPeminjamanDetail(int idPeminjaman) async {
    try {
      final data = await supabase
          .from('peminjaman_detail')
          .select('id_alat, qty, status_item, alat:id_alat(nama_alat, status, stok)')
          .eq('id_peminjaman', idPeminjaman)
          .order('id_alat');

      final rows = List<Map<String, dynamic>>.from(data);
      for (final row in rows) {
        final alat = Map<String, dynamic>.from(row['alat'] as Map? ?? {});
        alat['stok'] = (alat['stok'] as num?)?.toInt() ?? 1;
        row['alat'] = alat;
      }
      return rows;
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;

      final data = await supabase
          .from('peminjaman_detail')
          .select('id_alat, qty, status_item, alat:id_alat(nama_alat, status)')
          .eq('id_peminjaman', idPeminjaman)
          .order('id_alat');

      final rows = List<Map<String, dynamic>>.from(data);
      for (final row in rows) {
        final alat = Map<String, dynamic>.from(row['alat'] as Map? ?? {});
        alat['stok'] = 1;
        row['alat'] = alat;
      }
      return rows;
    }
  }

  Future<List<Map<String, dynamic>>> getDetailPeminjaman(int idPeminjaman) async {
    return getPeminjamanDetail(idPeminjaman);
  }

  Future<Set<int>> getReturnedAlatIdsByPeminjaman(int idPeminjaman) async {
    final data = await supabase
        .from('pengembalian_detail')
        .select('id_alat, pengembalian!inner(id_peminjaman)')
        .eq('pengembalian.id_peminjaman', idPeminjaman);

    final result = <int>{};
    for (final row in List<Map<String, dynamic>>.from(data)) {
      final id = (row['id_alat'] as num?)?.toInt();
      if (id != null) result.add(id);
    }
    return result;
  }

  // =========================
  // 8) PENGEMBALIAN (HEADER)
  // =========================
  Future<int> createPengembalianHeader({
    required int idPeminjaman,
    String keterangan = 'pengembalian',
  }) async {
    final tgl = DateTime.now().toIso8601String().substring(0, 10);

    final header = await supabase
        .from('pengembalian')
        .insert({
          'id_peminjaman': idPeminjaman,
          'tanggal_kembali_real': tgl,
          'denda': 0,
          'keterangan': keterangan,
        })
        .select('id_pengembalian')
        .single();

    return (header['id_pengembalian'] as num).toInt();
  }

  Future<Map<String, dynamic>> getPengembalianById(int idPengembalian) async {
    final data = await supabase
        .from('pengembalian')
        .select('id_pengembalian, id_peminjaman, tanggal_kembali_real, denda')
        .eq('id_pengembalian', idPengembalian)
        .single();

    return Map<String, dynamic>.from(data);
  }

  Future<void> updatePengembalianDenda({
    required int idPengembalian,
    required int denda,
  }) async {
    await supabase
        .from('pengembalian')
        .update({'denda': denda})
        .eq('id_pengembalian', idPengembalian);
  }

  int hitungDendaKeterlambatan({
    required DateTime tanggalKembaliRencana,
    DateTime? tanggalPengembalian,
    int dendaPerHari = 5000,
  }) {
    final ref = tanggalPengembalian ?? DateTime.now();
    final tglKembali = DateTime(ref.year, ref.month, ref.day);
    final tglRencana = DateTime(
      tanggalKembaliRencana.year,
      tanggalKembaliRencana.month,
      tanggalKembaliRencana.day,
    );

    final hariTerlambat = math.max(0, tglKembali.difference(tglRencana).inDays);
    return hariTerlambat * dendaPerHari;
  }

  // =========================
  // 9) PENGEMBALIAN PER ITEM (DETAIL)
  // =========================
  Future<void> returnItem({
    required int idPengembalian,
    required int idAlat,
    String kondisi = 'baik',
    DateTime? tanggalKembaliItem,
    String? keteranganItem,
  }) async {
    final tgl = (tanggalKembaliItem ?? DateTime.now())
        .toIso8601String()
        .substring(0, 10);

    final payload = <String, dynamic>{
      'id_pengembalian': idPengembalian,
      'id_alat': idAlat,
      'tanggal_kembali_item': tgl,
      'kondisi': kondisi,
    };

    if (keteranganItem != null && keteranganItem.trim().isNotEmpty) {
      payload['keterangan_item'] = keteranganItem.trim();
    }

    await supabase.from('pengembalian_detail').insert(payload);
  }

  // ============================================================
  // ADMIN - KATEGORI (CRUD)
  // ============================================================
  Future<List<Map<String, dynamic>>> adminListKategori() async {
    final data = await supabase
        .from('kategori')
        .select('id_kategori, nama_kategori, keterangan')
        .order('id_kategori', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> adminCreateKategori({
    required String namaKategori,
    required String keterangan,
  }) async {
    final row = await supabase
        .from('kategori')
        .insert({
          'nama_kategori': namaKategori.trim(),
          'keterangan': keterangan.trim(),
        })
        .select('id_kategori')
        .single();

    return (row['id_kategori'] as num).toInt();
  }

  Future<void> adminUpdateKategori({
    required int idKategori,
    required String namaKategori,
    required String keterangan,
  }) async {
    await supabase.from('kategori').update({
      'nama_kategori': namaKategori.trim(),
      'keterangan': keterangan.trim(),
    }).eq('id_kategori', idKategori);
  }

  Future<void> adminDeleteKategori(int idKategori) async {
    await supabase.from('kategori').delete().eq('id_kategori', idKategori);
  }

  // ============================================================
  // ADMIN - ALAT (CRUD)
  // ============================================================
  Future<List<Map<String, dynamic>>> adminListAlat({
    int? idKategori,
    String? status,
  }) async {
    try {
      dynamic q = supabase.from('alat').select(
        'id_alat, nama_alat, id_kategori, spesifikasi, status, stok, foto_url, kategori:id_kategori(nama_kategori)',
      );

      if (idKategori != null) q = q.eq('id_kategori', idKategori);
      if (status != null && status.trim().isNotEmpty) q = q.eq('status', status);

      final data = await q.order('id_alat', ascending: false);
      return _withDefaultStokList(data);
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;

      dynamic q = supabase.from('alat').select(
        'id_alat, nama_alat, id_kategori, spesifikasi, status, foto_url, kategori:id_kategori(nama_kategori)',
      );

      if (idKategori != null) q = q.eq('id_kategori', idKategori);
      if (status != null && status.trim().isNotEmpty) q = q.eq('status', status);

      final data = await q.order('id_alat', ascending: false);
      return _withDefaultStokList(data);
    }
  }

  Future<int> adminCreateAlat({
    required String namaAlat,
    required int idKategori,
    required String spesifikasi,
    required String status,
    int stok = 1,
    String? fotoUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'nama_alat': namaAlat.trim(),
        'id_kategori': idKategori,
        'spesifikasi': spesifikasi.trim(),
        'status': status.trim(),
        'stok': stok,
      };
      if (fotoUrl != null && fotoUrl.trim().isNotEmpty) {
        payload['foto_url'] = fotoUrl.trim();
      }

      final row = await supabase
          .from('alat')
          .insert(payload)
          .select('id_alat')
          .single();

      return (row['id_alat'] as num).toInt();
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;

      final payload = <String, dynamic>{
        'nama_alat': namaAlat.trim(),
        'id_kategori': idKategori,
        'spesifikasi': spesifikasi.trim(),
        'status': status.trim(),
      };
      if (fotoUrl != null && fotoUrl.trim().isNotEmpty) {
        payload['foto_url'] = fotoUrl.trim();
      }

      final row = await supabase
          .from('alat')
          .insert(payload)
          .select('id_alat')
          .single();

      return (row['id_alat'] as num).toInt();
    }
  }

  Future<void> adminUpdateAlat({
    required int idAlat,
    required String namaAlat,
    required int idKategori,
    required String spesifikasi,
    required String status,
    int? stok,
  }) async {
    final payload = <String, dynamic>{
      'nama_alat': namaAlat.trim(),
      'id_kategori': idKategori,
      'spesifikasi': spesifikasi.trim(),
      'status': status.trim(),
    };
    if (stok != null) payload['stok'] = stok;
    try {
      await supabase.from('alat').update(payload).eq('id_alat', idAlat);
    } catch (e) {
      if (!_isMissingStokColumnError(e)) rethrow;
      payload.remove('stok');
      await supabase.from('alat').update(payload).eq('id_alat', idAlat);
    }
  }

  Future<void> adminDeleteAlat(int idAlat) async {
    await supabase.from('alat').delete().eq('id_alat', idAlat);
  }
}
