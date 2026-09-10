import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:last_time_i/database/app_database.dart';
import 'package:last_time_i/models/task_item.dart';
import 'package:last_time_i/repositories/task_repository.dart';

void main() {
  late AppDatabase testDb;

  setUpAll(() {
    // Use the desktop (FFI) SQLite implementation so tests can run on the
    // host machine, exactly like the real database on an Android phone.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // A dedicated database file: parallel test files each use their own.
    testDb = AppDatabase.forTest('task_repository_test.db');
  });

  setUp(() async {
    // Start every test with an empty table.
    final db = await testDb.database;
    await db.delete('tasks');
  });

  tearDown(() async {
    // Close the connection so the next test opens a fresh one.
    await testDb.close();
  });

  test('insert returns the task with an id and it reads back correctly',
      () async {
    final repo = TaskRepository(database: testDb);

    final created = await repo.insertTask(
      TaskItem(
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      ),
    );

    expect(created.id, isNotNull);

    final all = await repo.getAllTasks();
    expect(all.length, 1);
    expect(all.first.id, created.id);
    expect(all.first.name, 'Change air filter');
    expect(all.first.lastCompletedAt, DateTime(2026, 7, 14));
  });

  test('update persists changes to an existing task', () async {
    final repo = TaskRepository(database: testDb);
    final created = await repo.insertTask(
      TaskItem(
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      ),
    );

    await repo.updateTask(created.copyWith(name: 'Change air filter + vent'));

    final all = await repo.getAllTasks();
    expect(all.length, 1);
    expect(all.first.name, 'Change air filter + vent');
    expect(all.first.lastCompletedAt, DateTime(2026, 7, 14));
  });

  test('delete removes the task', () async {
    final repo = TaskRepository(database: testDb);
    final created = await repo.insertTask(
      TaskItem(
        name: 'Clean bathroom',
        lastCompletedAt: DateTime(2026, 8, 30),
      ),
    );

    await repo.deleteTask(created.id!);

    final all = await repo.getAllTasks();
    expect(all, isEmpty);
  });

  test('data persists after the database is closed and reopened (restart)',
      () async {
    final repo = TaskRepository(database: testDb);
    await repo.insertTask(
      TaskItem(
        name: 'Call Mum',
        lastCompletedAt: DateTime(2026, 9, 6),
      ),
    );

    // Simulate an app restart: close the connection, then read again.
    await testDb.close();

    final repoAfterRestart = TaskRepository(database: testDb);
    final all = await repoAfterRestart.getAllTasks();
    expect(all.length, 1);
    expect(all.first.name, 'Call Mum');
  });
}
