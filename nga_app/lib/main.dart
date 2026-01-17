import 'package:flutter/material.dart';

import '../config/nga_env.dart';
import '../data/nga_repository.dart';
import 'screens/forum_screen.dart';

void main() {
  runApp(const NgaApp());
}

class NgaApp extends StatelessWidget {
  const NgaApp({super.key});

  static late final NgaRepository repository;

  static const _bg = Color(0xFFF6E9CC);
  static const _surface = Color(0xFFFBF2DA);
  static const _surfaceVariant = Color(0xFFF0E1C3);
  static const _outline = Color(0xFFD8C6A1);
  static const _ink = Color(0xFF3A2A1A);
  static const _muted = Color(0xFF7B614A);
  static const _primary = Color(0xFF6E4A2E);

  ThemeData _buildTheme() {
    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Color(0xFFFFFAF0),
      primaryContainer: Color(0xFFE6D0A6),
      onPrimaryContainer: Color(0xFF2A1A0F),
      secondary: Color(0xFF4E6B5A),
      onSecondary: Color(0xFFFFFAF0),
      secondaryContainer: Color(0xFFD8E5DD),
      onSecondaryContainer: Color(0xFF1F2A24),
      tertiary: Color(0xFF3E5F7D),
      onTertiary: Color(0xFFFFFAF0),
      tertiaryContainer: Color(0xFFD7E2EE),
      onTertiaryContainer: Color(0xFF1B2B39),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFF9DEDC),
      onErrorContainer: Color(0xFF410E0B),
      background: _bg,
      onBackground: _ink,
      surface: _surface,
      onSurface: _ink,
      surfaceVariant: _surfaceVariant,
      onSurfaceVariant: _muted,
      outline: _outline,
      outlineVariant: Color(0xFFE7D6B5),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2A1A0F),
      onInverseSurface: Color(0xFFFFFAF0),
      inversePrimary: Color(0xFFE6D0A6),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      dividerColor: scheme.outlineVariant.withOpacity(0.55),
    );

    final text = base.textTheme;

    return base.copyWith(
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onBackground,
          letterSpacing: -0.2,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onBackground,
          letterSpacing: -0.2,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onBackground,
        ),
        bodyLarge: text.bodyLarge?.copyWith(
          height: 1.42,
          color: scheme.onBackground,
        ),
        bodyMedium: text.bodyMedium?.copyWith(
          height: 1.42,
          color: scheme.onBackground,
        ),
        bodySmall: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelLarge: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onBackground,
          letterSpacing: -0.2,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.55),
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceVariant,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    repository = NgaRepository(cookie: NgaEnv.cookie);
    return MaterialApp(
      title: 'NGA Forum',
      theme: _buildTheme(),
      home: const ForumScreen(),
    );
  }
}
