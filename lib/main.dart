import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

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
