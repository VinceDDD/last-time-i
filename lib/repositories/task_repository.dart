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
  ///
  /// `createdAt` and `updatedAt` default to now if the caller did not set
  /// them, so the timestamps documented in the data model are never NULL.
  Future<TaskItem> insertTask(TaskItem task) async {
    final now = DateTime.now();
    final toInsert = task.copyWith(
      createdAt: task.createdAt ?? now,
      updatedAt: task.updatedAt ?? now,
    );
    final db = await _appDatabase.database;
    final id = await db.insert('tasks', toInsert.toMap());
    return toInsert.copyWith(id: id);
  }

  /// Saves changes to an existing task and stamps `updatedAt`.
  Future<void> updateTask(TaskItem task) async {
    final db = await _appDatabase.database;
    await db.update(
      'tasks',
      task.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Permanently removes the task with the given id.
  Future<void> deleteTask(int id) async {
    final db = await _appDatabase.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
