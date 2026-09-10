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
    // Dedicated database file, separate from other test files.
    testDb = AppDatabase.forTest('add_task_screen_test.db');
  });

  setUp(() async {
    final db = await testDb.database;
    await db.delete('tasks');
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('shows a validation error when the name is blank',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskScreen(repository: TaskRepository(database: testDb)),
      ),
    );

    await tester.tap(find.text('SAVE'));
    await tester.pump();

    expect(find.text('Name cannot be blank'), findsOneWidget);
  });

  testWidgets('defaults the date to today', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddTaskScreen(repository: TaskRepository(database: testDb)),
      ),
    );

    expect(find.text(formatDate(DateTime.now())), findsOneWidget);
  });

  testWidgets('saves a valid task to the database and pops with it',
      (WidgetTester tester) async {
    // Host screen that pushes AddTaskScreen and captures the popped result.
    TaskItem? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<TaskItem>(
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

    await tester.enterText(find.byType(TextFormField), 'Change air filter');
    await tester.tap(find.text('SAVE'));

    // The database insert is real async I/O; give it time to complete.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(popped, isNotNull);
    expect(popped!.name, 'Change air filter');

    List<TaskItem>? all;
    await tester.runAsync(() async {
      all = await TaskRepository(database: testDb).getAllTasks();
    });
    expect(all, isNotNull);
    expect(all!.length, 1);
    expect(all!.first.name, 'Change air filter');
  });
}
