import '../models/task_item.dart';
import '../repositories/task_repository.dart';

/// Business logic for tasks, sitting between the UI and the repository.
///
/// Screens call services; services call the repository. This keeps
/// rules like "mark done today" and input validation in one testable place.
class TaskService {
  TaskService({TaskRepository? repository})
    : _repository = repository ?? TaskRepository();

  final TaskRepository _repository;

  /// Returns an error message for an invalid name, or null.
  ///
  /// Also usable directly as a `TextFormField` validator.
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name cannot be blank';
    }
    return null;
  }

  /// Returns an error message for an invalid date, or null.
  static String? validateDate(DateTime lastCompletedAt) {
    if (lastCompletedAt.isAfter(DateTime.now())) {
      return 'Future dates are not allowed';
    }
    return null;
  }

  /// Returns the first error for an invalid (name, date) pair, or null.
  ///
  /// These are the product rules from PRODUCT_SPEC: the name must not be
  /// blank and the date must not be in the future.
  static String? validate(String name, DateTime lastCompletedAt) {
    final nameError = validateName(name);
    if (nameError != null) {
      return nameError;
    }
    return validateDate(lastCompletedAt);
  }

  /// Validates and creates a task, returning it with its assigned id.
  Future<TaskItem> addTask(String name, DateTime lastCompletedAt) async {
    final error = validate(name, lastCompletedAt);
    if (error != null) {
      throw ArgumentError(error);
    }
    return _repository.insertTask(
      TaskItem(name: name.trim(), lastCompletedAt: lastCompletedAt),
    );
  }

  /// Marks [task] as completed today and persists the change.
  ///
  /// Returns the updated copy (with `lastCompletedAt` = today) so the
  /// caller can use it without re-reading the database.
  Future<TaskItem> markDoneToday(TaskItem task) async {
    final updated = task.copyWith(lastCompletedAt: DateTime.now());
    await _repository.updateTask(updated);
    return updated;
  }

  /// Validates and saves changes (rename, new date) for [task].
  Future<TaskItem> updateTask(TaskItem task) async {
    final error = validate(task.name, task.lastCompletedAt);
    if (error != null) {
      throw ArgumentError(error);
    }
    await _repository.updateTask(task);
    return task;
  }

  /// Permanently removes the task with the given [id].
  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
  }
}
