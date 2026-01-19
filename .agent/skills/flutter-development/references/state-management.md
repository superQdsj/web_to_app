# State Management

Flutter's built-in state management solutions. Prefer these over third-party packages unless explicitly requested.

## Table of Contents
- [ValueNotifier](#valuenotifier)
- [ChangeNotifier](#changenotifier)
- [Streams & Futures](#streams--futures)
- [MVVM Pattern](#mvvm-pattern)
- [Dependency Injection](#dependency-injection)

---

## ValueNotifier

Use for simple, local state involving a single value.

```dart
// Define a ValueNotifier to hold the state
final ValueNotifier<int> _counter = ValueNotifier<int>(0);

// Use ValueListenableBuilder to listen and rebuild
ValueListenableBuilder<int>(
  valueListenable: _counter,
  builder: (context, value, child) {
    return Text('Count: $value');
  },
);

// Update the value
_counter.value++;
```

---

## ChangeNotifier

For complex state shared across multiple widgets.

```dart
class CartModel extends ChangeNotifier {
  final List<Item> _items = [];
  
  List<Item> get items => List.unmodifiable(_items);
  
  void add(Item item) {
    _items.add(item);
    notifyListeners();
  }
  
  void remove(Item item) {
    _items.remove(item);
    notifyListeners();
  }
}

// Use ListenableBuilder to listen
ListenableBuilder(
  listenable: cartModel,
  builder: (context, child) {
    return Text('Items: ${cartModel.items.length}');
  },
);
```

---

## Streams & Futures

### FutureBuilder
For single asynchronous operations.

```dart
FutureBuilder<User>(
  future: fetchUser(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    return Text('Hello, ${snapshot.data!.name}');
  },
);
```

### StreamBuilder
For sequences of asynchronous events.

```dart
StreamBuilder<int>(
  stream: counterStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Text('Waiting...');
    }
    return Text('Count: ${snapshot.data}');
  },
);
```

---

## MVVM Pattern

Structure for robust state management:

```dart
// Model
class User {
  final String id;
  final String name;
  User({required this.id, required this.name});
}

// ViewModel
class UserViewModel extends ChangeNotifier {
  final UserRepository _repository;
  User? _user;
  bool _loading = false;
  
  UserViewModel(this._repository);
  
  User? get user => _user;
  bool get loading => _loading;
  
  Future<void> loadUser(String id) async {
    _loading = true;
    notifyListeners();
    
    _user = await _repository.getUser(id);
    _loading = false;
    notifyListeners();
  }
}

// View
class UserScreen extends StatelessWidget {
  final UserViewModel viewModel;
  
  const UserScreen({super.key, required this.viewModel});
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        if (viewModel.loading) {
          return const CircularProgressIndicator();
        }
        return Text(viewModel.user?.name ?? 'No user');
      },
    );
  }
}
```

---

## Dependency Injection

Use simple manual constructor injection:

```dart
// Repository abstraction
abstract class UserRepository {
  Future<User> getUser(String id);
}

// Concrete implementation
class ApiUserRepository implements UserRepository {
  final HttpClient _client;
  
  ApiUserRepository(this._client);
  
  @override
  Future<User> getUser(String id) async {
    // Implementation
  }
}

// Inject via constructor
final viewModel = UserViewModel(ApiUserRepository(httpClient));
```

> **Note**: If a DI solution beyond manual injection is explicitly requested, consider `provider` package.
