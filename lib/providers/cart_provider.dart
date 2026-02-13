import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  /// daftar item (read-only)
  List<CartItem> get items => List.unmodifiable(_items);

  /// total qty semua barang
  int get totalItems => _items.fold(0, (sum, item) => sum + item.qty);

  /// tambah barang ke cart
  void addItem(CartItem item) {
    final index = _items.indexWhere((x) => x.idAlat == item.idAlat);

    if (index >= 0) {
      if (_items[index].qty < _items[index].stok) {
        _items[index].qty += 1;
      }
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  /// hapus barang dari cart
  void removeItem(int idAlat) {
    _items.removeWhere((x) => x.idAlat == idAlat);
    notifyListeners();
  }

  /// kosongkan cart (setelah submit peminjaman)
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
