import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_typography.dart';

/// NGA 论坛应用主题配置
///
/// 提供亮色和暗色两套主题，遵循 Material 3 设计规范
class NgaTheme {
  const NgaTheme._();

  /// 主品牌色 (用于生成 ColorScheme)
  static const Color _seedColor = Color(0xFF10273F);

  /// 亮色主题
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      // 覆盖部分颜色以匹配 NGA 风格
      surface: const Color(0xFFFFFCEE),
      onSurface: const Color(0xFF10273F),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: NgaTypography.lightTextTheme,

      // 扩展颜色
      extensions: const [NgaColors.light],

      // Scaffold 背景色
      scaffoldBackgroundColor: const Color(0xFFFFFCEE),

      // AppBar 样式
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5E8CB),
        foregroundColor: const Color(0xFF10273F),
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: NgaTypography.lightTextTheme.titleLarge?.copyWith(
          color: const Color(0xFF10273F),
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card 样式
      cardTheme: CardThemeData(
        color: const Color(0xFFF5E8CB),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEAE0C8)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Divider 样式
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5D9BA),
        thickness: 1,
        space: 1,
      ),

      // ListTile 样式
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: NgaTypography.lightTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF10273F),
        ),
        subtitleTextStyle: NgaTypography.lightTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF5C4D32),
        ),
      ),

      // 按钮样式
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF10273F),
          side: const BorderSide(color: Color(0xFFEAE0C8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1337EC),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input 样式
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFCEE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEAE0C8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEAE0C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Chip 样式
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFFFF7E9),
        labelStyle: NgaTypography.lightTextTheme.labelMedium?.copyWith(
          color: const Color(0xFF10273F),
        ),
        side: const BorderSide(color: Color(0xFFEAE0C8)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // BottomNavigationBar 样式
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF5E8CB),
        selectedItemColor: Color(0xFF1337EC),
        unselectedItemColor: Color(0xFF5C4D32),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // TabBar 样式
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF10273F),
        unselectedLabelColor: const Color(0xFF5C4D32),
        indicatorColor: colorScheme.primary,
        labelStyle: NgaTypography.lightTextTheme.labelLarge,
        unselectedLabelStyle: NgaTypography.lightTextTheme.labelLarge,
      ),

      // SnackBar 样式
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF10273F),
        contentTextStyle: NgaTypography.lightTextTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 暗色主题
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1A14),
      onSurface: const Color(0xFFE8E0D0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: NgaTypography.darkTextTheme,

      // 扩展颜色
      extensions: const [NgaColors.dark],

      // Scaffold 背景色
      scaffoldBackgroundColor: const Color(0xFF1E1A14),

      // AppBar 样式
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2A2318),
        foregroundColor: const Color(0xFFE8E0D0),
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: NgaTypography.darkTextTheme.titleLarge?.copyWith(
          color: const Color(0xFFE8E0D0),
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card 样式
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2318),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF4A3F2E)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Divider 样式
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3D3425),
        thickness: 1,
        space: 1,
      ),

      // ListTile 样式
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: NgaTypography.darkTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFFE8E0D0),
        ),
        subtitleTextStyle: NgaTypography.darkTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFFB8A88A),
        ),
      ),

      // 按钮样式
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE8E0D0),
          side: const BorderSide(color: Color(0xFF4A3F2E)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6B8CFF),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input 样式
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2318),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A3F2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A3F2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Chip 样式
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF352D22),
        labelStyle: NgaTypography.darkTextTheme.labelMedium?.copyWith(
          color: const Color(0xFFE8E0D0),
        ),
        side: const BorderSide(color: Color(0xFF4A3F2E)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // BottomNavigationBar 样式
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2A2318),
        selectedItemColor: Color(0xFF6B8CFF),
        unselectedItemColor: Color(0xFFB8A88A),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // TabBar 样式
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFFE8E0D0),
        unselectedLabelColor: const Color(0xFFB8A88A),
        indicatorColor: colorScheme.primary,
        labelStyle: NgaTypography.darkTextTheme.labelLarge,
        unselectedLabelStyle: NgaTypography.darkTextTheme.labelLarge,
      ),

      // SnackBar 样式
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF352D22),
        contentTextStyle: NgaTypography.darkTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFFE8E0D0),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
