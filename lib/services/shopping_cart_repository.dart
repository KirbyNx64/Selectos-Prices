import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:super_selectos/db/shopping_cart_database.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/shopping_cart_item.dart';
import 'package:super_selectos/models/shopping_list.dart';

class ShoppingCartRepository extends ChangeNotifier {
  ShoppingCartRepository._();

  static final ShoppingCartRepository instance = ShoppingCartRepository._();

  final ShoppingCartDatabase _database = ShoppingCartDatabase.instance;
  final List<ShoppingCartItem> _items = [];
  final List<ShoppingList> _lists = [];
  ShoppingList? _selectedList;
  bool _initialized = false;
  bool _loading = false;

  UnmodifiableListView<ShoppingCartItem> get items =>
      UnmodifiableListView(_items);

  UnmodifiableListView<ShoppingList> get lists => UnmodifiableListView(_lists);

  ShoppingList? get selectedList => _selectedList;

  bool get loading => _loading;

  int get totalItems => _items.fold(0, (total, item) => total + item.quantity);

  double get purchaseTotal =>
      _items.fold(0, (total, item) => total + item.regularSubtotal);

  double get totalSavings =>
      _items.fold(0, (total, item) => total + item.totalSavings);

  double get estimatedTotal =>
      _items.fold(0, (total, item) => total + item.subtotal);

  Future<void> initialize() async {
    if (_initialized || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      await _loadLists();
      if (_lists.isEmpty) {
        final list = await _database.createList(DateTime.now());
        _lists.add(list);
      }
      _selectedList ??= _lists.first;
      await _reload();
      _initialized = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product, int quantity) async {
    await _ensureInitialized();
    await _database.addProduct(_requireSelectedList().id, product, quantity);
    await _reload();
    notifyListeners();
  }

  Future<void> updateQuantity(String key, int quantity) async {
    await _ensureInitialized();
    await _database.updateQuantity(_requireSelectedList().id, key, quantity);
    await _reload();
    notifyListeners();
  }

  Future<void> removeProduct(String key) async {
    await _ensureInitialized();
    await _database.removeProduct(_requireSelectedList().id, key);
    await _reload();
    notifyListeners();
  }

  Future<void> clear() async {
    await _ensureInitialized();
    await _database.clear(_requireSelectedList().id);
    _items.clear();
    notifyListeners();
  }

  Future<void> createList() async {
    await _ensureInitialized();
    final list = await _database.createList(DateTime.now());
    _lists.insert(0, list);
    _selectedList = list;
    _items.clear();
    notifyListeners();
  }

  Future<void> selectList(int id) async {
    await _ensureInitialized();
    if (_selectedList?.id == id) return;
    _selectedList = _lists.firstWhere((list) => list.id == id);
    _loading = true;
    notifyListeners();
    try {
      await _reload();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSelectedListDateTime(DateTime dateTime) async {
    await _ensureInitialized();
    final selectedList = _requireSelectedList();
    await _database.updateListDateTime(selectedList.id, dateTime);

    final updatedList = ShoppingList(id: selectedList.id, createdAt: dateTime);
    final listIndex = _lists.indexWhere((list) => list.id == selectedList.id);
    _lists[listIndex] = updatedList;
    _lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _selectedList = updatedList;
    notifyListeners();
  }

  Future<void> deleteSelectedList() async {
    await _ensureInitialized();
    final selectedList = _requireSelectedList();
    await _database.deleteList(selectedList.id);
    _lists.removeWhere((list) => list.id == selectedList.id);

    if (_lists.isEmpty) {
      final replacement = await _database.createList(DateTime.now());
      _lists.add(replacement);
    }

    _selectedList = _lists.first;
    await _reload();
    notifyListeners();
  }

  Future<void> deleteAllLists() async {
    await _ensureInitialized();
    final replacement = await _database.deleteAllListsAndCreate(DateTime.now());
    _lists
      ..clear()
      ..add(replacement);
    _selectedList = replacement;
    _items.clear();
    notifyListeners();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Future<void> _reload() async {
    final selectedList = _selectedList;
    if (selectedList == null) {
      _items.clear();
      return;
    }
    final storedItems = await _database.getItems(selectedList.id);
    _items
      ..clear()
      ..addAll(storedItems);
  }

  Future<void> _loadLists() async {
    final storedLists = await _database.getLists();
    _lists
      ..clear()
      ..addAll(storedLists);
  }

  ShoppingList _requireSelectedList() {
    final list = _selectedList;
    if (list == null) {
      throw StateError('No hay una lista de compras seleccionada');
    }
    return list;
  }
}
