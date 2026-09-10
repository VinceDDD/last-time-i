import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:last_time_i/database/app_database.dart';
import 'package:last_time_i/models/task_item.dart';
import 'package:last_time_i/repositories/task_repository.dart';
import 'package:last_time_i/services/task_service.dart';
import 'package:last_time_i/utils/date_formatter.dart';

void main() {
  late AppDatabase testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    testDb = AppDatabase.forTest('task_service_test.db');
  });

  setUp(() async {
    final db = await testDb.database;
    await db.delete('tasks');
  });

  tearDown(() async {
    await testDb.close();
  });

  test('markDoneToday sets lastCompletedAt to today and persists it',
      () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);
    final created = await repo.insertTask(
      TaskItem(
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      ),
    );

    final updated = await service.markDoneToday(created);

    // The returned copy carries today's date.
    expect(formatDate(updated.lastCompletedAt), formatDate(DateTime.now()));
    // And the change is really in the database.
    final all = await repo.getAllTasks();
    expect(all.length, 1);
    expect(formatDate(all.first.lastCompletedAt), formatDate(DateTime.now()));
  });
}
