import 'package:flutter/material.dart';

import 'alat_admin_page.dart';

class ProdukPage extends StatelessWidget {
  const ProdukPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Produk admin sekarang langsung memakai halaman CRUD alat
    // yang sudah terhubung ke Supabase.
    return const AlatAdminPage();
  }
}
