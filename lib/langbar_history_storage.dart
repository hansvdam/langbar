import 'package:flutter/widgets.dart';
import 'ui/langfield/langbar_states.dart';
import 'utils/utils.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Removed duplicate initDB() function - use HistoryProvider.getInstance() instead

const String tableHistory = 'history';
const String columnId = '_id';
const String columnText = 'text';
const String columnNavUri = 'navuri';
const String columnTime = 'timestamp'; // seconds since epoch
const columnIsHuman = 'ishuman';

HistoryMessage historyMessagefromMap(Map map) {
  return HistoryMessage(
      text: map[columnText] as String,
      isHuman: map[columnIsHuman] == 1,
      navUri: map[columnNavUri] as String?,
      time: DateTime.fromMillisecondsSinceEpoch(map[columnTime] as int));
}

extension HistoryMessageExtension on HistoryMessage {
  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      columnNavUri: navUri,
      columnText: text,
      columnIsHuman: isHuman ? 1 : 0,
      columnTime: time.millisecondsSinceEpoch
    };
    return map;
  }
}

class HistoryProvider {
  Database? db;
  static HistoryProvider? _instance;
  bool _isOperationInProgress = false;
  
  // Singleton pattern to prevent multiple database connections
  static HistoryProvider getInstance() {
    _instance ??= HistoryProvider._internal();
    return _instance!;
  }
  
  HistoryProvider._internal();

  Future open() async {
    if (db?.isOpen == true) return; // Already open
    
    WidgetsFlutterBinding.ensureInitialized();
    db = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'langbar_database.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return db.execute(
          'CREATE TABLE $tableHistory($columnId INTEGER PRIMARY KEY autoincrement, $columnNavUri TEXT, $columnText TEXT not null, $columnIsHuman INTEGER, $columnTime INTEGER)',
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    // await clear();
  }

  Future<void> _waitForPreviousOperation() async {
    while (_isOperationInProgress) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  insert(HistoryMessage historyMessage) async {
    await _waitForPreviousOperation();
    _isOperationInProgress = true;
    
    try {
      await open(); // Ensure database is open
      await db?.transaction((txn) async {
        var result = await txn.insert(tableHistory, historyMessage.toMap());
        langbarLogger.d('inserted: $result');
      });
    } catch (e) {
      langbarLogger.e('Database insert error: $e');
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<List<HistoryMessage>> getHistoryItems() async {
    await _waitForPreviousOperation();
    _isOperationInProgress = true;
    
    try {
      await open(); // Ensure database is open
      final List<Map> maps = await db?.query(tableHistory, columns: [
            columnId,
            columnNavUri,
            columnText,
            columnIsHuman,
            columnTime
          ]) ??
          [];
      if (maps.isNotEmpty) {
        List<HistoryMessage> map2 =
            maps.map((map) => historyMessagefromMap(map)).toList();
        return map2;
      }
      return [];
    } catch (e) {
      langbarLogger.e('Database query error: $e');
      return [];
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<int> delete(int id) async {
    await _waitForPreviousOperation();
    _isOperationInProgress = true;
    
    try {
      await open(); // Ensure database is open
      int result = 0;
      await db?.transaction((txn) async {
        result = await txn.delete(tableHistory, where: '$columnId = ?', whereArgs: [id]);
      });
      return result;
    } catch (e) {
      langbarLogger.e('Database delete error: $e');
      return 0;
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<int> clear() async {
    await _waitForPreviousOperation();
    _isOperationInProgress = true;
    
    try {
      await open(); // Ensure database is open
      int result = 0;
      await db?.transaction((txn) async {
        result = await txn.delete(tableHistory);
      });
      return result;
    } catch (e) {
      langbarLogger.e('Database clear error: $e');
      return 0;
    } finally {
      _isOperationInProgress = false;
    }
  }

  // Future<int> update(Todo todo) async {
  //   return await db.update(tableTodo, todo.toMap(),
  //       where: '$columnId = ?', whereArgs: [todo.id]);
  // }

  Future close() async {
    try {
      await db?.close();
      db = null;
    } catch (e) {
      langbarLogger.e('Database close error: $e');
    }
  }
}

// // Create a Dog and add it to the dogs table
// var fido = const Dog(
//   id: 0,
//   name: 'Fido',
//   age: 35,
// );
//
// await insertDog(fido);
