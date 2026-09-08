import '../database/app_database.dart';
import '../models/task_item.dart';

/// The only place in the app that reads and writes tasks in the database.
/// Screens and services go through this class, never to SQLite directly.
class TaskRepository {
  TaskRepository({AppDatabase? database})
      : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  /// All tasks, in the order they were added.
  Future<List<TaskItem>> getAllTasks() async {
    final db = await _appDatabase.database;
    final rows = await db.query('tasks', orderBy: 'id ASC');
    return rows.map(TaskItem.fromMap).toList();
  }

  /// Saves a new task and returns it with its assigned id.
  Future<TaskItem> insertTask(TaskItem task) async {
    final db = await _appDatabase.database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  /// Saves changes to an existing task.
  Future<void> updateTask(TaskItem task) async {
    final db = await _appDatabase.database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Permanently removes the task with the given id.
  Future<void> deleteTask(int id) async {
    final db = await _appDatabase.database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
