import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:last_time_i/database/app_database.dart';
import 'package:last_time_i/repositories/task_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('a v1 database upgrades to v2 and keeps its data', () async {
    // The database file that AppDatabase.forTest('migration_test.db') opens.
    final path = p.join(
      await databaseFactory.getDatabasesPath(),
      'migration_test.db',
    );
    // Start from a clean file, so the test is repeatable.
    await databaseFactory.deleteDatabase(path);

    // 1. Build a database with the OLD v1 schema and put a row in it,
    //    exactly as v0.1.0 would have.
    final oldDb = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              last_completed_at TEXT NOT NULL,
              created_at TEXT,
              updated_at TEXT
            )
          ''');
        },
      ),
    );
    await oldDb.insert('tasks', {
      'name': 'Old task',
      'last_completed_at': '2026-07-14',
    });
    await oldDb.close();

    // 2. Open the same file through the app: the version-2 upgrade runs
    //    and adds the interval_days column without losing the row.
    final db = AppDatabase.forTest('migration_test.db');
    final repo = TaskRepository(database: db);
    final all = await repo.getAllTasks();

    expect(all.length, 1);
    expect(all.first.name, 'Old task');
    expect(all.first.lastCompletedAt, DateTime(2026, 7, 14));
    // The new column defaults to NULL for pre-existing rows.
    expect(all.first.intervalDays, isNull);

    await db.close();
  });
}
