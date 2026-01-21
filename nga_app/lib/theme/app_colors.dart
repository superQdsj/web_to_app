import 'package:flutter/material.dart';

/// NGA 论坛自定义颜色扩展
///
/// 使用 ThemeExtension 模式实现自定义颜色，支持主题切换和动画过渡
@immutable
class NgaColors extends ThemeExtension<NgaColors> {
  const NgaColors({
    // 文字颜色
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    // 帖子/卡片背景
    required this.postBackground,
    required this.postBackgroundSecondary,
    required this.cardSurface,
    // 边框
    required this.border,
    required this.divider,
    // 交互元素
    required this.link,
    required this.linkHover,
    // 状态颜色
    required this.success,
    required this.warning,
    required this.error,
    // 特殊元素
    required this.quoteBackground,
    required this.codeBackground,
  });

  // 文字颜色
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // 帖子/卡片背景
  final Color postBackground;
  final Color postBackgroundSecondary;
  final Color cardSurface;

  // 边框
  final Color border;
  final Color divider;

  // 交互元素
  final Color link;
  final Color linkHover;

  // 状态颜色
  final Color success;
  final Color warning;
  final Color error;

  // 特殊元素
  final Color quoteBackground;
  final Color codeBackground;

  /// 亮色主题配色 (经典 NGA 风格)
  static const light = NgaColors(
    // 文字: 用户指定 #10273f 作为主要字体色
    textPrimary: Color(0xFF10273F),
    textSecondary: Color(0xFF5C4D32),
    textMuted: Color(0xFF8A7A5C),
    // 帖子背景: 用户指定 #f5e8cb (主) 和 #fffcee (次)
    postBackground: Color(0xFFF5E8CB),
    postBackgroundSecondary: Color(0xFFFFFCEE),
    cardSurface: Color(0xFFFFF7E9),
    // 边框
    border: Color(0xFFEAE0C8),
    divider: Color(0xFFE5D9BA),
    // 交互
    link: Color(0xFF1337EC),
    linkHover: Color(0xFF0D2BB5),
    // 状态
    success: Color(0xFF2E7D32),
    warning: Color(0xFFF9A825),
    error: Color(0xFFC62828),
    // 特殊
    quoteBackground: Color(0xFFFFF8E1),
    codeBackground: Color(0xFFF5F5F5),
  );

  /// 暗色主题配色
  static const dark = NgaColors(
    // 文字
    textPrimary: Color(0xFFE8E0D0),
    textSecondary: Color(0xFFB8A88A),
    textMuted: Color(0xFF8A7A5C),
    // 帖子背景 (暗色调整)
    postBackground: Color(0xFF2A2318),
    postBackgroundSecondary: Color(0xFF1E1A14),
    cardSurface: Color(0xFF352D22),
    // 边框
    border: Color(0xFF4A3F2E),
    divider: Color(0xFF3D3425),
    // 交互
    link: Color(0xFF6B8CFF),
    linkHover: Color(0xFF8DA6FF),
    // 状态
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFCA28),
    error: Color(0xFFEF5350),
    // 特殊
    quoteBackground: Color(0xFF3D3425),
    codeBackground: Color(0xFF2D2D2D),
  );

  @override
  NgaColors copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? postBackground,
    Color? postBackgroundSecondary,
    Color? cardSurface,
    Color? border,
    Color? divider,
    Color? link,
    Color? linkHover,
    Color? success,
    Color? warning,
    Color? error,
    Color? quoteBackground,
    Color? codeBackground,
  }) {
    return NgaColors(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      postBackground: postBackground ?? this.postBackground,
      postBackgroundSecondary:
          postBackgroundSecondary ?? this.postBackgroundSecondary,
      cardSurface: cardSurface ?? this.cardSurface,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      link: link ?? this.link,
      linkHover: linkHover ?? this.linkHover,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      quoteBackground: quoteBackground ?? this.quoteBackground,
      codeBackground: codeBackground ?? this.codeBackground,
    );
  }

  @override
  NgaColors lerp(ThemeExtension<NgaColors>? other, double t) {
    if (other is! NgaColors) return this;
    return NgaColors(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      postBackground: Color.lerp(postBackground, other.postBackground, t)!,
      postBackgroundSecondary: Color.lerp(
        postBackgroundSecondary,
        other.postBackgroundSecondary,
        t,
      )!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      link: Color.lerp(link, other.link, t)!,
      linkHover: Color.lerp(linkHover, other.linkHover, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      quoteBackground: Color.lerp(quoteBackground, other.quoteBackground, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
    );
  }
}

/// 便捷扩展方法，用于在 BuildContext 上访问 NgaColors
extension NgaColorsExtension on BuildContext {
  NgaColors get ngaColors => Theme.of(this).extension<NgaColors>()!;
}
