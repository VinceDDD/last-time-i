import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:last_time_i/database/app_database.dart';
import 'package:last_time_i/models/task_category.dart';
import 'package:last_time_i/models/task_item.dart';
import 'package:last_time_i/repositories/task_repository.dart';
import 'package:last_time_i/screens/home_screen.dart';

/// A repository whose getAllTasks never completes, so the home screen
/// stays in its loading state.
class _PendingRepository extends TaskRepository {
  _PendingRepository(AppDatabase db) : super(database: db);

  @override
  Future<List<TaskItem>> getAllTasks() => Completer<List<TaskItem>>().future;
}

/// A repository whose getAllTasks always fails, so the home screen
/// shows its error state.
class _ThrowingRepository extends TaskRepository {
  _ThrowingRepository(AppDatabase db) : super(database: db);

  @override
  Future<List<TaskItem>> getAllTasks() async {
    throw Exception('database exploded');
  }
}

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

  testWidgets('shows the empty state when there are no tasks', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.text('ADD ITEM'), findsOneWidget);
  });

  testWidgets('lists tasks with their days-ago labels', (
    WidgetTester tester,
  ) async {
    final repo = TaskRepository(database: testDb);
    await tester.runAsync(() async {
      final now = DateTime.now();
      await repo.insertTask(
        TaskItem(
          name: 'Change air filter',
          lastCompletedAt: now.subtract(const Duration(days: 47)),
        ),
      );
      await repo.insertTask(TaskItem(name: 'Call Mum', lastCompletedAt: now));
    });

    await pumpHome(tester);

    expect(find.text('Change air filter'), findsOneWidget);
    expect(find.text('Call Mum'), findsOneWidget);
    expect(find.text('47 days ago'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Nothing here yet.'), findsNothing);
    // No intervals -> nothing overdue -> no reminder banner.
    expect(find.textContaining('overdue'), findsNothing);
  });

  testWidgets('groups tasks by category with section headers', (
    WidgetTester tester,
  ) async {
    final repo = TaskRepository(database: testDb);
    await tester.runAsync(() async {
      final now = DateTime.now();
      await repo.insertTask(
        TaskItem(
          name: 'Change air filter',
          lastCompletedAt: now,
          category: TaskCategory.home,
        ),
      );
      await repo.insertTask(
        TaskItem(
          name: 'Clean bathroom',
          lastCompletedAt: now,
          category: TaskCategory.home,
        ),
      );
      await repo.insertTask(
        TaskItem(
          name: 'Wash car',
          lastCompletedAt: now,
          category: TaskCategory.car,
        ),
      );
      await repo.insertTask(TaskItem(name: 'Call Mum', lastCompletedAt: now));
    });

    await pumpHome(tester);

    // One header per present category, plus Uncategorized for the rest.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Car'), findsOneWidget);
    expect(find.text('Uncategorized'), findsOneWidget);

    // All tasks render under their sections.
    expect(find.text('Change air filter'), findsOneWidget);
    expect(find.text('Clean bathroom'), findsOneWidget);
    expect(find.text('Wash car'), findsOneWidget);
    expect(find.text('Call Mum'), findsOneWidget);
  });

  testWidgets('tapping MARK DONE TODAY resets the label to Today', (
    WidgetTester tester,
  ) async {
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

  testWidgets('shows a loading indicator while the list loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: _PendingRepository(testDb))),
    );
    // No runAsync or pumpAndSettle here: the future never completes, so the
    // spinner stays on screen — that is exactly what we are asserting.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error message when loading fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: _ThrowingRepository(testDb))),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('renders a very long task name without crashing', (
    WidgetTester tester,
  ) async {
    final longName = 'x' * 150;
    final repo = TaskRepository(database: testDb);
    await tester.runAsync(() async {
      await repo.insertTask(
        TaskItem(name: longName, lastCompletedAt: DateTime.now()),
      );
    });

    await pumpHome(tester);

    expect(find.text(longName), findsOneWidget);
  });

  testWidgets('reloads the list when the app resumes from the background', (
    WidgetTester tester,
  ) async {
    final repo = TaskRepository(database: testDb);
    await pumpHome(tester);
    expect(find.text('Nothing here yet.'), findsOneWidget);

    // Simulate the app going to the background, during which a task is added.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.runAsync(() async {
      await repo.insertTask(
        TaskItem(name: 'Added while paused', lastCompletedAt: DateTime.now()),
      );
    });

    // Bring the app back to the foreground: the observer reloads the list.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Added while paused'), findsOneWidget);
  });

  testWidgets('shows a reminder banner for overdue and due-today tasks', (
    WidgetTester tester,
  ) async {
    final repo = TaskRepository(database: testDb);
    await tester.runAsync(() async {
      final now = DateTime.now();
      await repo.insertTask(
        TaskItem(
          name: 'Overdue task',
          lastCompletedAt: now.subtract(const Duration(days: 100)),
          intervalDays: 90,
        ),
      );
      await repo.insertTask(
        TaskItem(
          name: 'Due today task',
          lastCompletedAt: now.subtract(const Duration(days: 90)),
          intervalDays: 90,
        ),
      );
    });

    await pumpHome(tester);

    expect(find.text('1 task overdue · 1 due today'), findsOneWidget);
  });

  testWidgets('sorts overdue tasks to the top of their section', (
    WidgetTester tester,
  ) async {
    final repo = TaskRepository(database: testDb);
    await tester.runAsync(() async {
      final now = DateTime.now();
      // Same category; the NOT-due task is inserted first.
      await repo.insertTask(
        TaskItem(
          name: 'Not due',
          lastCompletedAt: now.subtract(const Duration(days: 5)),
          intervalDays: 90,
          category: TaskCategory.home,
        ),
      );
      await repo.insertTask(
        TaskItem(
          name: 'Overdue one',
          lastCompletedAt: now.subtract(const Duration(days: 100)),
          intervalDays: 90,
          category: TaskCategory.home,
        ),
      );
    });

    await pumpHome(tester);

    // The overdue card must render above the not-due card.
    final overdueY = tester.getTopLeft(find.text('Overdue one')).dy;
    final notDueY = tester.getTopLeft(find.text('Not due')).dy;
    expect(overdueY, lessThan(notDueY));
  });
}
