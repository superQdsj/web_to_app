# Coding Conventions

**Analysis Date:** 2025-01-23

## Naming Patterns

**Files:**
- `snake_case.dart` - All Dart files use snake_case naming
  - Example: `forum_category_service.dart`, `thread_parser.dart`

**Classes and Types:**
- `UpperCamelCase` - All classes, typedefs, and enums
  - Example: `ThreadParser`, `ForumCategory`, `NgaHttpClient`

**Functions and Variables:**
- `lowerCamelCase` - Methods, local variables, top-level variables
  - Example: `parseThreadPage`, `_scaffoldKey`, `_loading`

**Constants:**
- `lowerCamelCase` for local constants
- `k` prefix for compile-time constants (Flutter convention)
  - Example: `kDebugMode`, `defaultUserAgent`

**Private Members:**
- Leading underscore `_` indicates private class members
  - Example: `_parseRequiredInt()`, `_cachedCategories`

## Code Style

**Formatting:**
- Dart formatter is used (default settings)
- 2-space indentation
- Trailing commas in collection literals for better formatting

**Linting:**
- `analysis_options.yaml` located at `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/analysis_options.yaml`
- Uses `package:flutter_lints/flutter.yaml` as base configuration
- Key rules enforced:
  - `avoid_print: false` (debugPrint is preferred)
  - `prefer_single_quotes: true` (enabled)

**Run Formatting:**
```bash
cd nga_app && fvm dart format .
```

## Import Organization

**Order (top to bottom):**
1. Dart core libraries: `dart:async`, `dart:io`
2. Flutter packages: `package:flutter/...`
3. Third-party packages: `package:http/...`, `package:html/...`
4. Relative imports: `../src/...`, `./widgets/...`

**Examples from codebase:**
```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../src/auth/nga_cookie_store.dart';
import 'screens/home_screen.dart';
```

**Path Aliases:**
- No path aliases configured; relative imports are used consistently
- Example: `../src/model/thread_detail.dart`

## Error Handling

**Try-Catch Pattern:**
- Exceptions are caught with `try-catch (e, stackTrace)` pattern
- Errors are logged via `debugPrint` with context
- Original exception is rethrown after logging when appropriate

**Example from `nga_app/lib/src/model/forum_category.dart`:**
```dart
factory ForumCategory.fromJson(Map<String, dynamic> json) {
  try {
    final category = ForumCategory(...);
    return category;
  } catch (e, stackTrace) {
    debugPrint('[ForumCategory.fromJson] ERROR parsing category: $e');
    debugPrint('[ForumCategory.fromJson] JSON data: $json');
    debugPrint('[ForumCategory.fromJson] StackTrace: $stackTrace');
    rethrow;
  }
}
```

**Result Objects:**
- `NgaHttpResponse` wraps HTTP responses with typed fields
- No Result/Either type pattern currently in use

**Timeouts:**
- HTTP client uses `Future.timeout()` with custom `TimeoutException`
- Default timeout: 30 seconds
- Example from `nga_app/lib/src/http/nga_http_client.dart`:
```dart
.timeout(
  timeout,
  onTimeout: () {
    throw TimeoutException('timeout fetching $url');
  },
)
```

## Logging

**Framework:**
- `debugPrint()` from `package:flutter/foundation.dart`
- Conditional logging with `kDebugMode` guard

**Logging Prefix Convention:**
- All logs use `[NGA]` or `[ClassName]` prefix for filtering
- Example from `nga_app/lib/src/auth/nga_cookie_store.dart`:
```dart
if (kDebugMode) {
  debugPrint('=== [NGA] NgaCookieStore.setCookie len=${trimmed.length} ===');
}
```

**Stack Traces:**
- Printed on errors in parsing and service layers

## Comments

**When to Comment:**
- Complex parsing logic: explain regex patterns and extraction strategies
- Public APIs: Dartdoc comments for classes and public methods
- Chinese comments used for user-facing UI text and business logic notes

**JSDoc/TSDoc:**
- Minimal usage; inline comments preferred for implementation details
- Example from `nga_app/lib/screens/home_screen.dart`:
```dart
/// Main home screen with drawer navigation.
///
/// Replaces the bottom tab navigation with:
/// - Left drawer (MenuDrawer) for multi-function menu
/// - Right drawer (ProfileDrawer) for user profile
/// - AppBar with menu button (left) and avatar button (right)
class HomeScreen extends StatefulWidget {
```

**Inline Comments:**
- Used for TODO notes and explanation of complex logic
- Example from `nga_app/lib/screens/forum_screen.dart`:
```dart
// 如果已选中版块，登录后自动重新加载数据
if (NgaForumStore.activeFid.value != null && NgaCookieStore.hasCookie) {
  _fetchThreads();
}
```

## Function Design

**Size:**
- No strict limit; functions are kept focused on single responsibility
- Complex parsers extract helper methods (e.g., `_parseLegacy`, `_extractUserInfo`)

**Parameters:**
- Named parameters preferred for optional args with `required` keyword
- Example from `nga_app/lib/src/http/nga_http_client.dart`:
```dart
Future<NgaHttpResponse> getBytes(
  Uri url, {
  required String cookieHeaderValue,
  Duration timeout = const Duration(seconds: 30),
})
```

**Return Values:**
- Explicit return types on public methods
- `void` for side-effect methods

## Module Design

**Exports:**
- Theme module uses barrel exports:
```dart
export 'app_colors.dart';
export 'app_typography.dart';
```

**Stateless vs Stateful:**
- StatelessWidget for pure UI components
- StatefulWidget for UI with state or listeners
- Example pattern from `nga_app/lib/screens/home_screen.dart`:
```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State implementation
}
```

**State Management:**
- `ValueNotifier` for simple reactive state (e.g., `NgaCookieStore.cookie`)
- Local `State` for screen-level state
- Repository pattern (`NgaRepository`) for data access

**Singleton Pattern:**
- Static instances with private constructor for stores:
```dart
class NgaCookieStore {
  NgaCookieStore._();
  static final ValueNotifier<String> cookie = ValueNotifier<String>('');
}
```

---

*Convention analysis: 2025-01-23*
