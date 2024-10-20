import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hotkeys.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Create hotkeys table
        await db.execute('''
          CREATE TABLE hotkeys(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hotkey TEXT NOT NULL,
            item TEXT NOT NULL
          )
        ''');

        // Create sub_items table with foreign key
        await db.execute('''
          CREATE TABLE sub_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hotkey_id INTEGER,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            stock INTEGER DEFAULT 0,
            FOREIGN KEY (hotkey_id) REFERENCES hotkeys (id)
              ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE sub_items(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              hotkey_id INTEGER,
              name TEXT NOT NULL,
              price REAL NOT NULL,
              stock INTEGER DEFAULT 0,
              FOREIGN KEY (hotkey_id) REFERENCES hotkeys (id)
                ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  // Hotkey CRUD Operations
  Future<int> createHotkey(String hotkey, String item) async {
    final db = await database;
    return await db.insert(
      'hotkeys',
      {
        'hotkey': hotkey,
        'item': item,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllHotkeys() async {
    final db = await database;
    final List<Map<String, dynamic>> hotkeys = await db.query('hotkeys');
    
    // Fetch sub-items for each hotkey
    for (var hotkey in hotkeys) {
      final subItems = await getSubItems(hotkey['id']);
      hotkey['subItems'] = subItems;
    }
    
    return hotkeys;
  }

  Future<Map<String, dynamic>?> getHotkey(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'hotkeys',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      final hotkey = results.first;
      final subItems = await getSubItems(hotkey['id']);
      hotkey['subItems'] = subItems;
      return hotkey;
    }
    return null;
  }

  Future<int> updateHotkey(int id, String hotkey, String item) async {
    final db = await database;
    return await db.update(
      'hotkeys',
      {
        'hotkey': hotkey,
        'item': item,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHotkey(int id) async {
    final db = await database;
    // Sub-items will be automatically deleted due to CASCADE
    return await db.delete(
      'hotkeys',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllHotkeys() async {
    final db = await database;
    await db.delete('hotkeys');
  }

  // Sub-item CRUD Operations
  Future<int> createSubItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert(
      'sub_items',
      {
        'hotkey_id': item['hotkey_id'],
        'name': item['name'],
        'price': item['price'],
        'stock': item['stock'] ?? 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSubItems(int hotkeyId) async {
    final db = await database;
    return await db.query(
      'sub_items',
      where: 'hotkey_id = ?',
      whereArgs: [hotkeyId],
    );
  }

  Future<Map<String, dynamic>?> getSubItem(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'sub_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateSubItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    return await db.update(
      'sub_items',
      {
        'name': item['name'],
        'price': item['price'],
        'stock': item['stock'],
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubItem(int id) async {
    final db = await database;
    return await db.delete(
      'sub_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Stock Management


  Future<bool> hasEnoughStock(int id, int requestedQuantity) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'sub_items',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      int currentStock = result.first['stock'] ?? 0;
      return currentStock >= requestedQuantity;
    }
    return false;
  }

Future<int?> getSubItemStock(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'sub_items',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [id],
    );

    return result.isNotEmpty ? result.first['stock'] as int? : null;
  }

  // Search and Filter Operations
  Future<List<Map<String, dynamic>>> searchHotkeys(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'hotkeys',
      where: 'hotkey LIKE ? OR item LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    for (var hotkey in results) {
      final subItems = await getSubItems(hotkey['id']);
      hotkey['subItems'] = subItems;
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> searchSubItems(String query) async {
    final db = await database;
    return await db.query(
      'sub_items',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Batch Operations
  Future<void> batchUpdateStock(List<Map<String, dynamic>> updates) async {
    final db = await database;
    final batch = db.batch();

    for (var update in updates) {
      batch.update(
        'sub_items',
        {'stock': update['new_stock']},
        where: 'id = ?',
        whereArgs: [update['id']],
      );
    }

    await batch.commit();
  }
 Future<void> updateSubItemStock(int id, int quantity, {bool isIncrease = false}) async {
    final db = await database;
    
    final List<Map<String, dynamic>> result = await db.query(
      'sub_items',
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      int currentStock = result.first['stock'] ?? 0;
      int newStock = isIncrease ? currentStock + quantity : currentStock - quantity;
      
      // Ensure stock doesn't go below 0
      newStock = newStock < 0 ? 0 : newStock;

      await db.update(
        'sub_items',
        {'stock': newStock},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
  // Database Maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('sub_items');
      await txn.delete('hotkeys');
    });
  }
  Future<void> updateSubItemStockByName(String name, int quantity, {bool isIncrease = false}) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'sub_items',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (result.isNotEmpty) {
      int currentStock = result.first['stock'] ?? 0;
      int newStock = isIncrease ? currentStock + quantity : currentStock - quantity;

      // Ensure stock doesn't go below 0
      newStock = newStock < 0 ? 0 : newStock;

      await db.update(
        'sub_items',
        {'stock': newStock},
        where: 'name = ?',
        whereArgs: [name],
      );
    } else {
      print('No sub-item found with name: $name');
    }
}

}