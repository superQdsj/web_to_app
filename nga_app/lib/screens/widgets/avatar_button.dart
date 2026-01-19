import 'package:flutter/material.dart';

import '../../src/auth/nga_cookie_store.dart';

/// Avatar button widget for the app bar.
///
/// Displays user avatar or a default icon based on login status.
class AvatarButton extends StatelessWidget {
  const AvatarButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: NgaCookieStore.cookie,
      builder: (context, value, _) {
        final loggedIn = value.trim().isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: onPressed,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: loggedIn
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                loggedIn ? Icons.person : Icons.person_outline,
                size: 20,
                color: loggedIn
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
