import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:super_selectos/models/product.dart';

class FavoritesDatabase {
  FavoritesDatabase._();

  static final FavoritesDatabase instance = FavoritesDatabase._();

  static const _databaseName = 'selectos_favorites.db';
  static const _databaseVersion = 1;
  static const _favoritesTable = 'favorite_products';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    _database = await openDatabase(
      '$databasesPath/$_databaseName',
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_favoritesTable (
            favorite_key TEXT PRIMARY KEY,
            product_json TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<Product>> getFavorites() async {
    final db = await database;
    final rows = await db.query(_favoritesTable, orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => Product.fromJson(
            jsonDecode(row['product_json']! as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveFavorite(String key, Product product) async {
    final db = await database;
    await db.insert(_favoritesTable, {
      'favorite_key': key,
      'product_json': jsonEncode(product.toJson()),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateFavorites(Map<String, Product> products) async {
    if (products.isEmpty) return;

    final db = await database;
    await db.transaction((transaction) async {
      final batch = transaction.batch();
      for (final entry in products.entries) {
        batch.update(
          _favoritesTable,
          {'product_json': jsonEncode(entry.value.toJson())},
          where: 'favorite_key = ?',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> removeFavorite(String key) async {
    final db = await database;
    await db.delete(
      _favoritesTable,
      where: 'favorite_key = ?',
      whereArgs: [key],
    );
  }
}
