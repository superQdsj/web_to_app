part of '../thread_screen.dart';

/// 帖子页面配色方案
///
/// 注意: 此类保留用于向后兼容，新代码应使用 [NgaColors] 扩展
/// 使用方式: `context.ngaColors.postBackground`
class _ThreadPalette {
  const _ThreadPalette._();

  // 从全局主题获取颜色 (亮色模式默认值)
  // 主背景色 #f5e8cb
  static const Color backgroundLight = Color(0xFFF5E8CB);
  // 次背景色 #fffcee
  static const Color surfaceLight = Color(0xFFFFFCEE);
  static const Color borderLight = Color(0xFFEAE0C8);
  // 主要文字颜色 #10273f
  static const Color textPrimary = Color(0xFF10273F);
  static const Color textSecondary = Color(0xFF5C4D32);
  // 第三级文字颜色（时间戳等辅助信息）
  static const Color textTertiary = Color(0xFF8A7B5A);
  static const Color primary = Color(0xFF1337EC);

  // 引用块样式
  /// 引用块背景色（浅米黄）
  static const Color quoteBackground = Color(0xFFFFF9EB);

  /// 引用块左侧装饰条颜色（淡紫色）
  static const Color quoteAccent = Color(0xFF9FA8DA);

  /// 引用文字颜色（较浅的褐色）
  static const Color quoteText = Color(0xFF795548);

  /// 引用作者名颜色（深褐色）
  static const Color quoteAuthor = Color(0xFF5D4037);
}
