import 'package:flutter/material.dart';

/// Menu button widget for the app bar.
///
/// Displays a hamburger menu icon to open the left drawer.
class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: '多功能菜单',
      onPressed: onPressed,
    );
  }
}
