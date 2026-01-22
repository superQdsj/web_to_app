# Testing Patterns

**Analysis Date:** 2026-01-23

## Test Framework

### Runner
- **Framework:** `flutter_test` (Flutter SDK)
- **Version:** Bundled with Flutter SDK (`^3.10.7`)
- **Config:** `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/pubspec.yaml`

### Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Assertion Library
- **Framework:** `flutter_test` built-in (`expect()`)
- **Matchers:** `isTrue`, `isFalse`, `equals()`, `findsOneWidget`, etc.

### Run Commands
```bash
cd nga_app && fvm flutter test          # Run all tests
cd nga_app && fvm flutter test --verbose  # Verbose output
cd nga_app && fvm flutter test --update-goldens  # Update golden files
```

## Test File Organization

### Location
- **Pattern:** Separate `test/` directory at project root
- **Subdirectories:** Mirrors `lib/` structure
  ```
  nga_app/
  ├── lib/
  │   └── src/parser/
  │       └── thread_parser.dart
  └── test/
      └── parser/
          └── thread_parser_test.dart
  ```

### Naming Convention
- **Pattern:** `{module}_test.dart`
- **Examples:**
  - `test/widget_test.dart` - App widget smoke test
  - `test/parser/thread_parser_test.dart` - Parser unit tests

### File Count
- **Current:** 2 test files (1 default, 1 custom)
- **Coverage gap:** Services, models, HTTP client not tested

## Test Structure

### Unit Test Pattern (Parser Tests)
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nga_app/src/parser/thread_parser.dart';

void main() {
  test('Hybrid Parser should extract rich metadata from nga_debug.html', () {
    final file = File('../private/nga_debug.html');
    if (!file.existsSync()) {
      throw Exception(' nga_debug.html not found, skipping test.');
    }
    final html = file.readAsStringSync();

    final parser = ThreadParser();
    final detail = parser.parseThreadPage(
      html,
      tid: 46023232,
      url: 'https://bbs.nga.cn/read.php?tid=46023232',
      fetchedAt: DateTime.now().millisecondsSinceEpoch,
    );

    expect(detail.posts.isNotEmpty, isTrue);

    // Floor 0
    final p0 = detail.posts[0];
    expect(p0.author?.username, 'yhm31');
    expect(p0.author?.uid, 39748236);
    expect(p0.deviceType, '7 iOS');
    expect(p0.postDate, '2026-01-19 20:02');
    expect(p0.author?.wowCharacter?.name, '玛拉吉斯');
    expect(p0.author?.wowCharacter?.realm, '主宰之剑');
  });
}
```

### Widget Test Pattern (Smoke Test)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nga_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NgaApp());

    // Verify that the app title is present.
    expect(find.text('NGA Forum'), findsOneWidget);
  });
}
```

## Mocking

### Current State
- **Mocking framework:** Not detected in dependencies
- **Approach:** Uses real files and data for parser tests

### Fixture Data Pattern
- **Location:** `private/` directory (git-ignored)
- **File:** `nga_debug.html` - HTML sample for parsing tests
- **Access:** Direct `File` read in test
  ```dart
  final file = File('../private/nga_debug.html');
  final html = file.readAsStringSync();
  ```

### What Could Be Mocked
- HTML parsing (html package)
- HTTP responses
- File system reads
- SharedPreferences

### Recommended Mocking Setup
Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  mockito: ^5.4.0  # For Dart mocks
  build_runner: ^2.4.0  # For mock generation
```

## Fixtures and Factories

### Current Pattern
- **Location:** `private/` folder (not committed)
- **Format:** HTML files for parser testing

### Test Data Examples
```dart
// HTML fixture for thread parsing
final html = file.readAsStringSync();

// Assertions on parsed data
expect(detail.posts.isNotEmpty, isTrue);
expect(p0.author?.username, 'yhm31');
expect(p0.deviceType, '7 iOS');
```

### Missing Patterns
- **No factory classes** for test data
- **No shared fixtures** directory
- **No JSON fixtures** for model parsing

## Coverage

### Requirements
- **Target:** Not enforced
- **Command:**
  ```bash
  cd nga_app && fvm flutter test --coverage
  ```

### View Coverage
```bash
cd nga_app && fvm flutter test --coverage && lcov --remove coverage/lcov.info 'lib/main.dart' -o coverage/lcov.filtered && genhtml coverage/lcov.filtered -o coverage/html && open coverage/html/index.html
```

### Current Coverage Gaps
| Area | Coverage |
|------|----------|
| Widget tests | Partial (smoke test only) |
| Unit tests | Parser only |
| Services | 0% (ForumCategoryService, NgaCookieStore, NgaHttpClient) |
| Models | 0% (ThreadDetail, ThreadPost, etc.) |
| HTTP client | 0% |
| Authentication | 0% |

## Test Types

### Unit Tests
- **Scope:** Pure functions, parsers, utilities
- **Location:** `test/parser/`
- **Examples:**
  - HTML parsing logic (`thread_parser_test.dart`)
  - URL utilities
  - JSON serialization

### Widget Tests
- **Scope:** UI components, app launch
- **Location:** `test/widget_test.dart`
- **Examples:**
  - Smoke test for app launch
  - Component rendering tests

### Integration Tests
- **Status:** Not used
- **Recommendation:** Add `integration_test` package for:
  - WebView interaction
  - Full user flows
  - Cookie-based authentication

## Common Patterns

### Async Testing
```dart
// Not currently in codebase - pattern from flutter_test docs
testWidgets('Async widget test', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  await tester.pumpAndSettle();  // Wait for async ops
  expect(find.text('Loaded'), findsOneWidget);
});
```

### Error Testing
```dart
// Not currently in codebase - pattern example
test('throws exception on invalid input', () {
  expect(() => parser.parse(''), throwsException);
});
```

### Matcher Examples
```dart
expect(value, isTrue);              // Boolean
expect(value, isFalse);             // Boolean
expect(value, isNull);              // Null check
expect(find.text('Title'), findsOneWidget);  // Widget finding
expect(find.text('Title'), findsNothing);    // Widget absence
expect(find.byType(MyWidget), findsNWidgets(3));  // Multiple widgets
```

---

*Testing analysis: 2026-01-23*
