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

  test('markDoneToday sets lastCompletedAt to today and persists it', () async {
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

  test('updateTask persists a rename and a new date', () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);
    final created = await repo.insertTask(
      TaskItem(
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      ),
    );

    final updated = await service.updateTask(
      created.copyWith(
        name: 'Change air filter + vent',
        lastCompletedAt: DateTime(2026, 8, 1),
      ),
    );

    expect(updated.name, 'Change air filter + vent');

    final all = await repo.getAllTasks();
    expect(all.length, 1);
    expect(all.first.name, 'Change air filter + vent');
    expect(all.first.lastCompletedAt, DateTime(2026, 8, 1));
  });

  test('deleteTask removes the task', () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);
    final created = await repo.insertTask(
      TaskItem(name: 'Clean bathroom', lastCompletedAt: DateTime(2026, 8, 30)),
    );

    await service.deleteTask(created.id!);

    expect(await repo.getAllTasks(), isEmpty);
  });

  test('addTask rejects a blank name and saves nothing', () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);

    expect(
      () => service.addTask('   ', DateTime(2026, 9, 1)),
      throwsArgumentError,
    );
    expect(await repo.getAllTasks(), isEmpty);
  });

  test('addTask rejects a future date and saves nothing', () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    expect(() => service.addTask('Plan ahead', tomorrow), throwsArgumentError);
    expect(await repo.getAllTasks(), isEmpty);
  });

  test('addTask saves a valid task and returns it with an id', () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);

    final saved = await service.addTask(
      'Change air filter',
      DateTime(2026, 9, 1),
    );

    expect(saved.id, isNotNull);
    expect(saved.name, 'Change air filter');

    final all = await repo.getAllTasks();
    expect(all.length, 1);
    expect(all.first.name, 'Change air filter');
  });

  test('addTask saves a task with an interval', () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);

    final saved = await service.addTask(
      'Change air filter',
      DateTime(2026, 9, 1),
      intervalDays: 90,
    );

    expect(saved.intervalDays, 90);
    final all = await repo.getAllTasks();
    expect(all.first.intervalDays, 90);
  });

  test('addTask rejects an interval of zero', () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);

    expect(
      () => service.addTask(
        'Change air filter',
        DateTime(2026, 9, 1),
        intervalDays: 0,
      ),
      throwsArgumentError,
    );
    expect(await repo.getAllTasks(), isEmpty);
  });

  test('updateTask can clear an interval', () async {
    final repo = TaskRepository(database: testDb);
    final service = TaskService(repository: repo);
    final created = await repo.insertTask(
      TaskItem(
        name: 'Water plants',
        lastCompletedAt: DateTime(2026, 9, 1),
        intervalDays: 30,
      ),
    );

    await service.updateTask(created.copyWith(intervalDays: null));

    final all = await repo.getAllTasks();
    expect(all.first.intervalDays, isNull);
  });
}
