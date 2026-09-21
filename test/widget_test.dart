import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:last_time_i/database/app_database.dart';
import 'package:last_time_i/main.dart';
import 'package:last_time_i/repositories/task_repository.dart';

void main() {
  late AppDatabase testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    testDb = AppDatabase.forTest('widget_test.db');
  });

  setUp(() async {
    // Open the database before the fake-async test body starts, exactly
    // like every other test file: the FFI SQLite isolate must be running
    // before the widget pumps.
    final db = await testDb.database;
    await db.delete('tasks');
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('app launches, shows the title, and renders the empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      LastTimeIApp(repository: TaskRepository(database: testDb)),
    );
    // Real async database I/O needs a little time under the test clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last Time I...'), findsOneWidget);
    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
