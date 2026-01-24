import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../src/nga_forum_store.dart';
import '../../src/model/forum_category.dart';
import '../../src/services/forum_category_service.dart';

/// Grid-based accordion menu drawer following design from menu_drawer_3.
/// Features expandable categories with 2-column (main) and 3-column (sub) grids.
class MenuDrawerGrid extends StatefulWidget {
  const MenuDrawerGrid({super.key});

  @override
  State<MenuDrawerGrid> createState() => _MenuDrawerGridState();
}

class _MenuDrawerGridState extends State<MenuDrawerGrid> {
  late Future<List<ForumCategory>> _categoriesFuture;
  final Set<String> _expandedCategories = {};

  // Design colors from menu_drawer_3
  static const Color _primaryColor = Color(0xFF3E5076);
  static const Color _primaryLightColor = Color(0xFF5C7099);
  static const Color _accentColor = Color(0xFFF5A623);
  static const Color _backgroundLight = Color(0xFFFFF0CF);
  static const Color _surfaceLight = Color(0xFFF2E6C9);
  static const Color _cardLight = Color(0xFFFAF4E3);
  static const Color _textMain = Color(0xFF2C3E50);
  static const Color _textSub = Color(0xFF64748B);

  // Class icon colors for WoW professions
  static const Map<String, Color> _classColors = {
    'monk': Color(0xFFE0F2F1),
    'death_knight': Color(0xFFFFEBEE),
    'warrior': Color(0xFFE3F2FD),
    'mage': Color(0xFFF3E5F5),
    'priest': Color(0xFFFFF8E1),
    'shaman': Color(0xFFE1F5FE),
    'druid': Color(0xFFF1F8E9),
    'hunter': Color(0xFFFFF3E0),
    'paladin': Color(0xFFFFF8E1),
    'warlock': Color(0xFFEFEBE9),
    'rogue': Color(0xFFECEFF1),
    'demon_hunter': Color(0xFFE8EAF6),
    'evoker': Color(0xFFFBE9E7),
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
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      width: size.width * 0.85,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // Background with gradient (no blur for performance)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? const Color(0xFF2C2C2E) : _surfaceLight)
                        .withValues(alpha: 0.98),
                    (isDark ? const Color(0xFF1C1C1E) : _backgroundLight)
                        .withValues(alpha: 0.98),
                  ],
                ),
                border: Border(
                  right: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.1,
                    ),
                    width: 0.5,
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
                          child: CircularProgressIndicator(
                            color: _primaryColor,
                          ),
                        );
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
                                  color: theme.colorScheme.error,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '加载失败',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final categories = snapshot.data ?? [];

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          const SizedBox(height: 8),
                          ...categories.map(
                            (category) =>
                                _buildCategorySection(context, category),
                          ),
                          const SizedBox(height: 100),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryColor, _primaryLightColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NGA 论坛',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _textMain,
                  ),
                ),
                Text(
                  '精英玩家社区',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : _textSub,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Search button
          _buildSearchButton(context),
        ],
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('搜索功能开发中'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.search_rounded, color: _accentColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, ForumCategory category) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpanded = _expandedCategories.contains(category.id);
    final icon = ForumCategoryService.getIcon(category.icon);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Category header (always visible, expandable)
        Material(
          color: (isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(category.id);
                } else {
                  _expandedCategories.add(category.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryColor.withValues(alpha: 0.8),
                          _primaryLightColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Category name
                  Expanded(
                    child: Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _textMain,
                      ),
                    ),
                  ),
                  // Expand/collapse arrow
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : _textSub,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Expandable content
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: _buildSubcategoriesGrid(context, category),
        ),
      ],
    );
  }

  Widget _buildSubcategoriesGrid(BuildContext context, ForumCategory category) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: category.subcategories.asMap().entries.map((entry) {
          final index = entry.key;
          final subcategory = entry.value;
          final isFirst = index == 0;
          // First subcategory uses 2 columns, others use 3 columns
          final columnCount = isFirst ? 2 : 3;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subcategory label
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
                child: Text(
                  subcategory.name,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Grid of boards
              _buildBoardGrid(context, subcategory.boards, columnCount),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoardGrid(
    BuildContext context,
    List<ForumBoard> boards,
    int columnCount,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: columnCount == 2 ? 1.4 : 1.1,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final board = boards[index];
        final isLarge = columnCount == 2;
        return _buildBoardCard(context, board, isLarge);
      },
    );
  }

  Widget _buildBoardCard(BuildContext context, ForumBoard board, bool isLarge) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<int?>(
      valueListenable: NgaForumStore.activeFid,
      builder: (context, activeFid, _) {
        final isActive = activeFid == board.fid;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF2C2C2E) : _cardLight).withValues(
              alpha: isActive ? 0.95 : 0.85,
            ),
            borderRadius: BorderRadius.circular(isLarge ? 14 : 12),
            border: Border.all(
              color: isActive
                  ? _primaryColor.withValues(alpha: 0.3)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.5)),
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
              borderRadius: BorderRadius.circular(isLarge ? 14 : 12),
              child: Padding(
                padding: EdgeInsets.all(isLarge ? 12 : 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    _buildBoardIcon(context, board),
                    const SizedBox(height: 6),
                    // Board name
                    Expanded(
                      child: Center(
                        child: Text(
                          board.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: isLarge ? 13 : 11,
                            color: isDark
                                ? Colors.white
                                : _textMain.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if board has a valid icon URL from JSON
    final iconUrl = board.icon;
    final hasValidIconUrl =
        iconUrl != null &&
        iconUrl.isNotEmpty &&
        (iconUrl.startsWith('http://') || iconUrl.startsWith('https://'));

    if (hasValidIconUrl) {
      // Use network image from JSON data
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.5)),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: CachedNetworkImage(
            imageUrl: iconUrl,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const SizedBox(width: 32, height: 32),
            errorWidget: (context, url, error) {
              // Fallback to icon if image fails to load
              final (fallbackIcon, bgColor, iconColor) = _getBoardIconData(
                board,
              );
              return _buildFallbackIcon(
                fallbackIcon,
                bgColor,
                iconColor,
                isDark,
              );
            },
          ),
        ),
      );
    }

    // Fallback to hardcoded icons based on profession/class name
    final (icon, bgColor, iconColor) = _getBoardIconData(board);
    return _buildFallbackIcon(icon, bgColor, iconColor, isDark);
  }

  Widget _buildFallbackIcon(
    IconData icon,
    Color bgColor,
    Color iconColor,
    bool isDark,
  ) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5)),
          width: 1,
        ),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }

  (IconData, Color, Color) _getBoardIconData(ForumBoard board) {
    final name = board.name;
    final lowerName = name.toLowerCase();

    if (lowerName.contains('五晨寺') || lowerName.contains('武僧')) {
      return (
        Icons.self_improvement_rounded,
        _classColors['monk']!,
        _classIconColors['monk']!,
      );
    }
    if (lowerName.contains('黑锋') || lowerName.contains('死亡骑士')) {
      return (
        Icons.coronavirus_rounded,
        _classColors['death_knight']!,
        _classIconColors['death_knight']!,
      );
    }
    if (lowerName.contains('铁血') || lowerName.contains('战士')) {
      return (
        Icons.shield_rounded,
        _classColors['warrior']!,
        _classIconColors['warrior']!,
      );
    }
    if (lowerName.contains('魔法') || lowerName.contains('法师')) {
      return (
        Icons.auto_fix_high_rounded,
        _classColors['mage']!,
        _classIconColors['mage']!,
      );
    }
    if (lowerName.contains('信仰') || lowerName.contains('牧师')) {
      return (
        Icons.health_and_safety_rounded,
        _classColors['priest']!,
        _classIconColors['priest']!,
      );
    }
    if (lowerName.contains('风暴') || lowerName.contains('萨满')) {
      return (
        Icons.flash_on_rounded,
        _classColors['shaman']!,
        _classIconColors['shaman']!,
      );
    }
    if (lowerName.contains('翡翠') || lowerName.contains('德鲁伊')) {
      return (
        Icons.eco_rounded,
        _classColors['druid']!,
        _classIconColors['druid']!,
      );
    }
    if (lowerName.contains('猎手') || lowerName.contains('猎人')) {
      return (
        Icons.pets_rounded,
        _classColors['hunter']!,
        _classIconColors['hunter']!,
      );
    }
    if (lowerName.contains('圣光') || lowerName.contains('圣骑士')) {
      return (
        Icons.shield_moon_rounded,
        _classColors['paladin']!,
        _classIconColors['paladin']!,
      );
    }
    if (lowerName.contains('恶魔') && lowerName.contains('术士')) {
      return (
        Icons.cloud_rounded,
        _classColors['warlock']!,
        _classIconColors['warlock']!,
      );
    }
    if (lowerName.contains('暗影') || lowerName.contains('盗贼')) {
      return (
        Icons.visibility_off_rounded,
        _classColors['rogue']!,
        _classIconColors['rogue']!,
      );
    }
    if (lowerName.contains('伊利达雷') || lowerName.contains('恶魔猎手')) {
      return (
        Icons.flash_off_rounded,
        _classColors['demon_hunter']!,
        _classIconColors['demon_hunter']!,
      );
    }
    if (lowerName.contains('巨龙') || lowerName.contains('唤魔师')) {
      return (
        Icons.auto_awesome_rounded,
        _classColors['evoker']!,
        _classIconColors['evoker']!,
      );
    }

    // Default folder icon
    return (
      Icons.folder_rounded,
      const Color(0xFFF5F5F5),
      const Color(0xFF9E9E9E),
    );
  }
}
