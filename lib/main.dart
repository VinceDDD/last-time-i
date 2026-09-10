import 'package:flutter/material.dart';

import 'screens/add_task_screen.dart';

void main() {
  runApp(const LastTimeIApp());
}

/// Root widget of the application.
class LastTimeIApp extends StatelessWidget {
  const LastTimeIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last Time I',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Placeholder home: shows the app name and a button to add a task.
/// The real task list arrives in Stage 4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Last Time I...'),
      ),
      body: const Center(
        child: Text(
          'Last Time I...',
          style: TextStyle(fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
