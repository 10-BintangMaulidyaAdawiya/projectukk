import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPetugasService {
  final SupabaseClient _db = Supabase.instance.client;

  // Hitung jumlah peminjaman berdasarkan status (menunggu/disetujui/selesai/dll)
  Future<int> countByStatus(String status) async {
    final data = await _db
        .from('peminjaman')
        .select('id_peminjaman')
        .eq('status', status);

    return (data as List).length;
  }

  // Hitung terlambat: status disetujui dan tanggal_kembali_rencana < hari ini
  Future<int> countTerlambat() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final data = await _db
        .from('peminjaman')
        .select('id_peminjaman')
        .eq('status', 'disetujui')
        .lt('tanggal_kembali_rencana', todayStr);

    return (data as List).length;
  }

  // === Tambahan untuk PETUGAS: list permintaan menunggu persetujuan ===
  // Mengambil peminjaman + nama peminjam + detail alat yang diminta
  Future<List<Map<String, dynamic>>> listMenunggu() async {
    final data = await _db
        .from('peminjaman')
        .select(
          'id_peminjaman, tanggal_pinjam, tanggal_kembali_rencana, status, '
          'peminjam(peminjam_id, nama_peminjam), '
          'peminjaman_detail(id_detail, id_alat, qty, status_item, alat(nama_alat))',
        )
        .eq('status', 'menunggu')
        .order('tanggal_pinjam', ascending: false);

    return (data as List).cast<Map<String, dynamic>>();
  }

  // === Aksi PETUGAS: setujui ===
  // Update status peminjaman + status_item detail
  Future<void> setujui(int idPeminjaman) async {
    // 1) update header peminjaman
    await _db
        .from('peminjaman')
        .update({'status': 'disetujui'})
        .eq('id_peminjaman', idPeminjaman);

    // 2) update detail item
    await _db
        .from('peminjaman_detail')
        .update({'status_item': 'dipinjam'})
        .eq('id_peminjaman', idPeminjaman);

    // OPTIONAL (kalau kamu pakai status alat):
    // Ambil detail lalu update alat.status satu-satu
    // final details = await _db
    //     .from('peminjaman_detail')
    //     .select('id_alat')
    //     .eq('id_peminjaman', idPeminjaman);
    //
    // for (final d in (details as List)) {
    //   await _db.from('alat').update({'status': 'dipinjam'}).eq('id_alat', d['id_alat']);
    // }
  }

  // === Aksi PETUGAS: tolak ===
  Future<void> tolak(int idPeminjaman) async {
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
