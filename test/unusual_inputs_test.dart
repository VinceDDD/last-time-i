import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:last_time_i/database/app_database.dart';
import 'package:last_time_i/models/task_item.dart';
import 'package:last_time_i/repositories/task_repository.dart';
import 'package:last_time_i/screens/add_task_screen.dart';
import 'package:last_time_i/utils/date_formatter.dart';

void main() {
  late AppDatabase testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    testDb = AppDatabase.forTest('unusual_inputs_test.db');
  });

  setUp(() async {
    final db = await testDb.database;
    await db.delete('tasks');
  });

  tearDown(() async {
    await testDb.close();
  });

  /// Inserts [name] with [lastCompletedAt], reads it back, and asserts
  /// the table still contains exactly one row.
  Future<TaskItem> roundTrip(String name, DateTime lastCompletedAt) async {
    final repo = TaskRepository(database: testDb);
    await repo.insertTask(
      TaskItem(name: name, lastCompletedAt: lastCompletedAt),
    );
    final all = await repo.getAllTasks();
    expect(all.length, 1);
    return all.first;
  }

  group('unusual names survive a database round-trip', () {
    test('single-character name', () async {
      final saved = await roundTrip('A', DateTime(2026, 9, 1));
      expect(saved.name, 'A');
    });

    test('Chinese characters', () async {
      final saved = await roundTrip('换空气滤芯', DateTime(2026, 9, 1));
      expect(saved.name, '换空气滤芯');
    });

    test('emoji', () async {
      final saved = await roundTrip('Clean 🧽', DateTime(2026, 9, 1));
      expect(saved.name, 'Clean 🧽');
    });

    test('150-character name', () async {
      final longName = 'x' * 150;
      final saved = await roundTrip(longName, DateTime(2026, 9, 1));
      expect(saved.name, longName);
    });
  });

  group('unusual dates survive a database round-trip', () {
    test('31 December', () async {
      final saved = await roundTrip('New Year prep', DateTime(2025, 12, 31));
      expect(saved.lastCompletedAt, DateTime(2025, 12, 31));
    });

    test('leap day 29 February', () async {
      final saved = await roundTrip('Leap day thing', DateTime(2028, 2, 29));
      expect(saved.lastCompletedAt, DateTime(2028, 2, 29));
    });

    test("today's date", () async {
      final now = DateTime.now();
      final saved = await roundTrip('Done today', now);
      expect(formatDate(saved.lastCompletedAt), formatDate(now));
    });
  });

  testWidgets('add screen saves a Chinese + emoji name',
      (WidgetTester tester) async {
    // Host screen pushes AddTaskScreen so popping is safe.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddTaskScreen(
                      repository: TaskRepository(database: testDb),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '换空气滤芯 🧽');
    await tester.tap(find.text('SAVE'));

    // Let the real database write complete, then let the screen pop.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    List<TaskItem>? all;
    await tester.runAsync(() async {
      all = await TaskRepository(database: testDb).getAllTasks();
    });
    expect(all, isNotNull);
    expect(all!.length, 1);
    expect(all!.first.name, '换空气滤芯 🧽');
  });
}
