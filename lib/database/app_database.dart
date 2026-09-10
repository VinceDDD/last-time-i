import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite database: opens the file, defines the schema,
/// and hands out the [Database] instance to the repository layer.
///
/// Only one AppDatabase object should normally exist, so the app uses
/// the singleton [AppDatabase.instance].
class AppDatabase {
  AppDatabase._({String? dbName}) : _dbName = dbName ?? 'last_time_i.db';

  /// The single shared instance used by the app.
  static final AppDatabase instance = AppDatabase._();

  /// A separate instance for tests, so each test file uses its own
  /// database file and parallel test files never lock each other out.
  factory AppDatabase.forTest(String name) => AppDatabase._(dbName: name);

  final String _dbName;

  static const _dbVersion = 1;

  /// The open database connection, or null before the first open.
  Database? _database;

  /// Returns the open database, opening it on first use.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    final db = await _open();
    _database = db;
    return db;
  }

  /// Opens (or creates) the database file and returns the connection.
  Future<Database> _open() async {
    // The folder where the OS stores app databases.
    final basePath = await getDatabasesPath();
    // Join the folder and file name using the correct separator.
    final path = p.join(basePath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Runs once when the database file is first created.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        last_completed_at TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  /// Closes the connection and forgets it, so the next access
  /// opens the file again (used by tests to simulate an app restart).
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
