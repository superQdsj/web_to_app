import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';

import '../../src/auth/nga_cookie_store.dart';
import '../../src/auth/nga_user_store.dart';
import '../login_webview_sheet.dart';

/// A premium, redesigned right-side drawer for user profile management.
class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  Future<void> _openLogin() async {
    Navigator.of(context).pop();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LoginWebViewSheet(),
    );

    if (!mounted) return;

    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 登录成功'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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

    NgaCookieStore.setCookie('');
    await NgaCookieStore.clearStorage();
    NgaUserStore.clear();
    await WebviewCookieManager().clearCookies();

    if (!mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已退出登录'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // Glass Background Effect
          Positioned.fill(
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.85),
                    border: Border(left: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1)),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const Divider(height: 1, indent: 20, endIndent: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    children: [
                      _buildSectionTitle(context, '账户'),
                      _buildMenuItem(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: '个人详情',
                        onTap: () {
                          Navigator.of(context).pop();
                          // TODO: 添加个人详情页.

                        },
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: NgaCookieStore.cookie,
                        builder: (context, cookie, _) {
                          final isLoggedIn = cookie.isNotEmpty;
                          if (isLoggedIn) {
                            return _buildMenuItem(
                              context,
                              icon: Icons.logout_rounded,
                              title: '登出帐号',
                              color: colorScheme.error,
                              onTap: _logout,
                            );
                          } else {
                            return _buildMenuItem(
                              context,
                              icon: Icons.login_rounded,
                              title: '登录社区',
                              color: colorScheme.primary,
                              onTap: _openLogin,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, '通用'),
                      _buildMenuItem(
                        context,
                        icon: Icons.settings_outlined,
                        title: '软件设置',
                        onTap: () {}, // Placeholder
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: '关于 NGA',
                        onTap: () {}, // Placeholder
                      ),
                    ],
                  ),
                ),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<NgaUserInfo?>(
      valueListenable: NgaUserStore.user,
      builder: (context, user, _) {
        final isLoggedIn = user != null;

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 30),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with glow/ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isLoggedIn ? colorScheme.primary : colorScheme.outline).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                    child: user?.avatarUrl == null
                        ? Icon(
                            isLoggedIn ? Icons.person_rounded : Icons.person_add_rounded,
                            size: 32,
                            color: colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // User Info
              Text(
                isLoggedIn ? user.username : '欢迎来到 NGA',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold,
                  letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                isLoggedIn ? 'UID: ${user.uid}' : '登录以查看更多内容',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    final theme = Theme.of(context);
    final itemColor = color ?? theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: itemColor.withValues(alpha: 0.8), size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(color: itemColor, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Image.network(
            'https://img.ngacn.cc/base/common/logo.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.forum_rounded,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
