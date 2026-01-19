# Architecture

Application architecture, data flow, and routing patterns.

## Table of Contents
- [Separation of Concerns](#separation-of-concerns)
- [Feature-based Organization](#feature-based-organization)
- [Data Flow](#data-flow)
- [Routing with GoRouter](#routing-with-gorouter)

---

## Separation of Concerns

Organize projects into logical layers similar to MVC/MVVM:

```
lib/
├── main.dart
├── presentation/      # Widgets, screens, UI logic
│   ├── screens/
│   └── widgets/
├── domain/            # Business logic, use cases
│   ├── models/
│   └── services/
├── data/              # Data sources, repositories
│   ├── repositories/
│   └── api/
└── core/              # Shared utilities, extensions
    ├── utils/
    └── extensions/
```

### Layer Responsibilities

| Layer | Contents | Responsibilities |
|-------|----------|------------------|
| Presentation | Widgets, Screens | Display data, handle user input |
| Domain | Services, Use Cases | Business logic, validation rules |
| Data | Repositories, API Clients | Data fetching, caching, persistence |
| Core | Utilities, Extensions | Shared helpers, constants |

---

## Feature-based Organization

For larger projects, organize by feature:

```
lib/
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   ├── profile/
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   └── settings/
│       ├── presentation/
│       ├── domain/
│       └── data/
└── core/
    ├── router/
    ├── theme/
    └── utils/
```

**Benefits**:
- Improved navigability
- Better scalability
- Clear ownership per feature
- Easier to add/remove features

---

## Data Flow

### Repository Pattern

Abstract data sources for testability:

```dart
// Abstract repository
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<void> saveUser(User user);
}

// Concrete implementation
class ApiUserRepository implements UserRepository {
  final ApiClient _client;
  
  ApiUserRepository(this._client);
  
  @override
  Future<User> getUser(String id) async {
    final response = await _client.get('/users/$id');
    return User.fromJson(response.data);
  }
  
  @override
  Future<void> saveUser(User user) async {
    await _client.post('/users', data: user.toJson());
  }
}
```

### Data Structures

Define clear data models:

```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

---

## Routing with GoRouter

### Basic Setup

```dart
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'profile/:userId',
          name: 'profile',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return ProfileScreen(userId: userId);
          },
        ),
      ],
    ),
  ],
);

// In MaterialApp
MaterialApp.router(routerConfig: router);
```

### Navigation

```dart
// Navigate by path
context.go('/profile/123');

// Navigate by name
context.goNamed('profile', pathParameters: {'userId': '123'});

// Push (adds to stack)
context.push('/details');

// Pop
context.pop();
```

### Authentication Redirect

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authService.isLoggedIn;
    final isLoginPage = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginPage) {
      return '/login';
    }
    if (isLoggedIn && isLoginPage) {
      return '/';
    }
    return null; // No redirect
  },
  routes: [...],
);
```

### Shell Routes (Nested Navigation)

```dart
ShellRoute(
  builder: (context, state, child) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const AppBottomNav(),
    );
  },
  routes: [
    GoRoute(path: '/home', builder: ...),
    GoRoute(path: '/search', builder: ...),
    GoRoute(path: '/settings', builder: ...),
  ],
)
```

---

## Best Practices

- **Dependency direction**: Data → Domain → Presentation
- **Abstract external dependencies** for testability
- **Use Navigator** for short-lived screens (dialogs, temporary views)
- **Use GoRouter** for deep-linkable routes
- **Keep business logic out of widgets**
