# Repository Guidelines for AI Agents

This document provides guidelines for AI coding agents working in this Flutter mobile forum browsing app codebase.

## Project Overview

NGA App is a Flutter mobile application for browsing the [NGA Forum](https://bbs.nga.cn). It supports WebView-based authentication, forum thread browsing, and thread detail reading with automatic GBK/GB18030 encoding handling.

## Project Structure

```
.
├── nga_app/                    # Flutter application
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── screens/            # Page widgets (forum_screen, thread_screen, etc.)
│   │   │   ├── widgets/        # Screen-specific widgets
│   │   │   └── thread/         # Thread-related components
│   │   ├── src/                # Core business logic
│   │   │   ├── auth/           # Authentication (cookie store, user store)
│   │   │   ├── codec/          # Encoding utilities (GBK decoder)
│   │   │   ├── http/           # HTTP client wrapper
│   │   │   ├── model/          # Data models (ThreadItem, ThreadDetail)
│   │   │   ├── parser/         # HTML parsers (forum, thread)
│   │   │   ├── services/       # Business services
│   │   │   └── util/           # Utility functions
│   │   ├── data/               # Repository layer
│   │   └── theme/              # Theme configuration
│   └── test/                   # Test files
├── docs/                       # Documentation
├── scripts/                    # Development scripts (gwt.sh for worktrees)
├── private/                    # Local sensitive files (git-ignored)
└── out/                        # Build outputs (git-ignored)
```

## Build, Test, and Development Commands

All commands require `fvm` (Flutter Version Manager). Run from project root or `nga_app/` as indicated.

```bash
# Install dependencies
cd nga_app && fvm flutter pub get

# Run application
cd nga_app && fvm flutter run

# Run ALL tests
cd nga_app && fvm flutter test

# Run SINGLE test file
cd nga_app && fvm flutter test test/parser/thread_parser_test.dart

# Run tests matching a pattern
cd nga_app && fvm flutter test --name "should extract"

# Code analysis (linting)
cd nga_app && fvm flutter analyze

# Format code
cd nga_app && fvm dart format .

# Parallel development (creates git worktree)
./scripts/gwt.sh <branch-name>
```

## Parallel Development Policy

- **Git Worktree**: Use `./scripts/gwt.sh <branch>` for multi-branch parallel development
- **Build Policy**: Avoid `flutter run` or `flutter build` in worktrees - build directories are huge (GB+) and cause cache pollution
- **Validation**: Use `fvm flutter analyze` for verification in worktrees

## Code Style Guidelines

### Naming Conventions

| Type | Style | Example |
|------|-------|---------|
| Variables/Functions | lowerCamelCase | `fetchThreads`, `currentPage`, `_loading` |
| Classes/Types | UpperCamelCase | `ThreadItem`, `NgaRepository`, `ForumParser` |
| File names | snake_case | `forum_screen.dart`, `nga_cookie_store.dart` |
| Private members | Leading underscore | `_client`, `_cookie`, `_threads` |
| Constants | lowerCamelCase | `defaultUserAgent`, `_storageKey` |

### Import Conventions

```dart
// 1. Dart SDK imports first
import 'dart:async';
import 'dart:io';

// 2. Package imports (external dependencies)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 3. Relative imports for local files (preferred over package imports)
import '../src/model/thread_item.dart';
import '../data/nga_repository.dart';
```

### Formatting & Types

- **Line length**: Default Dart formatter settings (80 chars soft limit)
- **Trailing commas**: Use in multi-line argument lists for better diffs
- **Type annotations**: Explicit for public APIs and class members, inferred OK for local variables
- **Null safety**: Use required named parameters, nullable types with `?` where appropriate
- **No type suppressions**: Never use `as dynamic`, `// ignore:` for type errors

### Model Classes

```dart
class ThreadItem {
  ThreadItem({
    required this.tid,        // Required non-nullable
    required this.title,
    required this.author,     // Nullable fields still use required
  });

  final int tid;              // Immutable fields with final
  final String title;
  final String? author;       // Nullable when data may be missing

  Map<String, Object?> toJson() => {  // snake_case for JSON keys
    'tid': tid,
    'author_uid': authorUid,
  };
}
```

### State Management

- **ValueNotifier**: Used for simple global state (no external state management library)
- **Pattern**: Static ValueNotifier with listeners in StatefulWidget

```dart
// Store pattern
class NgaCookieStore {
  static final ValueNotifier<String> cookie = ValueNotifier<String>('');
  static void setCookie(String value) => cookie.value = value;
}

// Usage in widget
@override
void initState() {
  super.initState();
  NgaCookieStore.cookie.addListener(_onCookieChanged);
}

@override
void dispose() {
  NgaCookieStore.cookie.removeListener(_onCookieChanged);
  super.dispose();
}
```

### Error Handling

```dart
// Use try-catch with specific error messages
try {
  final threads = await _repository.fetchForumThreads(fid);
  setState(() => _threads.addAll(threads));
} catch (e) {
  setState(() => _error = e.toString());
}

// Throw descriptive exceptions
if (resp.statusCode != 200) {
  throw Exception('Failed to fetch forum: HTTP ${resp.statusCode}');
}

// Debug logging pattern
if (kDebugMode) {
  debugPrint('=== [NGA] Context message: $variable ===');
}
```

### Widget Organization

- **Screen widgets**: Full-page components in `screens/` folder
- **Reusable widgets**: Shared components in `screens/widgets/`
- **Private widgets**: Prefixed with underscore, same file as parent
- **StatelessWidget**: Prefer when no local state needed

```dart
// Private helper widget in same file
class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});
  
  final ThreadItem thread;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) { ... }
}
```

## Testing Guidelines

### Test File Organization

- Tests mirror source structure: `lib/src/parser/` -> `test/parser/`
- Widget tests in `test/widget_test.dart`
- Test file naming: `<source_name>_test.dart`

### Test Patterns

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nga_app/src/parser/thread_parser.dart';

void main() {
  test('Parser should extract metadata from HTML', () {
    final parser = ThreadParser();
    final detail = parser.parseThreadPage(html, tid: 123, ...);
    
    expect(detail.posts.isNotEmpty, isTrue);
    expect(detail.posts[0].author?.username, 'expected_name');
  });
}
```

### Running Tests

```bash
# All tests
fvm flutter test

# Single file
fvm flutter test test/parser/thread_parser_test.dart

# By name pattern
fvm flutter test --name "should extract"

# With coverage
fvm flutter test --coverage
```

## Commit & PR Guidelines

- **Conventional Commits**: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`
- **PR Requirements**: Purpose/summary, run commands, any compatibility notes
- **Never commit**: Cookies, `.env` files, anything in `private/` folder
- **Mask in logs**: Always hide Cookie values in logs and screenshots

## Security

- **Cookies**: Stored locally via SharedPreferences, never committed
- **Sensitive files**: Use `private/` directory (git-ignored)
- **Debug output**: Summarize cookies by name/length, never log full values

## Common Patterns

### HTTP Client Usage

```dart
final client = NgaHttpClient();
final response = await client.getBytes(
  url,
  cookieHeaderValue: cookie,
  timeout: const Duration(seconds: 30),
);
```

### Repository Pattern

```dart
class NgaRepository {
  NgaRepository({required String cookie}) : _cookie = cookie;
  
  Future<List<ThreadItem>> fetchForumThreads(int fid) async { ... }
  void close() => _client.close();
}
```

## Linting

Uses `package:flutter_lints/flutter.yaml` base rules. Run `fvm flutter analyze` to check.
