import 'dart:ui';
import 'package:flutter/material.dart';
import '../../src/nga_forum_store.dart';

/// A forum board representation.
class ForumBoard {
  final String name;
  final int fid;

  const ForumBoard(this.name, this.fid);
}

/// 版块分类数据
class _ForumCategories {
  const _ForumCategories._();

  static const wowBoards = [
    ForumBoard('艾泽拉斯议事厅', 7),
    ForumBoard('职业讨论区', 181),
    ForumBoard('冒险心得', 218),
    ForumBoard('镶金玫瑰', 254),
  ];

  static const gameBoards = [
    ForumBoard('游戏综合讨论', 414),
    ForumBoard('英雄联盟', -152678),
    ForumBoard('绝地求生', 568),
    ForumBoard('怪物猎人', 489),
  ];

  static const chatBoards = [
    ForumBoard('网事杂谈', -7),
    ForumBoard('晴风村', -7955747),
    ForumBoard('大时代', 706),
    ForumBoard('漩涡书院', 524),
  ];

  static const blizzardBoards = [
    ForumBoard('守望先锋', 459),
    ForumBoard('炉石传说', 422),
    ForumBoard('暗黑破坏神3', 318),
    ForumBoard('风暴英雄', 431),
  ];
}

/// A premium, redesigned left-side drawer for forum navigation and shortcuts.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Drawer(
      width: size.width * 0.82,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // Background layers for "Liquid Glass" effect
          Positioned.fill(
            child: Container(
              color: colorScheme.surface.withValues(alpha: 0.6),
            ),
          ),
          // Subtle glow spots
          Positioned(
            top: -100,
            right: -50,
            child: _GlowSpot(color: colorScheme.primary.withValues(alpha: 0.15), size: 300),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: _GlowSpot(color: colorScheme.secondary.withValues(alpha: 0.1), size: 400),
          ),
          // Backdrop Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface.withValues(alpha: 0.7),
                      colorScheme.surface.withValues(alpha: 0.4),
                    ],
                  ),
                  border: Border(
                    right: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      const SizedBox(height: 10),
                      _buildQuickActionsGrid(context),
                      const SizedBox(height: 32),
                      _buildSectionLabel(context, 'DISCOVER'),
                      const SizedBox(height: 12),
                      _buildForumCategory(
                        context,
                        icon: Icons.auto_awesome_rounded,
                        title: '魔兽世界',
                        boards: _ForumCategories.wowBoards,
                      ),
                      _buildForumCategory(
                        context,
                        icon: Icons.sports_esports_rounded,
                        title: '游戏专版',
                        boards: _ForumCategories.gameBoards,
                      ),
                      _buildForumCategory(
                        context,
                        icon: Icons.chat_bubble_outline_rounded,
                        title: '网事杂谈',
                        boards: _ForumCategories.chatBoards,
                      ),
                      _buildForumCategory(
                        context,
                        icon: Icons.shield_rounded,
                        title: '暴雪游戏',
                        boards: _ForumCategories.blizzardBoards,
                      ),
                      const SizedBox(height: 40),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.explore_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NGA Forum',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '精英玩家社区',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildActionCard(context, Icons.bookmark_rounded, '收藏', Colors.orange, '收藏功能开发中')),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(context, Icons.history_rounded, '历史', Colors.blue, '历史功能开发中')),
        const SizedBox(width: 12),
        Expanded(child: _buildActionCard(context, Icons.mail_rounded, '消息', Colors.purple, '消息功能开发中')),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label, Color accentColor, String tooltip) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tooltip), duration: const Duration(seconds: 1)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildForumCategory(BuildContext context, {required IconData icon, required String title, required List<ForumBoard> boards}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary.withValues(alpha: 0.8), size: 20),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: boards.map((board) => _buildBoardItem(context, board)).toList(),
        ),
      ),
    );
  }

  Widget _buildBoardItem(BuildContext context, ForumBoard board) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<int?>(
      valueListenable: NgaForumStore.activeFid,
      builder: (context, activeFid, _) {
        final isActive = activeFid == board.fid;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                NgaForumStore.setActiveFid(board.fid);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isActive ? 4 : 0,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: isActive ? 12 : 0),
                    Expanded(
                      child: Text(
                        board.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isActive)
                      Icon(Icons.check_circle_rounded, size: 14, color: colorScheme.primary)
                    else
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.person_outline_rounded, size: 20, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '未登录',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '点击开启完整体验',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置功能开发中'), duration: Duration(seconds: 1)),
              );
            },
            icon: Icon(Icons.settings_outlined, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _GlowSpot extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowSpot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size / 2,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }
}
