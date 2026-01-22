import 'dart:ui';
import 'package:flutter/material.dart';
import '../../src/nga_forum_store.dart';
import '../../src/model/forum_category.dart';
import '../../src/services/forum_category_service.dart';

/// A premium, redesigned left-side drawer for forum navigation and shortcuts.
/// Follows the design from menu_drawer_2 with glass-morphism effect and card-based board list.
class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  late Future<List<ForumCategory>> _categoriesFuture;

  // Design colors from menu_drawer_2
  static const Color _primaryColor = Color(0xFF4B5C96);
  static const Color _primaryDarkColor = Color(0xFF6B7DB8);
  static const Color _backgroundLight = Color(0xFFFFF0CF);
  static const Color _surfaceLight = Color(0xFFFFFCF5);
  static const Color _textMain = Color(0xFF2C3E50);
  static const Color _textSub = Color(0xFF64748B);

  // Class icon colors for WoW professions
  static const Map<String, Color> _classColors = {
    'monk': Color(0xFFE0F2F1), // 武僧 - teal
    'death_knight': Color(0xFFFFEBEE), // 死亡骑士 - red
    'warrior': Color(0xFFE3F2FD), // 战士 - blue
    'mage': Color(0xFFF3E5F5), // 法师 - purple
    'priest': Color(0xFFFFF8E1), // 牧师 - yellow
    'shaman': Color(0xFFE1F5FE), // 萨满 - sky
    'druid': Color(0xFFF1F8E9), // 德鲁伊 - green
    'hunter': Color(0xFFFFF3E0), // 猎人 - orange
    'paladin': Color(0xFFFFF8E1), // 圣骑士 - yellow
    'warlock': Color(0xFFEFEBE9), // 术士 - brown
    'rogue': Color(0xFFECEFF1), // 盗贼 - grey
    'demon_hunter': Color(0xFFE8EAF6), // 恶魔猎手 - indigo
    'evoker': Color(0xFFFBE9E7), // 唤魔师 - coral
  };

  static const Map<String, Color> _classIconColors = {
    'monk': Color(0xFF00897B),
    'death_knight': Color(0xFFC62828),
    'warrior': Color(0xFF1565C0),
    'mage': Color(0xFF7B1FA2),
    'priest': Color(0xFFF9A825),
    'shaman': Color(0xFF0277BD),
    'druid': Color(0xFF388E3C),
    'hunter': Color(0xFFEF6C00),
    'paladin': Color(0xFFF9A825),
    'warlock': Color(0xFF5D4037),
    'rogue': Color(0xFF607D8B),
    'demon_hunter': Color(0xFF3949AB),
    'evoker': Color(0xFFBF360C),
  };

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
      width: size.width * 0.85,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // Background layers for glass-morphism effect
          Positioned.fill(
            child: Container(
              color: (theme.brightness == Brightness.light
                      ? _backgroundLight
                      : const Color(0xFF1C1C1E))
                  .withValues(alpha: 0.95),
            ),
          ),
          // Subtle glow spots
          Positioned(
            top: -50,
            right: -50,
            child: _GlowSpot(
              color: _primaryColor.withValues(alpha: 0.1),
              size: 200,
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: _GlowSpot(
              color: _primaryDarkColor.withValues(alpha: 0.08),
              size: 300,
            ),
          ),
          // Backdrop Blur for glass effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (theme.brightness == Brightness.light
                              ? _surfaceLight
                              : const Color(0xFF2C2C2E))
                          .withValues(alpha: 0.9),
                      (theme.brightness == Brightness.light
                              ? _backgroundLight
                              : const Color(0xFF1C1C1E))
                          .withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border(
                    right: BorderSide(
                      color: (theme.brightness == Brightness.light
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.1))
                          .withValues(alpha: 0.3),
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
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                          color: _primaryColor,
                        ));
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: colorScheme.error,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '加载失败',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.error,
                                  ),
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

                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            (theme.brightness == Brightness.light
                                    ? _surfaceLight
                                    : const Color(0xFF2C2C2E))
                                .withValues(alpha: 1),
                            (theme.brightness == Brightness.light
                                    ? _backgroundLight
                                    : const Color(0xFF1C1C1E))
                                .withValues(alpha: 1),
                          ],
                        ).createShader(bounds),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            const SizedBox(height: 8),
                            _buildQuickActionsGrid(context),
                            const SizedBox(height: 24),
                            ...categories.map((category) =>
                                _buildForumCategory(context, category)),
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _buildFooter(context),
              ],
            ),
          ),

          // Search FAB
          Positioned(
            bottom: 100,
            right: 16,
            child: _buildSearchFab(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _primaryDarkColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NGA 论坛',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : _textMain,
                    ),
                  ),
                  Text(
                    '精英玩家社区',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : _textSub,
                      letterSpacing: 3,
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
        Expanded(
          child: _buildActionCard(
            context,
            Icons.bookmark_rounded,
            '收藏',
            const Color(0xFFFF9800),
            '收藏功能开发中',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            Icons.history_rounded,
            '历史',
            const Color(0xFF2196F3),
            '历史功能开发中',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            context,
            Icons.mail_rounded,
            '消息',
            const Color(0xFF9C27B0),
            '消息功能开发中',
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label,
    Color accentColor,
    String tooltip,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 72,
      decoration: BoxDecoration(
        color: (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.6))
            .withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.5)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tooltip),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : _textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForumCategory(BuildContext context, ForumCategory category) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionLabel(context, category.name),
        const SizedBox(height: 12),
        ...category.subcategories.expand((sub) {
          return [
            if (sub.name != '主版块')
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
                child: Text(
                  sub.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ...sub.boards.map((board) => _buildBoardCard(context, board)),
          ];
        }),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : _textSub.withValues(alpha: 0.7),
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBoardCard(BuildContext context, ForumBoard board) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<int?>(
      valueListenable: NgaForumStore.activeFid,
      builder: (context, activeFid, _) {
        final isActive = activeFid == board.fid;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: (isDark
                    ? const Color(0xFF2C2C2E)
                    : _surfaceLight)
                .withValues(alpha: isActive ? 0.95 : 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? _primaryColor.withValues(alpha: 0.3)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.4)),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                NgaForumStore.setActiveFid(board.fid);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon container
                    _buildBoardIcon(context, board),
                    const SizedBox(width: 14),
                    // Board info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            board.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : _textMain,
                            ),
                          ),
                          if (board.info != null && board.info!.isNotEmpty)
                            Text(
                              board.info!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : _textSub,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Chevron
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: isActive
                          ? const EdgeInsets.only(left: 4)
                          : EdgeInsets.zero,
                      child: Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : Icons.chevron_right_rounded,
                        size: isActive ? 18 : 20,
                        color: isActive
                            ? _primaryColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : _textSub.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoardIcon(BuildContext context, ForumBoard board) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine icon and color based on board name or fid
    final (icon, bgColor, iconColor) = _getBoardIconData(board);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.5)),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
    );
  }

  (IconData, Color, Color) _getBoardIconData(ForumBoard board) {
    // Map board names to icons and colors based on WoW professions
    final name = board.name;
    final lowerName = name.toLowerCase();

    if (lowerName.contains('五晨寺') || lowerName.contains('武僧')) {
      return (
        Icons.self_improvement_rounded,
        _classColors['monk']!,
        _classIconColors['monk']!
      );
    }
    if (lowerName.contains('黑锋') || lowerName.contains('死亡骑士')) {
      return (
        Icons.coronavirus_rounded,
        _classColors['death_knight']!,
        _classIconColors['death_knight']!
      );
    }
    if (lowerName.contains('铁血') || lowerName.contains('战士')) {
      return (
        Icons.shield_rounded,
        _classColors['warrior']!,
        _classIconColors['warrior']!
      );
    }
    if (lowerName.contains('魔法') || lowerName.contains('法师')) {
      return (
        Icons.auto_fix_high_rounded,
        _classColors['mage']!,
        _classIconColors['mage']!
      );
    }
    if (lowerName.contains('信仰') || lowerName.contains('牧师')) {
      return (
        Icons.health_and_safety_rounded,
        _classColors['priest']!,
        _classIconColors['priest']!
      );
    }
    if (lowerName.contains('风暴') || lowerName.contains('萨满')) {
      return (
        Icons.flash_on_rounded,
        _classColors['shaman']!,
        _classIconColors['shaman']!
      );
    }
    if (lowerName.contains('翡翠') || lowerName.contains('德鲁伊')) {
      return (
        Icons.eco_rounded,
        _classColors['druid']!,
        _classIconColors['druid']!
      );
    }
    if (lowerName.contains('猎手') || lowerName.contains('猎人')) {
      return (
        Icons.pets_rounded,
        _classColors['hunter']!,
        _classIconColors['hunter']!
      );
    }
    if (lowerName.contains('圣光') || lowerName.contains('圣骑士')) {
      return (
        Icons.shield_moon_rounded,
        _classColors['paladin']!,
        _classIconColors['paladin']!
      );
    }
    if (lowerName.contains('恶魔') && lowerName.contains('术士')) {
      return (
        Icons.cloud_rounded,
        _classColors['warlock']!,
        _classIconColors['warlock']!
      );
    }
    if (lowerName.contains('暗影') || lowerName.contains('盗贼')) {
      return (
        Icons.visibility_off_rounded,
        _classColors['rogue']!,
        _classIconColors['rogue']!
      );
    }
    if (lowerName.contains('伊利达雷') || lowerName.contains('恶魔猎手')) {
      return (
        Icons.flash_off_rounded,
        _classColors['demon_hunter']!,
        _classIconColors['demon_hunter']!
      );
    }
    if (lowerName.contains('巨龙') || lowerName.contains('唤魔师')) {
      return (
        Icons.auto_awesome_rounded,
        _classColors['evoker']!,
        _classIconColors['evoker']!
      );
    }

    // Default folder icon
    return (
      Icons.folder_rounded,
      const Color(0xFFF5F5F5),
      const Color(0xFF9E9E9E),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? const Color(0xFF1C1C1E) : _backgroundLight)
                .withValues(alpha: 0),
            (isDark ? const Color(0xFF1C1C1E) : _backgroundLight)
                .withValues(alpha: 1),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor.withValues(alpha: 0.1), _primaryDarkColor.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: _primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '未登录',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _textMain,
                  ),
                ),
                Text(
                  '点击开启完整体验',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : _textSub,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设置功能开发中'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? Colors.white.withValues(alpha: 0.6) : _textSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFab(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('搜索功能开发中'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.search_rounded,
        size: 22,
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
            blurRadius: size / 3,
            spreadRadius: size / 6,
          ),
        ],
      ),
    );
  }
}
