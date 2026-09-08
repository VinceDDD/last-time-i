import 'package:flutter/material.dart';

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

/// Stage 1 placeholder: the app only needs to launch and display
/// "Last Time I...". Real screens come in later stages.
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
    );
  }
}
