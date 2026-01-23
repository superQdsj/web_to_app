import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';

import '../../src/auth/nga_cookie_store.dart';
import '../../src/auth/nga_user_store.dart';

/// Avatar button widget for the app bar.
///
/// Displays user avatar or a default icon based on login status.
/// Long-pressing the avatar when logged in triggers logout confirmation.
class AvatarButton extends StatefulWidget {
  const AvatarButton({super.key, required this.onPressed, this.onLogout});

  final VoidCallback onPressed;
  final VoidCallback? onLogout;

  @override
  State<AvatarButton> createState() => _AvatarButtonState();
}

class _AvatarButtonState extends State<AvatarButton> {
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认登出'),
        content: const Text('登出将清空本地 Cookie 和 WebView Cookie。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('登出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticFeedback.mediumImpact();

    NgaCookieStore.setCookie('');
    await NgaCookieStore.clearStorage();
    await NgaUserStore.clear();
    await WebviewCookieManager().clearCookies();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已退出登录'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<NgaUserInfo?>(
      valueListenable: NgaUserStore.user,
      builder: (context, user, _) {
        final avatarUrl = user?.avatarUrl;
        final hasAvatar = avatarUrl != null;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Tooltip(
            message: user?.username ?? '',
            child: MouseRegion(
              cursor: user != null && widget.onLogout != null
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                onTap: widget.onPressed,
                onLongPress: user != null && widget.onLogout != null
                    ? _handleLogout
                    : null,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: user != null
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  foregroundImage:
                      hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: !hasAvatar
                      ? Icon(
                          user != null ? Icons.person : Icons.person_outline,
                          size: 22,
                          color: user != null
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
