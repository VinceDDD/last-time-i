import 'package:flutter_test/flutter_test.dart';

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
  });

  group('TaskItem copyWith and the interval sentinel', () {
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
  });
}
