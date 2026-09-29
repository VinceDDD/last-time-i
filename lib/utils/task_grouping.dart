import '../models/task_category.dart';
import '../models/task_item.dart';

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
