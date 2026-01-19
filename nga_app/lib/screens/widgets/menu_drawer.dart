import 'package:flutter/material.dart';

/// Left-side drawer with multi-function menu items.
///
/// Contains navigation links to various features like favorites,
/// browsing history, settings, etc.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.dashboard_rounded,
                  size: 48,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  '多功能菜单',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _MenuTile(
            icon: Icons.bookmark_outline,
            title: '收藏夹',
            onTap: () => _showSnackBar(context, '收藏夹功能开发中'),
          ),
          _MenuTile(
            icon: Icons.history,
            title: '浏览历史',
            onTap: () => _showSnackBar(context, '浏览历史功能开发中'),
          ),
          _MenuTile(
            icon: Icons.forum_outlined,
            title: '我的帖子',
            onTap: () => _showSnackBar(context, '我的帖子功能开发中'),
          ),
          _MenuTile(
            icon: Icons.notifications_outlined,
            title: '消息通知',
            onTap: () => _showSnackBar(context, '消息通知功能开发中'),
          ),
          const Divider(),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: '设置',
            onTap: () => _showSnackBar(context, '设置功能开发中'),
          ),
          _MenuTile(
            icon: Icons.info_outline,
            title: '关于',
            onTap: () => _showSnackBar(context, '关于功能开发中'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    Navigator.of(context).pop(); // Close drawer first
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
