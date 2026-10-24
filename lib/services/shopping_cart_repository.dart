import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_selectos/db/shopping_cart_database.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/shopping_cart_item.dart';
import 'package:super_selectos/models/shopping_list.dart';

class ShoppingCartRepository extends ChangeNotifier {
  ShoppingCartRepository._();

  static final ShoppingCartRepository instance = ShoppingCartRepository._();
  static const String _selectedListIdKey = 'shopping_cart_selected_list_id';

  final ShoppingCartDatabase _database = ShoppingCartDatabase.instance;
  final List<ShoppingCartItem> _items = [];
  final List<ShoppingList> _lists = [];
  ShoppingList? _selectedList;
  bool _initialized = false;
  bool _loading = false;
  ShoppingListSortOrder _sortOrder = ShoppingListSortOrder.nameAscending;

  UnmodifiableListView<ShoppingCartItem> get items =>
      UnmodifiableListView(_items);

  UnmodifiableListView<ShoppingList> get lists => UnmodifiableListView(_lists);

  ShoppingList? get selectedList => _selectedList;

  bool get loading => _loading;

  ShoppingListSortOrder get sortOrder => _sortOrder;

  int get totalItems => _items.fold(0, (total, item) => total + item.quantity);

  int get checkedItems => _items
      .where((item) => item.isChecked)
      .fold(0, (total, item) => total + item.quantity);

  int get remainingItems => totalItems - checkedItems;

  double get purchaseTotal =>
      _items.fold(0, (total, item) => total + item.regularSubtotal);

  double get totalSavings =>
      _items.fold(0, (total, item) => total + item.totalSavings);

  double get estimatedTotal =>
      _items.fold(0, (total, item) => total + item.subtotal);

  Future<void> setSortOrder(ShoppingListSortOrder sortOrder) async {
    if (_sortOrder == sortOrder) return;
    await _ensureInitialized();
    final selectedList = _requireSelectedList();
    await _database.updateListSortOrder(selectedList.id, sortOrder);

    final updatedList = ShoppingList(
      id: selectedList.id,
      createdAt: selectedList.createdAt,
      name: selectedList.name,
      sortOrder: sortOrder,
    );
    final listIndex = _lists.indexWhere((list) => list.id == selectedList.id);
    if (listIndex != -1) _lists[listIndex] = updatedList;
    _selectedList = updatedList;
    _sortOrder = sortOrder;
    _sortItems();
    notifyListeners();
  }

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
      final preferences = await SharedPreferences.getInstance();
      final savedListId = preferences.getInt(_selectedListIdKey);
      final savedListIndex = _lists.indexWhere(
        (list) => list.id == savedListId,
      );
      _selectedList = savedListIndex == -1
          ? _lists.first
          : _lists[savedListIndex];
      await preferences.setInt(_selectedListIdKey, _selectedList!.id);
      _sortOrder = _selectedList!.sortOrder;
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

  Future<void> updateChecked(String key, bool isChecked) async {
    await _ensureInitialized();
    await _database.updateChecked(_requireSelectedList().id, key, isChecked);
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

  Future<void> createList({String? name}) async {
    await _ensureInitialized();
    final list = await _database.createList(DateTime.now(), name: name);
    _lists.insert(0, list);
    _selectedList = list;
    _sortOrder = list.sortOrder;
    _items.clear();
    await _saveSelectedListId(list.id);
    notifyListeners();
  }

  Future<void> updateSelectedListName(String? name) async {
    await _ensureInitialized();
    final selectedList = _requireSelectedList();
    final cleanName = name?.trim().isEmpty == true ? null : name?.trim();
    await _database.updateListName(selectedList.id, cleanName);

    final updatedList = ShoppingList(
      id: selectedList.id,
      createdAt: selectedList.createdAt,
      name: cleanName,
      sortOrder: selectedList.sortOrder,
    );
    final listIndex = _lists.indexWhere((list) => list.id == selectedList.id);
    if (listIndex != -1) {
      _lists[listIndex] = updatedList;
    }
    _selectedList = updatedList;
    notifyListeners();
  }

  Future<void> selectList(int id) async {
    await _ensureInitialized();
    if (_selectedList?.id == id) return;
    _selectedList = _lists.firstWhere((list) => list.id == id);
    _sortOrder = _selectedList!.sortOrder;
    await _saveSelectedListId(id);
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

    final updatedList = ShoppingList(
      id: selectedList.id,
      createdAt: dateTime,
      name: selectedList.name,
      sortOrder: selectedList.sortOrder,
    );
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
    _sortOrder = _selectedList!.sortOrder;
    await _saveSelectedListId(_selectedList!.id);
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
    _sortOrder = replacement.sortOrder;
    _items.clear();
    await _saveSelectedListId(replacement.id);
    notifyListeners();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Future<void> _saveSelectedListId(int listId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_selectedListIdKey, listId);
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
    _sortItems();
  }

  void _sortItems() {
    int compareNames(ShoppingCartItem a, ShoppingCartItem b) => a.product.nombre
        .toLowerCase()
        .compareTo(b.product.nombre.toLowerCase());

    int withNameFallback(
      ShoppingCartItem a,
      ShoppingCartItem b,
      int comparison,
    ) => comparison != 0 ? comparison : compareNames(a, b);

    _items.sort((a, b) {
      return switch (_sortOrder) {
        ShoppingListSortOrder.nameAscending => compareNames(a, b),
        ShoppingListSortOrder.nameDescending => compareNames(b, a),
        ShoppingListSortOrder.priceAscending => withNameFallback(
          a,
          b,
          a.unitPrice.compareTo(b.unitPrice),
        ),
        ShoppingListSortOrder.priceDescending => withNameFallback(
          a,
          b,
          b.unitPrice.compareTo(a.unitPrice),
        ),
        ShoppingListSortOrder.addedAscending => withNameFallback(
          a,
          b,
          a.addedAt.compareTo(b.addedAt),
        ),
        ShoppingListSortOrder.addedDescending => withNameFallback(
          a,
          b,
          b.addedAt.compareTo(a.addedAt),
        ),
      };
    });
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
