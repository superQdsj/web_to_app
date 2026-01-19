# Testing

Comprehensive testing guide for Flutter applications.

## Table of Contents
- [Running Tests](#running-tests)
- [Unit Tests](#unit-tests)
- [Widget Tests](#widget-tests)
- [Integration Tests](#integration-tests)
- [Mocking](#mocking)

---

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

---

## Unit Tests

Use `package:test` for testing business logic.

```dart
import 'package:test/test.dart';

void main() {
  group('Calculator', () {
    late Calculator calculator;

    setUp(() {
      calculator = Calculator();
    });

    test('adds two numbers', () {
      // Arrange
      const a = 2;
      const b = 3;

      // Act
      final result = calculator.add(a, b);

      // Assert
      expect(result, equals(5));
    });
  });
}
```

### Using package:checks

Prefer `package:checks` for expressive assertions:

```dart
import 'package:checks/checks.dart';

test('user has valid email', () {
  final user = User(email: 'test@example.com');
  
  check(user.email)
    .isNotNull()
    .contains('@')
    .endsWith('.com');
});
```

---

## Widget Tests

Use `package:flutter_test` for testing UI components.

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Arrange: Build the widget
    await tester.pumpWidget(const MyApp());

    // Assert: Initial state
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Act: Tap the button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Assert: Updated state
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
```

### Finders

```dart
find.text('Hello')              // Find by text
find.byType(ElevatedButton)     // Find by widget type
find.byKey(const Key('submit')) // Find by key
find.byIcon(Icons.add)          // Find by icon
```

### Interactions

```dart
await tester.tap(finder);       // Tap
await tester.enterText(finder, 'text'); // Enter text
await tester.drag(finder, const Offset(0, -300)); // Drag/scroll
await tester.pump();            // Rebuild after state change
await tester.pumpAndSettle();   // Wait for animations
```

---

## Integration Tests

Use `package:integration_test` for end-to-end testing.

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### Test File

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to details
    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();

    expect(find.text('Details Screen'), findsOneWidget);
  });
}
```

### Run Integration Tests

```bash
flutter test integration_test/app_test.dart
```

---

## Mocking

Prefer fakes or stubs over mocks. If mocks are necessary, use `mockito` or `mocktail`.

### Using Fakes

```dart
// Fake implementation for testing
class FakeUserRepository implements UserRepository {
  @override
  Future<User> getUser(String id) async {
    return User(id: id, name: 'Test User');
  }
}

// In test
test('loads user', () async {
  final viewModel = UserViewModel(FakeUserRepository());
  await viewModel.loadUser('123');
  
  expect(viewModel.user?.name, equals('Test User'));
});
```

### Using Mocktail

```dart
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockRepo;
  late UserViewModel viewModel;

  setUp(() {
    mockRepo = MockUserRepository();
    viewModel = UserViewModel(mockRepo);
  });

  test('handles error', () async {
    when(() => mockRepo.getUser(any()))
        .thenThrow(Exception('Network error'));

    await viewModel.loadUser('123');

    expect(viewModel.error, isNotNull);
  });
}
```

---

## Best Practices

- Follow **Arrange-Act-Assert** (Given-When-Then) pattern
- Write unit tests for domain logic and data layer
- Write widget tests for UI components
- Write integration tests for end-to-end flows
- Aim for high test coverage
- Avoid code generation for mocks when possible
