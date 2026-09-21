import 'package:flutter/material.dart';

import 'repositories/task_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LastTimeIApp());
}

/// Root widget of the application.
class LastTimeIApp extends StatelessWidget {
  const LastTimeIApp({super.key, this.repository});

  /// Allows tests to supply their own repository (and database).
  final TaskRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last Time I',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: HomeScreen(repository: repository),
    );
  }
}
