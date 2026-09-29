import '../models/task_category.dart';
import '../models/task_item.dart';
import 'date_formatter.dart';

/// One section of the grouped home list: a category (null for
/// uncategorized tasks) and the tasks that belong to it.
class TaskSection {
  const TaskSection({required this.category, required this.tasks});

  /// The section's category, or null for the "Uncategorized" section.
  final TaskCategory? category;

  /// The tasks in this section, in their original (insertion) order.
  final List<TaskItem> tasks;
}

/// Groups [tasks] into sections for the home list.
///
/// Categorized sections appear in the fixed enum order, then the
/// "Uncategorized" section last. Sections with no tasks are omitted.
List<TaskSection> groupTasks(List<TaskItem> tasks) {
  final sections = <TaskSection>[];

  for (final category in TaskCategory.values) {
    final inCategory = tasks
        .where((task) => task.category == category)
        .toList();
    if (inCategory.isNotEmpty) {
      sections.add(TaskSection(category: category, tasks: inCategory));
    }
  }

  final uncategorized = tasks.where((task) => task.category == null).toList();
  if (uncategorized.isNotEmpty) {
    sections.add(TaskSection(category: null, tasks: uncategorized));
  }

  return sections;
}

/// Sorts [tasks] for the home list by reminder priority:
/// overdue tasks first, then tasks due today, then everything else.
///
/// Within each priority group the original order is preserved.
/// [now] is injectable so tests can pin the "today" reference date.
List<TaskItem> sortByReminder(List<TaskItem> tasks, {DateTime? now}) {
  final reference = now ?? DateTime.now();

  int priority(TaskItem task) {
    if (isOverdue(
      task.lastCompletedAt,
      intervalDays: task.intervalDays,
      now: reference,
    )) {
      return 0;
    }
    if (isDueToday(
      task.lastCompletedAt,
      intervalDays: task.intervalDays,
      now: reference,
    )) {
      return 1;
    }
    return 2;
  }

  // List.sort is not guaranteed stable, so pair every task with its
  // original index and sort by (priority, index).
  final indexed = <(TaskItem, int)>[
    for (var i = 0; i < tasks.length; i++) (tasks[i], i),
  ];
  indexed.sort((a, b) {
    final byPriority = priority(a.$1).compareTo(priority(b.$1));
    return byPriority != 0 ? byPriority : a.$2.compareTo(b.$2);
  });
  return [for (final (task, _) in indexed) task];
}
