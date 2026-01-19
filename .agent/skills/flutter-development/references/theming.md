# Theming & Visual Design

Comprehensive guide for Material 3 theming, color schemes, typography, and responsive layouts.

## Table of Contents
- [ThemeData Setup](#themedata-setup)
- [ColorScheme](#colorscheme)
- [ThemeExtension](#themeextension)
- [Typography](#typography)
- [Layout Best Practices](#layout-best-practices)
- [Assets & Images](#assets--images)

---

## ThemeData Setup

### Light and Dark Themes

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
    ),
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system, // or .light, .dark
  home: const MyHomePage(),
);
```

### Component Themes

Customize specific components within `ThemeData`:

```dart
ThemeData(
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  cardTheme: const CardTheme(
    elevation: 2,
    margin: EdgeInsets.all(8),
  ),
);
```

---

## ColorScheme

### Generate from Seed

```dart
ColorScheme.fromSeed(
  seedColor: Colors.deepPurple,
  brightness: Brightness.light,
)
```

### Color Palette Guidelines

| Role | Usage | Ratio |
|------|-------|-------|
| Primary/Neutral | Dominant surfaces | 60% |
| Secondary | Supporting elements | 30% |
| Accent | Call-to-action, highlights | 10% |

### Contrast Requirements (WCAG 2.1)
- **Normal text**: 4.5:1 minimum
- **Large text** (18pt or 14pt bold): 3:1 minimum

---

## ThemeExtension

For custom design tokens not in standard `ThemeData`:

```dart
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success, required this.danger});

  final Color? success;
  final Color? danger;

  @override
  ThemeExtension<AppColors> copyWith({Color? success, Color? danger}) {
    return AppColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t),
      danger: Color.lerp(danger, other.danger, t),
    );
  }
}

// Register in ThemeData
theme: ThemeData(
  extensions: const <ThemeExtension<dynamic>>[
    AppColors(success: Colors.green, danger: Colors.red),
  ],
),

// Use in widgets
Container(
  color: Theme.of(context).extension<AppColors>()!.success,
)
```

---

## Typography

### Font Scale

```dart
textTheme: const TextTheme(
  displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold),
  titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
  bodyLarge: TextStyle(fontSize: 16.0, height: 1.5),
  bodyMedium: TextStyle(fontSize: 14.0, height: 1.4),
  labelSmall: TextStyle(fontSize: 11.0, color: Colors.grey),
),
```

### Google Fonts

```dart
// flutter pub add google_fonts

final TextTheme appTextTheme = TextTheme(
  displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
  titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
  bodyMedium: GoogleFonts.openSans(fontSize: 14),
);
```

### Readability Guidelines
- **Line height**: 1.4x to 1.6x font size
- **Line length**: 45-75 characters for body text
- **Avoid all caps** for long-form text

---

## Layout Best Practices

### Flexible Layouts

```dart
// Expanded: Fill remaining space
Row(
  children: [
    const Icon(Icons.star),
    Expanded(child: Text('Title')),
    const Icon(Icons.more_vert),
  ],
)

// Wrap: Prevent overflow
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: chips,
)
```

### Responsive Design

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return WideLayout();
    }
    return NarrowLayout();
  },
)
```

### WidgetStateProperty

```dart
final ButtonStyle myButtonStyle = ButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith<Color>(
    (Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.green;
      }
      return Colors.blue;
    },
  ),
);
```

---

## Assets & Images

### Declare in pubspec.yaml

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

### Local Images

```dart
Image.asset('assets/images/placeholder.png')
```

### Network Images

```dart
Image.network(
  'https://example.com/image.png',
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return const Center(child: CircularProgressIndicator());
  },
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.error);
  },
)
```

> **Tip**: Use `cached_network_image` package for caching network images.
