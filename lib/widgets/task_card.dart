import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../utils/date_formatter.dart';

/// One row in the home list: the task name, how long ago it was done,
/// and a button to mark it done today.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onMarkDoneToday,
  });

  /// The task to display.
  final TaskItem task;

  /// Called when the user taps "MARK DONE TODAY".
  final VoidCallback onMarkDoneToday;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.name),
      subtitle: Text(daysAgoLabel(task.lastCompletedAt)),
      trailing: TextButton(
        onPressed: onMarkDoneToday,
        child: const Text('MARK DONE TODAY'),
      ),
    );
  }
}
