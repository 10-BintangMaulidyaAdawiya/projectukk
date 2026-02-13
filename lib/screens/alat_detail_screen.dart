import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item.dart';

class AlatDetailScreen extends StatefulWidget {
  final int idAlat;
  const AlatDetailScreen({super.key, required this.idAlat});

  @override
  State<AlatDetailScreen> createState() => _AlatDetailScreenState();
}

class _AlatDetailScreenState extends State<AlatDetailScreen> {
  final _svc = SupabaseService();
  bool _loading = true;
  Map<String, dynamic>? _alat;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.fetchAlatById(widget.idAlat);
      setState(() => _alat = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _brandFromName(String namaAlat) {
    final n = namaAlat.toLowerCase();
    if (n.contains('asus')) return 'asus';
    if (n.contains('acer')) return 'acer';
    if (n.contains('lenovo')) return 'lenovo';
    if (n.contains('dell')) return 'dell';
    if (n.contains('hp')) return 'hp';
    if (n.contains('msi')) return 'msi';
    if (n.contains('apple') || n.contains('macbook')) return 'macbook';
    return 'laptop';
  }

  String _defaultBrandImageUrl(String namaAlat) {
    final brand = _brandFromName(namaAlat);
    return 'https://source.unsplash.com/1200x800/?$brand,laptop';
  }

  Widget _buildDetailImage() {
    final fotoUrl = (_alat?['foto_url'] ?? '').toString().trim();
    final nama = (_alat?['nama_alat'] ?? '').toString();
    final img = fotoUrl.isNotEmpty ? fotoUrl : _defaultBrandImageUrl(nama);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        img,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderImage(),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: Icon(Icons.laptop_mac, size: 60)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xffE8ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xff2C3E75),
        title: const Text('Detail Barang'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_alat == null)
              ? const Center(child: Text('Data tidak ditemukan'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: _buildDetailImage(),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _alat!['nama_alat'].toString(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Status: ${_alat!['status']}'),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Stok: ${_alat!['stok'] ?? 0}'),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          (_alat!['spesifikasi'] ?? '').toString(),
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      const Spacer(),

                      finalButton(cart),
                    ],
                  ),
                ),
    );
  }

  Widget finalButton(CartProvider cart) {
    final status = (_alat!['status'] ?? '-').toString();
    final stok = (_alat!['stok'] as num?)?.toInt() ?? 0;
    final tersedia = status.toLowerCase() == 'tersedia' && stok > 0;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: tersedia
            ? () {
                cart.addItem(
                  CartItem(
                    idAlat: _alat!['id_alat'] as int,
                    namaAlat: _alat!['nama_alat'].toString(),
                    status: status,
                    stok: stok,
                    qty: 1,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Masuk keranjang peminjaman')),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff2C3E75),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(tersedia ? 'Ajukan Peminjaman' : 'Tidak tersedia'),
      ),
    );
  }
}
// TODO Implement this library.
