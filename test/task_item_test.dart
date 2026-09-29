import 'package:flutter_test/flutter_test.dart';

import 'package:last_time_i/models/task_category.dart';
import 'package:last_time_i/models/task_item.dart';

void main() {
  group('TaskItem equality', () {
    test('identical field values compare equal and share a hash code', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      );
      final b = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different name compares unequal', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      );

      expect(a == a.copyWith(name: 'Clean bathroom'), isFalse);
    });

    test('a different date compares unequal', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      );

      expect(a == a.copyWith(lastCompletedAt: DateTime(2026, 7, 15)), isFalse);
    });

    test('a different interval compares unequal', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      );

      expect(a == a.copyWith(intervalDays: 90), isFalse);
    });

    test('a different category compares unequal', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
      );

      expect(a == a.copyWith(category: TaskCategory.home), isFalse);
    });
  });

  group('TaskItem copyWith and the sentinel', () {
    test('passing null to copyWith clears the interval', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
        intervalDays: 90,
      );

      expect(a.copyWith(intervalDays: null).intervalDays, isNull);
    });

    test('not passing intervalDays keeps the old value', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
        intervalDays: 90,
      );

      expect(a.copyWith(name: 'New name').intervalDays, 90);
    });

    test('passing null to copyWith clears the category', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
        category: TaskCategory.home,
      );

      expect(a.copyWith(category: null).category, isNull);
    });

    test('not passing category keeps the old value', () {
      final a = TaskItem(
        id: 1,
        name: 'Change air filter',
        lastCompletedAt: DateTime(2026, 7, 14),
        category: TaskCategory.home,
      );

      expect(a.copyWith(name: 'New name').category, TaskCategory.home);
    });
  });
}
