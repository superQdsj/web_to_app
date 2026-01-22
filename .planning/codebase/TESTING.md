# Testing Patterns

**Analysis Date:** 2025-01-23

## Test Framework

**Runner:**
- `flutter_test` package ( Flutter's built-in testing framework)
- Config: No separate config file; uses Flutter defaults
- Dart SDK: ^3.10.7

**Assertion Library:**
- Built-in `expect()` from `flutter_test`
- Matcher functions: `equals`, `isTrue`, `isFalse`, `isNull`, `isNotNull`, `findsOneWidget`

**Run Commands:**
```bash
cd nga_app && fvm flutter test              # Run all tests
cd nga_app && fvm flutter test --coverage   # Run with coverage
cd nga_app && fvm flutter test test/parser/ # Run specific directory
```

## Test File Organization

**Location:**
- `nga_app/test/` for unit tests
- Co-located with parser in `nga_app/test/parser/thread_parser_test.dart`

**Naming:**
- `*_test.dart` suffix for test files
- Example: `widget_test.dart`, `thread_parser_test.dart`

**Structure:**
```
nga_app/
├── test/
│   ├── widget_test.dart           # Widget/integration tests
│   └── parser/
│       └── thread_parser_test.dart # Parser unit tests
```

## Test Structure

**Widget Tests:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nga_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NgaApp());
    expect(find.text('NGA Forum'), findsOneWidget);
  });
}
```

**Unit Tests (Parsers):**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nga_app/src/parser/thread_parser.dart';
import 'dart:io';

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
    expect(p0.author?.username, 'yhm31');
    expect(p0.author?.uid, 39748236);
  });
}
```

**Patterns:**
- `WidgetTester` for widget tests
- Direct `test()` for pure Dart functions
- File-based fixtures for parser tests

## Mocking

**Framework:**
- No mocking framework currently configured
- `package:mocktail` or `package:mockito` not in dependencies

**Current Approach:**
- File-based test data (`../private/nga_debug.html`)
- Direct instantiation of classes under test
- No external service mocking

**What to Mock:**
- HTTP responses: Use test fixture files
- File I/O: Read from test fixtures in `private/` directory

**What NOT to Mock:**
- Parser logic: Test against real HTML files
- Widget rendering: Use `testWidgets` with real widget tree

## Fixtures and Factories

**Test Data:**
- Located in `nga_app/private/nga_debug.html` (git-ignored)
- Real NGA forum HTML for parser validation

**Factory Pattern:**
- Not currently used
- Constructors with required params for object creation

**Example from `nga_app/lib/src/model/thread_detail.dart`:**
```dart
ThreadPost({
  this.pid,
  required this.floor,
  required this.author,
  required this.authorUid,
  required this.contentText,
  this.deviceType,
  this.postDate,
});
```

## Coverage

**Requirements:**
- No coverage enforcement configured
- Coverage available via `flutter test --coverage`

**View Coverage:**
```bash
cd nga_app && fvm flutter test --coverage
# Open coverage/lcov.info in browser or IDE
```

## Test Types

**Widget Tests:**
- Smoke tests for app launch
- Basic widget rendering verification
- Location: `nga_app/test/widget_test.dart`

**Unit Tests:**
- Parser validation against real HTML
- Data model parsing from JSON
- Location: `nga_app/test/parser/thread_parser_test.dart`

**Integration Tests:**
- Not currently implemented
- Would require integration_test package

## Common Patterns

**Async Testing:**
- Widget tests use `testWidgets` with async/await
- `await tester.pumpWidget()` for widget rendering
- Example from `widget_test.dart`:
```dart
testWidgets('App launches smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(const NgaApp());
  expect(find.text('NGA Forum'), findsOneWidget);
});
```

**Error Testing:**
- Tests throw exceptions for missing fixtures
- No specific error assertion pattern

**Assertions:**
- `expect(actual, matcher)` for assertions
- Common matchers: `isTrue`, `equals(...)`, `findsOneWidget`

## Test Configuration

**pubspec.yaml Dev Dependencies:**
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

**No Additional Test Configuration:**
- Uses Flutter defaults
- No custom test configuration file

---

*Testing analysis: 2025-01-23*
