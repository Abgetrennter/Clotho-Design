import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'sqlite_schema.dart';

class SqliteDatabase {
  SqliteDatabase._(this._database);

  final sqlite3.Database _database;

  sqlite3.Database get rawDatabase => _database;

  static SqliteDatabase openInMemory() {
    final database = sqlite3.sqlite3.openInMemory();
    final wrapper = SqliteDatabase._(database);
    wrapper._initialize();
    return wrapper;
  }

  static SqliteDatabase openFile(String path) {
    final database = sqlite3.sqlite3.open(path);
    final wrapper = SqliteDatabase._(database);
    wrapper._initialize();
    return wrapper;
  }

  void close() {
    _database.dispose();
  }

  T transaction<T>(T Function(sqlite3.Database db) action) {
    _database.execute('BEGIN');
    try {
      final result = action(_database);
      _database.execute('COMMIT');
      return result;
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  void _initialize() {
    _database.execute('PRAGMA foreign_keys = ON;');
    for (final statement in SqliteSchema.v1Statements) {
      _database.execute(statement);
    }
  }
}
