import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:last_time_i/database/app_database.dart';
import 'package:last_time_i/models/task_item.dart';
import 'package:last_time_i/repositories/task_repository.dart';
import 'package:last_time_i/screens/edit_task_screen.dart';

void main() {
  late AppDatabase testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    testDb = AppDatabase.forTest('edit_task_screen_test.db');
  });

  setUp(() async {
    final db = await testDb.database;
    await db.delete('tasks');
  });

  tearDown(() async {
    await testDb.close();
  });

  Future<TaskItem> seedTask({
    String name = 'Change air filter',
    DateTime? lastCompletedAt,
  }) async {
    return TaskRepository(database: testDb).insertTask(
      TaskItem(
        name: name,
        lastCompletedAt: lastCompletedAt ?? DateTime(2026, 7, 14),
      ),
    );
  }

  /// Pumps the edit screen directly (no navigation).
  Future<void> pumpEdit(WidgetTester tester, TaskItem task) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditTaskScreen(
          task: task,
          repository: TaskRepository(database: testDb),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Pumps a host screen that pushes the edit screen, so popping is safe.
  Future<void> pumpEditViaHost(WidgetTester tester, TaskItem task) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditTaskScreen(
                      task: task,
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
  }

  testWidgets('pre-fills the current name and date', (WidgetTester tester) async {
    TaskItem? task;
    await tester.runAsync(() async {
      task = await seedTask();
    });
    await pumpEdit(tester, task!);

    expect(find.text('Change air filter'), findsOneWidget);
    expect(find.text('2026-07-14'), findsOneWidget);
  });

  testWidgets('saving a rename persists to the database',
      (WidgetTester tester) async {
    TaskItem? task;
    await tester.runAsync(() async {
      task = await seedTask();
    });
    await pumpEditViaHost(tester, task!);

    await tester.enterText(
      find.byType(TextFormField),
      'Change air filter + vent',
    );
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
    expect(all!.first.name, 'Change air filter + vent');
  });

  testWidgets('cancel keeps the task, confirm deletes it',
      (WidgetTester tester) async {
    TaskItem? task;
    await tester.runAsync(() async {
      task = await seedTask(name: 'Clean bathroom');
    });
    await pumpEditViaHost(tester, task!);

    // Open the confirmation dialog, then cancel.
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    List<TaskItem>? afterCancel;
    await tester.runAsync(() async {
      afterCancel = await TaskRepository(database: testDb).getAllTasks();
    });
    expect(afterCancel, hasLength(1));

    // Open the dialog again, this time confirm the delete.
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('DELETE'),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    List<TaskItem>? afterDelete;
    await tester.runAsync(() async {
      afterDelete = await TaskRepository(database: testDb).getAllTasks();
    });
    expect(afterDelete, isEmpty);
  });
}
