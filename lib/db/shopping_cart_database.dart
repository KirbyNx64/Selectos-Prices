import 'package:sqflite/sqflite.dart';
import 'package:super_selectos/models/product.dart';
import 'package:super_selectos/models/shopping_cart_item.dart';
import 'package:super_selectos/models/shopping_list.dart';

class ShoppingCartDatabase {
  ShoppingCartDatabase._();

  static final ShoppingCartDatabase instance = ShoppingCartDatabase._();

  static const _databaseName = 'selectos_prices.db';
  static const _databaseVersion = 3;
  static const _itemsTable = 'shopping_cart';
  static const _listsTable = 'shopping_lists';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    _database = await openDatabase(
      '$databasesPath/$_databaseName',
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createListsTable(db);
        await _createItemsTable(db);
        await _insertList(db, DateTime.now());
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToMultipleLists(db);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $_listsTable ADD COLUMN name TEXT');
        }
      },
    );
    return _database!;
  }

  Future<List<ShoppingList>> getLists() async {
    final db = await database;
    final rows = await db.query(_listsTable, orderBy: 'created_at DESC');
    return rows.map(ShoppingList.fromMap).toList();
  }

  Future<ShoppingList> createList(DateTime createdAt, {String? name}) async {
    final db = await database;
    final id = await _insertList(db, createdAt, name: name);
    return ShoppingList(id: id, createdAt: createdAt, name: name);
  }

  Future<void> updateListName(int listId, String? name) async {
    final db = await database;
    await db.update(
      _listsTable,
      {'name': name?.trim().isEmpty == true ? null : name?.trim()},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  Future<void> updateListDateTime(int listId, DateTime dateTime) async {
    final db = await database;
    await db.update(
      _listsTable,
      {'created_at': dateTime.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  Future<void> deleteList(int listId) async {
    final db = await database;
    await db.delete(_listsTable, where: 'id = ?', whereArgs: [listId]);
  }

  Future<ShoppingList> deleteAllListsAndCreate(
    DateTime createdAt, {
    String? name,
  }) async {
    final db = await database;
    return db.transaction((transaction) async {
      await transaction.delete(_itemsTable);
      await transaction.delete(_listsTable);
      final id = await _insertList(transaction, createdAt, name: name);
      return ShoppingList(id: id, createdAt: createdAt, name: name);
    });
  }

  Future<List<ShoppingCartItem>> getItems(int listId) async {
    final db = await database;
    final rows = await db.query(
      _itemsTable,
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'nombre COLLATE NOCASE',
    );
    return rows.map(ShoppingCartItem.fromMap).toList();
  }

  Future<void> addProduct(int listId, Product product, int quantity) async {
    if (quantity < 1) return;

    final db = await database;
    final key = ShoppingCartItem.keyFor(product);

    await db.transaction((txn) async {
      final existing = await txn.query(
        _itemsTable,
        columns: ['cantidad'],
        where: 'list_id = ? AND product_key = ?',
        whereArgs: [listId, key],
        limit: 1,
      );
      final currentQuantity = existing.isEmpty
          ? 0
          : existing.first['cantidad'] as int;

      final item = ShoppingCartItem(
        key: key,
        product: product,
        quantity: currentQuantity + quantity,
      );
      await txn.insert(_itemsTable, {
        'list_id': listId,
        ...item.toMap(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> updateQuantity(int listId, String key, int quantity) async {
    if (quantity < 1) {
      await removeProduct(listId, key);
      return;
    }
    final db = await database;
    await db.update(
      _itemsTable,
      {'cantidad': quantity},
      where: 'list_id = ? AND product_key = ?',
      whereArgs: [listId, key],
    );
  }

  Future<void> removeProduct(int listId, String key) async {
    final db = await database;
    await db.delete(
      _itemsTable,
      where: 'list_id = ? AND product_key = ?',
      whereArgs: [listId, key],
    );
  }

  Future<void> clear(int listId) async {
    final db = await database;
    await db.delete(_itemsTable, where: 'list_id = ?', whereArgs: [listId]);
  }

  static Future<void> _createListsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $_listsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createItemsTable(DatabaseExecutor db) async {
    await db.execute('''
          CREATE TABLE $_itemsTable (
            list_id INTEGER NOT NULL,
            product_key TEXT NOT NULL,
            product_id TEXT NOT NULL,
            nombre TEXT NOT NULL,
            precio REAL,
            precio_final REAL,
            precio_original REAL,
            descuento REAL NOT NULL DEFAULT 0,
            tiene_descuento INTEGER NOT NULL DEFAULT 0,
            promocion TEXT,
            imagen TEXT,
            imagenes TEXT NOT NULL DEFAULT '[]',
            descripcion TEXT,
            enlace TEXT,
            supermercado TEXT NOT NULL,
            codigo_barra TEXT,
            categoria TEXT,
            cantidad INTEGER NOT NULL CHECK (cantidad > 0),
            PRIMARY KEY (list_id, product_key),
            FOREIGN KEY (list_id) REFERENCES $_listsTable(id) ON DELETE CASCADE
          )
        ''');
  }

  static Future<int> _insertList(
    DatabaseExecutor db,
    DateTime createdAt, {
    String? name,
  }) {
    return db.insert(_listsTable, {
      'name': name?.trim().isEmpty == true ? null : name?.trim(),
      'created_at': createdAt.millisecondsSinceEpoch,
    });
  }

  static Future<void> _migrateToMultipleLists(Database db) async {
    await _createListsTable(db);
    final listId = await _insertList(db, DateTime.now());
    await db.execute(
      'ALTER TABLE $_itemsTable RENAME TO ${_itemsTable}_version_1',
    );
    await _createItemsTable(db);
    await db.execute('''
      INSERT INTO $_itemsTable (
        list_id, product_key, product_id, nombre, precio, precio_final,
        precio_original, descuento, tiene_descuento, promocion, imagen,
        imagenes, descripcion, enlace, supermercado, codigo_barra, categoria,
        cantidad
      )
      SELECT
        $listId, product_key, product_id, nombre, precio, precio_final,
        precio_original, descuento, tiene_descuento, promocion, imagen,
        imagenes, descripcion, enlace, supermercado, codigo_barra, categoria,
        cantidad
      FROM ${_itemsTable}_version_1
    ''');
    await db.execute('DROP TABLE ${_itemsTable}_version_1');
  }
}
