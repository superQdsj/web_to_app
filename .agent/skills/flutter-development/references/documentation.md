# Documentation & Accessibility

Documentation standards, dartdoc guidelines, and accessibility best practices.

## Table of Contents
- [Documentation Philosophy](#documentation-philosophy)
- [Dartdoc Style](#dartdoc-style)
- [Commenting Guidelines](#commenting-guidelines)
- [Accessibility (A11Y)](#accessibility-a11y)

---

## Documentation Philosophy

- **Comment wisely**: Explain *why*, not *what*
- **Document for the user**: Answer real questions
- **No useless documentation**: Don't restate the obvious
- **Consistency**: Use consistent terminology

```dart
// ❌ Useless: restates the obvious
/// Returns the user's name.
String get name => _name;

// ✅ Useful: explains non-obvious behavior
/// Returns the user's display name, falling back to email if name is empty.
String get displayName => name.isNotEmpty ? name : email;
```

---

## Dartdoc Style

### Basic Format

```dart
/// Single-sentence summary ending with a period.
///
/// Additional details in separate paragraph after blank line.
/// Can span multiple lines.
///
/// Example:
/// ```dart
/// final user = User(name: 'John');
/// print(user.greet()); // Hello, John!
/// ```
String greet() => 'Hello, $name!';
```

### Key Rules

1. **Use `///`** for doc comments (not `/* */`)
2. **Start with summary**: Single sentence, ends with period
3. **Separate paragraphs**: Blank `///` line after summary
4. **Don't repeat context**: Avoid restating class name or signature

### Documenting Parameters

Use prose, not `@param`:

```dart
/// Fetches user data from the server.
///
/// The [id] must be a valid UUID. If [includeProfile] is true,
/// the full profile data is fetched (slower but more complete).
///
/// Throws [NotFoundException] if user doesn't exist.
Future<User> fetchUser(String id, {bool includeProfile = false});
```

### Getters and Setters

Document only one (usually the getter):

```dart
/// The user's current score, between 0 and 100.
int get score => _score;
set score(int value) => _score = value.clamp(0, 100);
```

---

## Commenting Guidelines

### When to Comment

```dart
// ✅ Explain non-obvious logic
// Using bitwise AND for performance in hot path
final result = value & 0xFF;

// ✅ Document workarounds
// TODO(#1234): Remove when API supports pagination
final allItems = await fetchAllItems();

// ✅ Clarify intent
// Skip first item as it's the header row
for (var i = 1; i < rows.length; i++) { ... }
```

### When NOT to Comment

```dart
// ❌ Don't state the obvious
// Increment counter
counter++;

// ❌ Don't explain clear code
// Check if user is logged in
if (user.isLoggedIn) { ... }
```

### Style Rules

- **Be brief**: Write concisely
- **Avoid jargon**: No unexplained abbreviations
- **Use backticks**: For code references
- **No trailing comments**: Put comments on their own line

---

## Accessibility (A11Y)

Implement accessibility to empower all users.

### Color Contrast

Ensure text has contrast ratio of **4.5:1** against background.

```dart
// Use theme colors with proper contrast
Text(
  'Important text',
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
  ),
)
```

### Dynamic Text Scaling

Test UI with increased system font sizes:

```dart
// Don't hardcode text sizes that break at larger scales
// Use theme-based text styles
Text('Hello', style: Theme.of(context).textTheme.bodyMedium)
```

### Semantic Labels

Use `Semantics` widget for screen readers:

```dart
Semantics(
  label: 'Profile picture for John Doe',
  child: CircleAvatar(
    backgroundImage: NetworkImage(user.avatarUrl),
  ),
)

// For buttons with icons only
IconButton(
  icon: const Icon(Icons.delete),
  tooltip: 'Delete item', // Provides accessibility label
  onPressed: onDelete,
)
```

### Focusable Elements

Ensure interactive elements are focusable:

```dart
Focus(
  onFocusChange: (hasFocus) {
    setState(() => _isFocused = hasFocus);
  },
  child: Container(
    decoration: BoxDecoration(
      border: _isFocused ? Border.all(color: Colors.blue, width: 2) : null,
    ),
    child: MyInteractiveWidget(),
  ),
)
```

### Testing Accessibility

Regularly test with:
- **TalkBack** (Android)
- **VoiceOver** (iOS)

```dart
testWidgets('button is accessible', (tester) async {
  await tester.pumpWidget(MyApp());
  
  final semantics = tester.getSemantics(find.byType(ElevatedButton));
  expect(semantics.label, equals('Submit form'));
});
```
