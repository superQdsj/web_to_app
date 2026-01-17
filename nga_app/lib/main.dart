import 'package:flutter/material.dart';

import 'screens/forum_screen.dart';

void main() {
  runApp(const NgaApp());
}

class NgaApp extends StatelessWidget {
  const NgaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NGA Forum',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ForumScreen(),
    );
  }
}
