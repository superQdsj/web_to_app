import 'package:flutter/material.dart';

import 'widgets/avatar_button.dart';
import 'widgets/menu_button.dart';
import 'widgets/menu_drawer.dart';
import 'widgets/profile_drawer.dart';
import 'forum_screen.dart';

/// Main home screen with drawer navigation.
///
/// Replaces the bottom tab navigation with:
/// - Left drawer (MenuDrawer) for multi-function menu
/// - Right drawer (ProfileDrawer) for user profile
/// - AppBar with menu button (left) and avatar button (right)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openMenuDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _openProfileDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: MenuButton(onPressed: _openMenuDrawer),
        title: const Text('NGA Forum'),
        actions: [AvatarButton(onPressed: _openProfileDrawer)],
      ),
      drawer: const MenuDrawer(),
      endDrawer: const ProfileDrawer(),
      body: const ForumContent(),
    );
  }
}
