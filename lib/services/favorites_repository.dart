import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:super_selectos/db/favorites_database.dart';
import 'package:super_selectos/models/product.dart';

class FavoritesRepository extends ChangeNotifier {
  FavoritesRepository._();

  static final FavoritesRepository instance = FavoritesRepository._();

  final FavoritesDatabase _database = FavoritesDatabase.instance;
  final List<Product> _products = [];
  bool _initialized = false;
  bool _loading = false;

  UnmodifiableListView<Product> get products => UnmodifiableListView(_products);

  bool get loading => _loading;

  Future<void> initialize() async {
    if (_initialized || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      final storedProducts = await _database.getFavorites();
      _products
        ..clear()
        ..addAll(storedProducts);
      _initialized = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool isFavorite(Product product) {
    final key = keyFor(product);
    return _products.any((favorite) => keyFor(favorite) == key);
  }

  Future<bool> toggle(Product product) async {
    await _ensureInitialized();
    final key = keyFor(product);
    final index = _products.indexWhere((favorite) => keyFor(favorite) == key);

    if (index >= 0) {
      await _database.removeFavorite(key);
      _products.removeAt(index);
      notifyListeners();
      return false;
    }

    await _database.saveFavorite(key, product);
    _products.insert(0, product);
    notifyListeners();
    return true;
  }

  Future<void> updateProducts(Iterable<Product> products) async {
    await _ensureInitialized();

    final updates = <String, Product>{};
    for (final product in products) {
      final key = keyFor(product);
      if (_products.any((favorite) => keyFor(favorite) == key)) {
        updates[key] = product;
      }
    }
    if (updates.isEmpty) return;

    await _database.updateFavorites(updates);
    for (final entry in updates.entries) {
      final index = _products.indexWhere(
        (favorite) => keyFor(favorite) == entry.key,
      );
      if (index >= 0) _products[index] = entry.value;
    }
    notifyListeners();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  static String keyFor(Product product) {
    final id = product.id.trim();
    if (id.isNotEmpty) return 'id:$id';

    final barcode = product.codigoBarra?.trim();
    if (barcode != null && barcode.isNotEmpty) return 'barcode:$barcode';

    return 'name:${product.supermercado}:${product.nombre.trim().toLowerCase()}';
  }
}
