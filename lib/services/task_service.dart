import '../models/task_item.dart';
import '../repositories/task_repository.dart';

/// Business logic for tasks, sitting between the UI and the repository.
///
/// Screens call services; services call the repository. This keeps
/// rules like "mark done today" in one testable place.
class TaskService {
  TaskService({TaskRepository? repository})
      : _repository = repository ?? TaskRepository();

  final TaskRepository _repository;

  /// Marks [task] as completed today and persists the change.
  ///
  /// Returns the updated copy (with `lastCompletedAt` = today) so the
  /// caller can use it without re-reading the database.
  Future<TaskItem> markDoneToday(TaskItem task) async {
    final updated = task.copyWith(
      lastCompletedAt: DateTime.now(),
    );
    await _repository.updateTask(updated);
    return updated;
  }

  /// Saves changes (rename, new date) for [task] and persists them.
  Future<TaskItem> updateTask(TaskItem task) async {
    await _repository.updateTask(task);
    return task;
  }

  /// Permanently removes the task with the given [id].
  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
  }
}
