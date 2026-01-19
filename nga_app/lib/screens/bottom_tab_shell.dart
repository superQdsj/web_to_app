import 'package:flutter/material.dart';

import 'forum_screen.dart';
import 'profile_screen.dart';

class BottomTabShell extends StatefulWidget {
  const BottomTabShell({super.key});

  @override
  State<BottomTabShell> createState() => _BottomTabShellState();
}

class _BottomTabShellState extends State<BottomTabShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    ForumScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: '论坛',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '个人',
          ),
        ],
      ),
    );
  }
}
