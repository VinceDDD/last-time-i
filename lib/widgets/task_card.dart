import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../utils/date_formatter.dart';

/// One row in the home list: the task name, its status (how long ago it
/// was done, or how overdue it is), and a button to mark it done today.
/// Tapping the row edits the task.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onMarkDoneToday,
    this.onTap,
  });

  /// The task to display.
  final TaskItem task;

  /// Called when the user taps "MARK DONE TODAY".
  final VoidCallback onMarkDoneToday;

  /// Called when the row is tapped (opens the edit screen).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = isOverdue(
      task.lastCompletedAt,
      intervalDays: task.intervalDays,
    );
    return ListTile(
      onTap: onTap,
      title: Text(task.name),
      subtitle: Text(
        statusLabel(task.lastCompletedAt, intervalDays: task.intervalDays),
        style: overdue ? const TextStyle(color: Colors.red) : null,
      ),
      trailing: TextButton(
        onPressed: onMarkDoneToday,
        child: const Text('MARK DONE TODAY'),
      ),
    );
  }
}
