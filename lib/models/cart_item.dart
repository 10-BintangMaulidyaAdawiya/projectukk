class CartItem {
  final int idAlat;
  final String namaAlat;
  final String status;
  final int stok;
  int qty;

  CartItem({
    required this.idAlat,
    required this.namaAlat,
    required this.status,
    required this.stok,
    this.qty = 1,
  });

  /// Format yang dikirim ke RPC Supabase
  Map<String, dynamic> toRpcJson() => {
        'id_alat': idAlat,
        'qty': qty,
      };
}
