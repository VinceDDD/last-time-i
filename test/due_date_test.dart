import 'package:flutter_test/flutter_test.dart';

import 'package:last_time_i/models/task_item.dart';
import 'package:last_time_i/utils/due_date.dart';

void main() {
  // Pinned reference date for shouldSchedule tests.
  final now = DateTime(2026, 10, 5);

  group('dueDate', () {
    test('is the last completion date plus the interval', () {
      final task = TaskItem(
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 9, 19),
        intervalDays: 7,
      );

      expect(dueDate(task), DateTime(2026, 9, 26));
    });

    test('rolls over month boundaries', () {
      final task = TaskItem(
        name: 'Water plants',
        lastCompletedAt: DateTime(2026, 9, 28),
        intervalDays: 7,
      );

      expect(dueDate(task), DateTime(2026, 10, 5));
    });

    test('rolls over year boundaries', () {
      final task = TaskItem(
        name: 'Water plants',
        lastCompletedAt: DateTime(2026, 12, 28),
        intervalDays: 7,
      );

      expect(dueDate(task), DateTime(2027, 1, 4));
    });

    test('tasks without an interval have no due date', () {
      final task = TaskItem(
        name: 'Call Mum',
        lastCompletedAt: DateTime(2026, 10, 5),
      );

      expect(dueDate(task), isNull);
    });
  });

  group('shouldSchedule', () {
    test('a future due date is scheduled', () {
      final task = TaskItem(
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 9, 19),
        intervalDays: 30, // due 19 October: in the future
      );

      expect(shouldSchedule(task, now: now), isTrue);
    });

    test('a task due today is not scheduled (banner covers it)', () {
      final task = TaskItem(
        name: 'Water plants',
        lastCompletedAt: DateTime(2026, 9, 28),
        intervalDays: 7, // due exactly 5 October: today
      );

      expect(shouldSchedule(task, now: now), isFalse);
    });

    test('a past due date is not scheduled (would fire immediately)', () {
      final task = TaskItem(
        name: 'Oil change',
        lastCompletedAt: DateTime(2026, 9, 19),
        intervalDays: 7, // due 26 September: already past
      );

      expect(shouldSchedule(task, now: now), isFalse);
    });

    test('tasks without an interval are never scheduled', () {
      final task = TaskItem(
        name: 'Call Mum',
        lastCompletedAt: DateTime(2026, 10, 1),
      );

      expect(shouldSchedule(task, now: now), isFalse);
    });
  });
}
