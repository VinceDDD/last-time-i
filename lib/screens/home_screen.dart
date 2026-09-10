import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../repositories/task_repository.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';

/// Home screen: shows all tasks with how long ago each was completed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository});

  /// Allows tests to supply their own repository (and database).
  final TaskRepository? repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TaskRepository _repository =
      widget.repository ?? TaskRepository();

  /// The future that loads the task list; replaced on every reload.
  late Future<List<TaskItem>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _repository.getAllTasks();
  }

  /// Re-reads the list from the database and rebuilds.
  void _reload() {
    setState(() {
      _tasksFuture = _repository.getAllTasks();
    });
  }

  /// Opens the add screen, then refreshes the list on return.
  Future<void> _openAddScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
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
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) => TaskCard(task: tasks[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
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
          FilledButton(
            onPressed: onAdd,
            child: const Text('ADD ITEM'),
          ),
        ],
      ),
    );
  }
}
