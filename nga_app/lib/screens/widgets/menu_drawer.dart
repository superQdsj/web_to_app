import 'dart:ui';
import 'package:flutter/material.dart';
import '../../src/nga_forum_store.dart';
import '../../src/model/forum_category.dart';
import '../../src/services/forum_category_service.dart';

/// A premium, redesigned left-side drawer for forum navigation and shortcuts.
class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  late Future<List<ForumCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ForumCategoryService.loadCategories();
  }

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
                  child: FutureBuilder<List<ForumCategory>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  '加载失败',
                                  style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.error),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final categories = snapshot.data ?? [];

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 10),
                          _buildQuickActionsGrid(context),
                          const SizedBox(height: 32),
                          _buildSectionLabel(context, 'DISCOVER'),
                          const SizedBox(height: 12),
                          ...categories.map((category) => _buildForumCategory(context, category)),
                          const SizedBox(height: 40),
                        ],
                      );
                    },
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

  Widget _buildForumCategory(BuildContext context, ForumCategory category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = ForumCategoryService.getIcon(category.icon);

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
            category.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: _buildSubcategories(context, category),
        ),
      ),
    );
  }

  List<Widget> _buildSubcategories(BuildContext context, ForumCategory category) {
    if (category.subcategories.length == 1 && category.subcategories.first.name == '主版块') {
      return category.subcategories.first.boards.map((board) => _buildBoardItem(context, board)).toList();
    }

    return category.subcategories.map((sub) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            sub.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 8),
          children: sub.boards.map((board) => _buildBoardItem(context, board)).toList(),
        ),
      );
    }).toList();
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
