import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../utils/date_formatter.dart';

/// One row in the home list: the task name and how long ago it was done.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  /// The task to display.
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.name),
      subtitle: Text(daysAgoLabel(task.lastCompletedAt)),
      // Stage 5 adds the "Mark done today" action here.
    );
  }
}
