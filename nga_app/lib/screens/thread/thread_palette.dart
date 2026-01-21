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
  static const Color primary = Color(0xFF1337EC);
}

