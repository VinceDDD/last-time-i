import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:last_time_i/database/app_database.dart';
import 'package:last_time_i/models/task_item.dart';
import 'package:last_time_i/repositories/task_repository.dart';
import 'package:last_time_i/screens/home_screen.dart';

void main() {
  late AppDatabase testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    testDb = AppDatabase.forTest('home_screen_test.db');
  });

  setUp(() async {
    final db = await testDb.database;
    await db.delete('tasks');
  });

  tearDown(() async {
    await testDb.close();
  });

  /// Pumps the home screen and lets its database future finish loading.
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: TaskRepository(database: testDb)),
      ),
    );
    // Real async database I/O needs a little time under the test clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state when there are no tasks',
      (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.text('ADD ITEM'), findsOneWidget);
  });

  testWidgets('lists tasks with their days-ago labels',
      (WidgetTester tester) async {
    final repo = TaskRepository(database: testDb);
    await tester.runAsync(() async {
      final now = DateTime.now();
      await repo.insertTask(
        TaskItem(
          name: 'Change air filter',
          lastCompletedAt: now.subtract(const Duration(days: 47)),
        ),
      );
      await repo.insertTask(
        TaskItem(name: 'Call Mum', lastCompletedAt: now),
      );
    });

    await pumpHome(tester);

    expect(find.text('Change air filter'), findsOneWidget);
    expect(find.text('Call Mum'), findsOneWidget);
    expect(find.text('47 days ago'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Nothing here yet.'), findsNothing);
  });

  testWidgets('tapping MARK DONE TODAY resets the label to Today',
      (WidgetTester tester) async {
    final repo = TaskRepository(database: testDb);
    await tester.runAsync(() async {
      await repo.insertTask(
        TaskItem(
          name: 'Clean bathroom',
          lastCompletedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      );
    });

    await pumpHome(tester);
    expect(find.text('8 days ago'), findsOneWidget);

    await tester.tap(find.text('MARK DONE TODAY'));
    // Phase 1: let the real database write complete.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    // Phase 2: flush the continuation so the screen starts its reload read.
    await tester.pump();
    // Phase 3: let that reload read complete too.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    // Phase 4: rebuild with the fresh data (spinner is gone, settles now).
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('8 days ago'), findsNothing);
  });
}
