# Coding Conventions

**Analysis Date:** 2026-01-23

## Naming Patterns

### Files
- **Pattern:** `snake_case.dart`
- **Examples:**
  - `thread_parser.dart`
  - `forum_category_service.dart`
  - `nga_http_client.dart`
  - `menu_drawer_grid.dart`

### Classes and Types
- **Pattern:** `UpperCamelCase`
- **Examples:**
  - `ThreadParser` (parser class)
  - `NgaCookieStore` (service/singleton)
  - `ForumCategoryService` (service layer)
  - `ThreadDetail` (model class)
  - `NgaHttpClient` (HTTP wrapper)

### Functions and Variables
- **Pattern:** `lowerCamelCase`
- **Examples:**
  - `parseThreadPage()` (method)
  - `loadCategories()` (method)
  - `cookie` (ValueNotifier)
  - `fetchedAt` (property)
  - `_cachedCategories` (private static)

### Constants
- **Pattern:** `lowerCamelCase` for values, `k` prefix for compile-time constants
- **Examples:**
  - `defaultUserAgent` (static const in class)
  - `_storageKey` (private static const)
  - `kDebugMode` (Flutter framework constant)

### Private Members
- **Pattern:** Underscore prefix `_`
- **Examples:**
  - `_cachedCategories` (static field)
  - `_parseLegacy()` (private method)
  - `_extractUserInfo()` (private helper)
  - `_client` (private field in HTTP client)

## Code Style

### Formatting
- **Tool:** Dart formatter (automatic with `dart format .`)
- **No custom configuration in `analysis_options.yaml`**

### Linting
- **Tool:** `flutter_lints` package
- **Config:** `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/analysis_options.yaml`
- **Base:** `package:flutter_lints/flutter.yaml`
- **Additional rules:** None (commented out `prefer_single_quotes`)

### Indentation and Spacing
- **Standard:** 2 spaces for indentation
- **Line length:** No strict limit enforced

## Import Organization

### Order
1. `dart:` imports (Dart SDK)
2. `package:` imports (external packages)
3. Relative imports (local project files)

### Examples
```dart
import 'dart:convert';                          // Dart SDK
import 'package:html/dom.dart';                 // External package
import 'package:html/parser.dart' as html_parser;
import '../model/thread_detail.dart';           // Local relative
import '../util/url_utils.dart';
```

### Path Aliases
- **Not used:** All imports use relative paths (`../`, `./`)

## Error Handling

### Try-Catch Pattern
```dart
try {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  // Process data
} catch (e, stackTrace) {
  debugPrint('[ForumCategoryService] ERROR: $e');
  debugPrint('[ForumCategoryService] StackTrace: $stackTrace');
  rethrow;  // Propagate for caller to handle
}
```

### Swallowed Errors (Fallback Parsers)
```dart
try {
  return jsonDecode(jsonStr) as Map<String, dynamic>;
} catch (e) {
  // Ignore parsing errors and fall back to empty data
}
return {};
```

### Async Error Handling
```dart
static Future<void> loadFromStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedCookie = prefs.getString(_storageKey) ?? '';
    cookie.value = savedCookie;
  } catch (e) {
    debugPrint('=== [NGA] Failed: $e ===');
    // Non-critical: silent fail, app continues without cookies
  }
}
```

## Logging

### Framework
- **Tool:** `debugPrint()` from `package:flutter/foundation.dart`
- **Guard:** Always wrap in `kDebugMode` check

### Pattern
```dart
if (kDebugMode) {
  debugPrint('[ForumCategoryService] Loading categories from assets...');
}
```

### Tagging Convention
- **Format:** `[CategoryName] Message`
- **Examples:**
  - `[ForumCategoryService]`
  - `[NGA] NgaCookieStore.setCookie`
  - `[NGA] NgaCookieStore.loadFromStorage`

## Comments

### Documentation Comments
- **Style:** Doxygen-style `///` for public APIs
- **Location:** Above classes and methods
- **Examples:**
  ```dart
  /// Parses a thread page HTML (first page only).
  ///
  /// MVP goals:
  /// - extract a list of post bodies as `content_text`
  /// - author name may be unavailable in raw HTML
  ThreadDetail parseThreadPage(...) { ... }
  ```

### Implementation Comments
- **Style:** Inline `//` for notes
- **Examples:**
  ```dart
  // 1. Extract metadata via Regex
  final userInfoMap = _extractUserInfo(htmlText);

  // Attempt hybrid parsing first
  try { ... }
  ```

## Function Design

### Size
- **Preference:** Small, focused functions
- **Example:** Parser has `_extractUserInfo()`, `_extractGroups()`, `_extractDeviceType()` as separate helpers

### Parameters
- **Named parameters:** Used for complex methods
- **Pattern:**
  ```dart
  ThreadDetail parseThreadPage(
    String htmlText, {
    required int tid,
    required String url,
    required int fetchedAt,
  })
  ```

### Return Types
- **Explicit:** All functions have explicit return types
- **Void:** Used for side-effect functions (e.g., `setCookie()`)

## Class Design

### Constructors
- **Positional:** Simple models with positional parameters
- **Named:** For optional configurations
- **Examples:**
  ```dart
  class ThreadPost {
    ThreadPost({
      this.pid,
      required this.floor,
      required this.author,
      required this.authorUid,
      required this.contentText,
      this.deviceType,
      this.postDate,
    });
  }
  ```

### Static Utilities
- **Pattern:** Service classes with static methods
- **Examples:**
  - `ForumCategoryService.loadCategories()`
  - `NgaCookieStore.setCookie()`
  - `NgaCookieStore.summarizeCookieHeader()`

### Singleton Pattern
- **Approach:** Static fields + private constructor
- **Example:**
  ```dart
  class NgaCookieStore {
    NgaCookieStore._();  // Private constructor
    static final ValueNotifier<String> cookie = ValueNotifier<String>('');
  }
  ```

## Module Design

### Exports
- **Barrel files:** Used in theme module
- **Example:** `theme/app_theme.dart` exports colors and typography
  ```dart
  export 'app_colors.dart';
  export 'app_typography.dart';
  ```

### Directory Structure
```
nga_app/lib/
├── main.dart                    # Entry point
├── screens/                     # Pages
│   └── home_screen.dart
├── widgets/                     # Reusable UI components
├── services/                    # Business logic services
├── src/                         # Internal implementation
│   ├── auth/                    # Authentication
│   ├── http/                    # HTTP client
│   ├── model/                   # Data models
│   ├── parser/                  # HTML parsers
│   └── util/                    # Utilities
└── theme/                       # Theming
```

---

*Convention analysis: 2026-01-23*
