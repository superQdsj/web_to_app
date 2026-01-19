# Code Quality

Dart and Flutter best practices, coding standards, and API design principles.

## Table of Contents
- [Naming Conventions](#naming-conventions)
- [Code Style](#code-style)
- [Dart Best Practices](#dart-best-practices)
- [Flutter Best Practices](#flutter-best-practices)
- [API Design Principles](#api-design-principles)
- [Lint Rules](#lint-rules)

---

## Naming Conventions

| Element | Style | Example |
|---------|-------|---------|
| Classes | `PascalCase` | `UserProfile`, `HttpClient` |
| Variables, functions | `camelCase` | `userName`, `fetchData()` |
| Enums | `camelCase` | `connectionState.active` |
| Files | `snake_case` | `user_profile.dart` |
| Constants | `camelCase` | `defaultTimeout` |

**Guidelines**:
- Avoid abbreviations
- Use meaningful, descriptive names
- Keep names consistent throughout codebase

---

## Code Style

### Line Length
Lines should be **80 characters or fewer**.

### Functions
Keep functions short with a single purpose (strive for < 20 lines).

```dart
// ✅ Good: Single purpose
Future<User> fetchUser(String id) async {
  final response = await _client.get('/users/$id');
  return User.fromJson(response.data);
}

// ❌ Avoid: Multiple responsibilities
Future<void> loadAndDisplayUser(String id) async {
  // Fetching
  final response = await _client.get('/users/$id');
  final user = User.fromJson(response.data);
  // Caching
  await _cache.save(user);
  // UI update
  _controller.updateUser(user);
  // Analytics
  _analytics.logUserLoaded(id);
}
```

### Arrow Functions
Use for simple one-line functions:

```dart
String get fullName => '$firstName $lastName';
bool get isEmpty => items.isEmpty;
```

### Trailing Comments
Don't add trailing comments.

```dart
// ✅ Good
final count = items.length;

// ❌ Avoid
final count = items.length; // Get the count
```

---

## Dart Best Practices

### Null Safety
Write soundly null-safe code. Avoid `!` unless value is guaranteed non-null.

```dart
// ✅ Good: Handle null explicitly
final name = user?.name ?? 'Unknown';

// ❌ Avoid: Force unwrap
final name = user!.name;
```

### Async/Await
Use properly with robust error handling.

```dart
Future<void> loadData() async {
  try {
    final data = await fetchData();
    setState(() => _data = data);
  } on NetworkException catch (e) {
    _showError('Network error: ${e.message}');
  } catch (e, stackTrace) {
    developer.log('Unexpected error', error: e, stackTrace: stackTrace);
  }
}
```

### Pattern Matching

```dart
switch (result) {
  case Success(:final data):
    return DataWidget(data: data);
  case Error(:final message):
    return ErrorWidget(message: message);
}
```

### Records
Use for returning multiple values:

```dart
(String, int) parseUserInfo(String input) {
  // Parse logic
  return (name, age);
}

// Usage
final (name, age) = parseUserInfo(input);
```

### Switch Expressions
Prefer exhaustive switch:

```dart
String getStatusText(Status status) => switch (status) {
  Status.loading => 'Loading...',
  Status.success => 'Done!',
  Status.error => 'Failed',
};
```

---

## Flutter Best Practices

### Composition Over Inheritance

```dart
// ✅ Good: Compose widgets
class UserCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          UserAvatar(user: user),
          UserDetails(user: user),
        ],
      ),
    );
  }
}

// ❌ Avoid: Deep inheritance
class UserCard extends BaseCard { ... }
```

### Private Widget Classes
Use instead of helper methods:

```dart
// ✅ Good: Private widget class
class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.url});
  final String url;
  
  @override
  Widget build(BuildContext context) => CircleAvatar(...);
}

// ❌ Avoid: Helper method returning widget
Widget _buildAvatar() => CircleAvatar(...);
```

### Const Constructors

```dart
// ✅ Reduces rebuilds
const SizedBox(height: 16),
const Padding(
  padding: EdgeInsets.all(8),
  child: Icon(Icons.star),
),
```

### List Performance

```dart
// ✅ Lazy loading for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(item: items[index]),
)
```

### Isolates for Expensive Work

```dart
// Move expensive computation off UI thread
final result = await compute(parseJson, jsonString);
```

---

## API Design Principles

When building reusable APIs:

1. **Consider the User**: Design from consumer perspective
2. **Intuitive Interface**: Easy to use correctly, hard to misuse
3. **Documentation is Essential**: Clear, concise, with examples

```dart
/// Fetches user by [id] from the API.
///
/// Throws [NotFoundException] if user doesn't exist.
///
/// Example:
/// ```dart
/// final user = await repository.getUser('123');
/// print(user.name);
/// ```
Future<User> getUser(String id);
```

---

## Lint Rules

Use `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
    prefer_const_constructors: true
    prefer_const_declarations: true

analyzer:
  errors:
    missing_required_param: error
    missing_return: error
```

### Logging
Use `dart:developer` instead of `print`:

```dart
import 'dart:developer' as developer;

developer.log('User logged in', name: 'auth');
```
