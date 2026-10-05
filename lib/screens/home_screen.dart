import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../utils/date_formatter.dart';
import '../utils/task_grouping.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';

/// Home screen: shows all tasks grouped by category, with how long ago
/// each was completed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository, this.scheduler});

  /// Allows tests to supply their own repository (and database).
  final TaskRepository? repository;

  /// Swappable notification scheduler; tests inject a fake.
  final ReminderScheduler? scheduler;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final TaskRepository _repository = widget.repository ?? TaskRepository();
  late final TaskService _service = TaskService(repository: _repository);
  late final ReminderScheduler _scheduler =
      widget.scheduler ?? NotificationService();

  /// The future that loads the task list; replaced on every reload.
  late Future<List<TaskItem>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    // Watch app lifecycle events so the list refreshes when the app
    // returns to the foreground (e.g. after an overnight sleep).
    WidgetsBinding.instance.addObserver(this);
    _tasksFuture = _loadAndSchedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever the app moves between foreground and background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  /// Re-reads the list from the database and rebuilds.
  void _reload() {
    setState(() {
      _tasksFuture = _loadAndSchedule();
    });
  }

  /// Loads the list, then re-schedules due-date notifications to match.
  ///
  /// Every change (add, edit, mark done, delete) flows back through this
  /// method, so the scheduled notifications always mirror the database.
  Future<List<TaskItem>> _loadAndSchedule() async {
    final tasks = await _repository.getAllTasks();
    try {
      await _scheduler.rescheduleAll(tasks);
    } catch (_) {
      // Notifications are best-effort: a permission problem must not
      // break the list itself.
    }
    return tasks;
  }

  /// Opens the add screen, then refreshes the list on return.
  Future<void> _openAddScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTaskScreen(repository: _repository)),
    );
    _reload();
  }

  /// Opens the edit screen, then refreshes the list on return.
  Future<void> _openEditScreen(TaskItem task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditTaskScreen(task: task, repository: _repository),
      ),
    );
    _reload();
  }

  /// Marks the task as done today, then refreshes the list.
  Future<void> _markDoneToday(TaskItem task) async {
    await _service.markDoneToday(task);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Last Time I...')),
      body: FutureBuilder<List<TaskItem>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          final tasks = snapshot.data ?? const <TaskItem>[];
          if (tasks.isEmpty) {
            return _EmptyState(onAdd: _openAddScreen);
          }
          return _buildTaskList(tasks);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// The grouped list: a reminder banner on top, then one section
  /// header per category followed by its cards (overdue first).
  Widget _buildTaskList(List<TaskItem> tasks) {
    final now = DateTime.now();
    // Overdue/due-today tasks rise to the top of their sections.
    final sections = groupTasks(sortByReminder(tasks, now: now));
    final overdueCount = tasks
        .where(
          (t) => isOverdue(
            t.lastCompletedAt,
            intervalDays: t.intervalDays,
            now: now,
          ),
        )
        .length;
    final dueTodayCount = tasks
        .where(
          (t) => isDueToday(
            t.lastCompletedAt,
            intervalDays: t.intervalDays,
            now: now,
          ),
        )
        .length;
    return ListView(
      children: [
        if (overdueCount + dueTodayCount > 0)
          _OverdueBanner(
            overdueCount: overdueCount,
            dueTodayCount: dueTodayCount,
          ),
        for (final section in sections) ...[
          _SectionHeader(section: section),
          for (final task in section.tasks)
            TaskCard(
              task: task,
              onMarkDoneToday: () => _markDoneToday(task),
              onTap: () => _openEditScreen(task),
            ),
        ],
      ],
    );
  }
}

/// The reminder strip shown above the list: how many tasks are past
/// their target interval and how many fall due today.
class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({
    required this.overdueCount,
    required this.dueTodayCount,
  });

  final int overdueCount;
  final int dueTodayCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final parts = <String>[
      if (overdueCount > 0)
        overdueCount == 1 ? '1 task overdue' : '$overdueCount tasks overdue',
      if (dueTodayCount > 0)
        dueTodayCount == 1 ? '1 due today' : '$dueTodayCount due today',
    ];
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: colors.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                parts.join(' · '),
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A category header: its icon and name (or "Uncategorized").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final TaskSection section;

  @override
  Widget build(BuildContext context) {
    final category = section.category;
    final label = category?.label ?? 'Uncategorized';
    final icon = category?.icon ?? Icons.label_outline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

/// Shown when there are no tasks yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nothing here yet.'),
          const Text('Add something you\'d like to keep track of.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAdd, child: const Text('ADD ITEM')),
        ],
      ),
    );
  }
}
