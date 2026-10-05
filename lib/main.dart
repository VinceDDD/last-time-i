import 'package:flutter/material.dart';

import 'repositories/task_repository.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise notifications once at startup so permission is requested
  // before the user creates their first task.
  final scheduler = NotificationService();
  try {
    await scheduler.init();
  } catch (_) {
    // Notifications are best-effort: the app works without them.
  }

  runApp(LastTimeIApp(scheduler: scheduler));
}

/// Root widget of the application.
class LastTimeIApp extends StatelessWidget {
  const LastTimeIApp({super.key, this.repository, this.scheduler});

  /// Allows tests to supply their own repository (and database).
  final TaskRepository? repository;

  /// Swappable notification scheduler; tests inject a fake.
  final ReminderScheduler? scheduler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last Time I',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: HomeScreen(repository: repository, scheduler: scheduler),
    );
  }
}
