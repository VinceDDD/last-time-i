import 'package:flutter_test/flutter_test.dart';

import 'package:last_time_i/models/task_category.dart';
import 'package:last_time_i/models/task_item.dart';
import 'package:last_time_i/utils/task_grouping.dart';

void main() {
  TaskItem task(String name, {TaskCategory? category}) => TaskItem(
    name: name,
    lastCompletedAt: DateTime(2026, 9, 1),
    category: category,
  );

  group('groupTasks', () {
    test('groups tasks by category in fixed enum order', () {
      final sections = groupTasks([
        task('B', category: TaskCategory.car),
        task('A', category: TaskCategory.home),
      ]);

      expect(sections.length, 2);
      // Home comes before Car in the enum, regardless of insertion order.
      expect(sections[0].category, TaskCategory.home);
      expect(sections[0].tasks.single.name, 'A');
      expect(sections[1].category, TaskCategory.car);
      expect(sections[1].tasks.single.name, 'B');
    });

    test('uncategorized tasks come last', () {
      final sections = groupTasks([
        task('No category'),
        task('Home one', category: TaskCategory.home),
      ]);

      expect(sections.length, 2);
      expect(sections[0].category, TaskCategory.home);
      expect(sections[1].category, isNull);
      expect(sections[1].tasks.single.name, 'No category');
    });

    test('categories with no tasks are omitted', () {
      final sections = groupTasks([
        task('Pets one', category: TaskCategory.pets),
      ]);

      expect(sections.length, 1);
      expect(sections.single.category, TaskCategory.pets);
    });

    test('tasks keep their insertion order inside a section', () {
      final sections = groupTasks([
        task('First', category: TaskCategory.home),
        task('Second', category: TaskCategory.home),
      ]);

      expect(sections.single.tasks.map((t) => t.name), ['First', 'Second']);
    });

    test('empty input gives no sections', () {
      expect(groupTasks([]), isEmpty);
    });
  });

  group('sortByReminder', () {
    DateTime now() => DateTime(2026, 9, 29);

    TaskItem item(String name, int daysAgo, {int? intervalDays}) => TaskItem(
      name: name,
      lastCompletedAt: now().subtract(Duration(days: daysAgo)),
      intervalDays: intervalDays,
    );

    test('overdue first, then due today, then everything else', () {
      final sorted = sortByReminder([
        item('due today', 90, intervalDays: 90),
        item('normal', 0),
        item('overdue', 100, intervalDays: 90),
      ], now: now());

      expect(sorted.map((t) => t.name), ['overdue', 'due today', 'normal']);
    });

    test('keeps the original order inside each priority group', () {
      // All three are overdue; their relative order must not change.
      final sorted = sortByReminder([
        item('A', 95, intervalDays: 90),
        item('B', 92, intervalDays: 90),
        item('C', 99, intervalDays: 90),
      ], now: now());

      expect(sorted.map((t) => t.name), ['A', 'B', 'C']);
    });

    test('empty input stays empty', () {
      expect(sortByReminder([]), isEmpty);
    });
  });
}
