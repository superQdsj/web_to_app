import 'package:flutter/material.dart';

/// NGA 论坛字体排版配置
///
/// 遵循 Material 3 的字体层级:
/// - Display: 大型展示文字 (很少使用)
/// - Headline: 标题 (帖子标题等)
/// - Title: 副标题/小节标题
/// - Body: 正文内容
/// - Label: 按钮/标签等小型文字
class NgaTypography {
  const NgaTypography._();

  /// 主要文字颜色 (#10273f)
  static const Color _textColor = Color(0xFF10273F);

  /// 次要文字颜色
  static const Color _textSecondary = Color(0xFF5C4D32);

  /// 创建亮色主题的 TextTheme
  static TextTheme get lightTextTheme {
    return _baseTextTheme.apply(
      bodyColor: _textColor,
      displayColor: _textColor,
    );
  }

  /// 创建暗色主题的 TextTheme
  static TextTheme get darkTextTheme {
    const darkText = Color(0xFFE8E0D0);
    return _baseTextTheme.apply(bodyColor: darkText, displayColor: darkText);
  }

  /// 基础字体配置
  ///
  /// 使用系统默认字体族，确保在 iOS/Android 上都有良好表现
  /// - iOS: San Francisco
  /// - Android: Roboto
  /// - 中文: 系统默认 (PingFang SC / Noto Sans CJK)
  static TextTheme get _baseTextTheme {
    return const TextTheme(
      // Display - 大型展示文字
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      ),

      // Headline - 页面/帖子标题
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      ),

      // Title - 小节标题/列表项标题
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      // Body - 正文内容
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),

      // Label - 按钮/标签/辅助文字
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }
}

/// 帖子内容专用文字样式
///
/// 用于论坛帖子内容的特殊排版需求
class NgaPostTextStyles {
  const NgaPostTextStyles._();

  /// 帖子内容文字 (论坛特色: 较大行高，易读)
  static TextStyle postContent({Color? color}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.7,
    letterSpacing: 0.3,
    color: color ?? NgaTypography._textColor,
  );

  /// 引用块文字
  static TextStyle quote({Color? color}) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    height: 1.6,
    color: color ?? NgaTypography._textSecondary,
  );

  /// 代码块文字 (等宽字体)
  static TextStyle code({Color? color}) => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: 'monospace',
    height: 1.5,
    letterSpacing: 0,
    color: color ?? NgaTypography._textColor,
  );

  /// 用户名文字
  static TextStyle username({Color? color}) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: color ?? NgaTypography._textColor,
  );

  /// 时间戳/元信息
  static TextStyle meta({Color? color}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: color ?? NgaTypography._textSecondary,
  );

  /// 楼层号
  static TextStyle floorNumber({Color? color}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: color ?? NgaTypography._textSecondary,
  );
}
