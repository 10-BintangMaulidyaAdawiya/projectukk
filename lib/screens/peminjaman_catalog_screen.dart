import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../services/supabase_service.dart';
import 'keranjang_peminjaman_screen.dart';
import 'peminjaman_riwayat_screen.dart';

class PeminjamanCatalogScreen extends StatefulWidget {
  const PeminjamanCatalogScreen({super.key});

  @override
  State<PeminjamanCatalogScreen> createState() => _PeminjamanCatalogScreenState();
}

class _PeminjamanCatalogScreenState extends State<PeminjamanCatalogScreen> {
  final _svc = SupabaseService();

  bool _loading = true;
  bool _loadingAktif = true;

  String _search = '';
  int? _selectedKategoriId;

  List<Map<String, dynamic>> _kategori = [];
  List<Map<String, dynamic>> _alat = [];

  List<Map<String, dynamic>> _peminjamanAktif = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _loadingAktif = true;
    });

    try {
      final kat = await _svc.getKategori();
      final alat = await _svc.getAlat(); // semua alat (Tersedia + Dipinjam)

      // ambil peminjaman aktif user login
      final aktif = await _svc.getPeminjamanAktifSaya();

      if (!mounted) return;
      setState(() {
        _kategori = kat;
        _alat = alat;
        _peminjamanAktif = aktif;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal load data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingAktif = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();
    return _alat.where((a) {
      final nama = (a['nama_alat'] ?? '').toString().toLowerCase();
      final okSearch = q.isEmpty || nama.contains(q);

      final okKategori = _selectedKategoriId == null ||
          (a['id_kategori'] as int?) == _selectedKategoriId;

      return okSearch && okKategori;
    }).toList();
  }

  void _addToCart(Map<String, dynamic> alat) {
    final status = (alat['status'] ?? '').toString();
    final stok = (alat['stok'] as num?)?.toInt() ?? 0;
    final idAlat = (alat['id_alat'] as num).toInt();
    final cart = context.read<CartProvider>();
    int qtyDiCart = 0;
    for (final item in cart.items) {
      if (item.idAlat == idAlat) {
        qtyDiCart = item.qty;
        break;
      }
    }

    if (status.toLowerCase() != 'tersedia' || stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alat tidak tersedia untuk dipinjam')),
      );
      return;
    }

    if (qtyDiCart >= stok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok tidak cukup. Maksimal $stok item.')),
      );
      return;
    }

    cart.addItem(
          CartItem(
            idAlat: idAlat,
            namaAlat: (alat['nama_alat'] ?? '').toString(),
            status: status,
            stok: stok,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ditambahkan ke keranjang')),
    );
  }

  Map<String, dynamic>? get _aktifTerbaru {
    if (_peminjamanAktif.isEmpty) return null;
    return _peminjamanAktif.first;
  }

  String _brandFromName(String namaAlat) {
    final n = namaAlat.toLowerCase();
    if (n.contains('asus')) return 'ASUS';
    if (n.contains('acer')) return 'ACER';
    if (n.contains('lenovo')) return 'LENOVO';
    if (n.contains('dell')) return 'DELL';
    if (n.contains('hp')) return 'HP';
    if (n.contains('msi')) return 'MSI';
    if (n.contains('apple') || n.contains('macbook')) return 'APPLE';
    return 'LAPTOP';
  }

  String _defaultBrandImageUrl(String namaAlat) {
    final brand = _brandFromName(namaAlat).toLowerCase();
    if (brand == 'asus') {
      return 'https://source.unsplash.com/800x600/?asus,laptop';
    }
    if (brand == 'acer') {
      return 'https://source.unsplash.com/800x600/?acer,laptop';
    }
    if (brand == 'lenovo') {
      return 'https://source.unsplash.com/800x600/?lenovo,laptop';
    }
    if (brand == 'dell') {
      return 'https://source.unsplash.com/800x600/?dell,laptop';
    }
    if (brand == 'hp') {
      return 'https://source.unsplash.com/800x600/?hp,laptop';
    }
    if (brand == 'msi') {
      return 'https://source.unsplash.com/800x600/?msi,laptop';
    }
    if (brand == 'apple') {
      return 'https://source.unsplash.com/800x600/?macbook,laptop';
    }
    return 'https://source.unsplash.com/800x600/?laptop,computer';
  }

  Widget _buildAlatImage(Map<String, dynamic> alat) {
    final nama = (alat['nama_alat'] ?? '').toString();
    final fotoUrl = (alat['foto_url'] ?? '').toString().trim();
    final img = fotoUrl.isNotEmpty ? fotoUrl : _defaultBrandImageUrl(nama);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _brandPlaceholder(nama),
      ),
    );
  }

  Widget _brandPlaceholder(String namaAlat) {
    final brand = _brandFromName(namaAlat);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xffF3F5FF), Color(0xffDDE4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.laptop_mac,
              size: 42,
              color: Color(0xff2C3E75),
            ),
            const SizedBox(height: 6),
            Text(
              brand,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff2C3E75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        title: const Text('Daftar Alat'),
        actions: [
          // ===== icon keranjang + badge =====
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KeranjangPeminjamanScreen(),
                    ),
                  );
                },
              ),
              if (cart.totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      cart.totalItems.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Halo Peminjam 👋',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // =========================
                  // CARD STATUS PEMINJAMAN AKTIF + BUTTON RIWAYAT
                  // =========================
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _loadingAktif
                          ? const SizedBox(
                              height: 80,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status Peminjaman Aktif Saya',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                if (_aktifTerbaru == null)
                                  const Text('Tidak ada peminjaman aktif.')
                                else ...[
                                  Text(
                                      'Transaksi #${_aktifTerbaru!['id_peminjaman']}'),
                                  Text(
                                      'Pinjam: ${_aktifTerbaru!['tanggal_pinjam']}'),
                                  Text(
                                      'Kembali: ${_aktifTerbaru!['tanggal_kembali_rencana']}'),
                                  Text('Status: ${_aktifTerbaru!['status']}'),
                                  if ((_aktifTerbaru!['status'] ?? '').toString() ==
                                      'menunggu')
                                    const Text(
                                      'Menunggu persetujuan petugas',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                ],
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PeminjamanRiwayatScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.history),
                                    label:
                                        const Text('Lihat Riwayat Peminjaman'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== Search =====
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari produk',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 12),

                  // ===== Filter kategori (chips) =====
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChoiceChip(
                          label: const Text('Semua'),
                          selected: _selectedKategoriId == null,
                          onSelected: (_) =>
                              setState(() => _selectedKategoriId = null),
                        ),
                        const SizedBox(width: 8),
                        ..._kategori.map((k) {
                          final id = k['id_kategori'] as int;
                          final nama = (k['nama_kategori'] ?? '').toString();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(nama),
                              selected: _selectedKategoriId == id,
                              onSelected: (_) =>
                                  setState(() => _selectedKategoriId = id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ===== Grid alat =====
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, i) {
                      final a = _filtered[i];
                      final status = (a['status'] ?? '').toString();
                      final stok = (a['stok'] as num?)?.toInt() ?? 0;
                      final isTersedia =
                          status.toLowerCase() == 'tersedia' && stok > 0;

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _addToCart(a),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: Offset(0, 4),
                                color: Color(0x14000000),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: _buildAlatImage(a),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                (a['nama_alat'] ?? '').toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Stok: $stok | $status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isTersedia ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: ElevatedButton(
                                  onPressed:
                                      isTersedia ? () => _addToCart(a) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff2C3E75),
                                    disabledBackgroundColor:
                                        const Color(0xff9AA7D6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isTersedia ? 'Ajukan' : 'Tidak tersedia',
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
