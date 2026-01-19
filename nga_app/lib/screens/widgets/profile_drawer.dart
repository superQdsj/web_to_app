import 'package:flutter/material.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';

import '../../src/auth/nga_cookie_store.dart';
import '../login_webview_sheet.dart';

/// Right-side drawer displaying user profile and login status.
///
/// Contains login status card, login/logout buttons, and user information.
class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  Future<void> _openLogin() async {
    // Close drawer first
    Navigator.of(context).pop();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const LoginWebViewSheet(),
    );

    if (!mounted) return;

    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功。')),
      );
    }
  }

  Future<void> _logout() async {
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
            child: const Text('登出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    NgaCookieStore.setCookie('');
    await NgaCookieStore.clearStorage();
    await WebviewCookieManager().clearCookies();

    if (!mounted) return;

    // Close drawer
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已登出。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _StatusCard(theme: theme),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _openLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('登录'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('登出'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '提示：未登录时无法加载论坛和帖子内容。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: NgaCookieStore.cookie,
            builder: (context, value, _) {
              final loggedIn = value.trim().isNotEmpty;
              return CircleAvatar(
                radius: 40,
                backgroundColor: loggedIn
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  loggedIn ? Icons.person : Icons.person_outline,
                  size: 40,
                  color: loggedIn
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            '个人中心',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: NgaCookieStore.cookie,
      builder: (context, value, _) {
        final loggedIn = value.trim().isNotEmpty;
        final label = loggedIn ? '已登录' : '未登录';
        final color = loggedIn
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;
        final cookieLength = value.trim().length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest,
              ],
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(
                  loggedIn ? Icons.verified_user : Icons.person_outline,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loggedIn ? 'Cookie 长度：$cookieLength' : '请先完成登录。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
