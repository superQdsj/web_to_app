---
name: flutter-development
description: Flutter and Dart development guide following modern best practices. Use when writing Flutter/Dart code, creating widgets, managing state, setting up navigation with GoRouter, theming with Material 3, testing, or following Effective Dart guidelines. Triggers on Flutter, Dart, Widget, StatelessWidget, StatefulWidget, ThemeData, ColorScheme.
---

# Flutter Development

Expert guide for building beautiful, performant, and maintainable Flutter applications.

## Quick Start

### Core Principles
- **SOLID Principles**: Apply throughout codebase
- **Composition over Inheritance**: Favor composing smaller widgets
- **Immutability**: Widgets (especially `StatelessWidget`) should be immutable
- **Separation of Concerns**: UI logic separate from business logic

### Project Structure
```
lib/
├── main.dart              # Application entry point
├── presentation/          # Widgets, screens
├── domain/                # Business logic classes
├── data/                  # Models, API clients
└── core/                  # Utilities, extensions
```

### Naming Conventions
- `PascalCase` for classes
- `camelCase` for members/variables/functions/enums
- `snake_case` for files
- Line length: 80 characters or fewer

## Widget Essentials

### Prefer Composition
```dart
// ✅ Good: Small, focused widgets
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          UserAvatar(user: user),
          UserInfo(user: user),
        ],
      ),
    );
  }
}

// ❌ Avoid: Private helper methods returning widgets
Widget _buildUserInfo() => ... // Use private Widget classes instead
```

### Use Const Constructors
```dart
// ✅ Reduces rebuilds
const SizedBox(height: 16),
const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.star)),
```

### Performance Tips
- Use `ListView.builder` for long lists (lazy loading)
- Use `compute()` for expensive calculations (separate isolate)
- Avoid expensive operations in `build()` methods

## Navigation with GoRouter

```dart
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'details/:id',
          builder: (context, state) {
            final String id = state.pathParameters['id']!;
            return DetailScreen(id: id);
          },
        ),
      ],
    ),
  ],
);

// Use in MaterialApp
MaterialApp.router(routerConfig: _router);
```

## Detailed References

For comprehensive guidance on specific topics:

| Topic | Reference | When to Use |
|-------|-----------|-------------|
| State Management | [state-management.md](references/state-management.md) | ValueNotifier, ChangeNotifier, Streams, MVVM |
| Theming & Design | [theming.md](references/theming.md) | ThemeData, ColorScheme, Material 3, fonts, layouts |
| Testing | [testing.md](references/testing.md) | Unit, widget, integration tests, mocking |
| Architecture | [architecture.md](references/architecture.md) | MVVM, data flow, routing, feature organization |
| Code Quality | [code-quality.md](references/code-quality.md) | Dart/Flutter best practices, API design |
| Documentation | [documentation.md](references/documentation.md) | dartdoc, comment style, accessibility |

## Package Management

```bash
# Add dependency
flutter pub add <package_name>

# Add dev dependency
flutter pub add dev:<package_name>

# Run code generation (for json_serializable, etc.)
dart run build_runner build --delete-conflicting-outputs
```

## Essential Packages

| Purpose | Package |
|---------|---------|
| Navigation | `go_router` |
| JSON Serialization | `json_serializable`, `json_annotation` |
| Fonts | `google_fonts` |
| Testing | `package:test`, `package:flutter_test`, `package:checks` |
