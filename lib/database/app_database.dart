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

  /// Bump this when the schema changes, and add a migration step in
  /// [_onUpgrade] so existing installs are upgraded, not recreated.
  static const _dbVersion = 2;

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
      onUpgrade: _onUpgrade,
    );
  }

  /// Runs once when the database file is first created (fresh install).
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        last_completed_at TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        interval_days INTEGER
      )
    ''');
  }

  /// Runs when an existing database has an older schema version.
  ///
  /// Each new version adds one step here; old installs are migrated
  /// forward step by step, keeping their data.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 -> v2: add the optional target interval column.
      await db.execute('ALTER TABLE tasks ADD COLUMN interval_days INTEGER');
    }
  }

  /// Closes the connection and forgets it, so the next access
  /// opens the file again (used by tests to simulate an app restart).
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
