# Architecture

**Analysis Date:** 2026-01-23

## Pattern Overview

**Overall:** Layered Clean Architecture with Static State Management

**Key Characteristics:**
- **Layered separation**: Presentation (UI) → Services → Repository → Data Source
- **Static stores for global state**: Uses `ValueNotifier` singletons for cookie, user, and forum state
- **Parser-driven data extraction**: HTML parsing layer extracts structured data from NGA forum responses
- **Repository pattern**: `NgaRepository` orchestrates HTTP calls and parsing logic
- **Widget-based composition**: Screens compose reusable widgets; minimal business logic in UI layer

## Layers

**Presentation Layer (Screens & Widgets):**
- Purpose: Render UI, handle user interaction, display data
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/`
- Contains: Stateful/Stateless widgets, screen controllers, user input handlers
- Depends on: Services, Models, Stores
- Used by: Flutter framework (MaterialApp router)

**Services Layer:**
- Purpose: Business logic for data operations (loading categories, icons)
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/services/`
- Contains: `ForumCategoryService` (static methods, in-memory cache)
- Depends on: Models, Flutter services (rootBundle)
- Used by: UI layer (widgets), other services

**Repository Layer:**
- Purpose: Coordinate HTTP fetching and HTML parsing; provide clean API to screens
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/data/nga_repository.dart`
- Contains: `NgaRepository` class
- Depends on: HTTP client, Parsers, Models
- Used by: Screen state classes (ForumContentState)

**Data Layer (Core):**
- Purpose: HTTP communication, HTML parsing, encoding/decoding
- Location:
  - HTTP: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/http/nga_http_client.dart`
  - Parsers: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/`
  - Codecs: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/codec/`
  - Models: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/model/`
- Contains: HTTP client, parsers (ForumParser, ThreadParser), models (ThreadItem, ThreadDetail, ForumCategory)
- Depends on: dart:io, dart:async, package:http, package:html
- Used by: Repository layer

**State Management Layer (Stores):**
- Purpose: Global reactive state for authentication, user info, active forum
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/`, `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/nga_forum_store.dart`
- Contains: `NgaCookieStore`, `NgaUserStore`, `NgaForumStore`
- Pattern: Static singletons with `ValueNotifier`
- Depends on: shared_preferences (persistence)
- Used by: All layers via listener pattern

**Theme Layer:**
- Purpose: Centralized styling for light/dark modes
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/theme/`
- Contains: `NgaTheme`, `NgaColors`, `NgaTypography`
- Used by: All widgets via `Theme.of(context)`

## Data Flow

**Forum Thread List Flow:**

1. User selects board from `MenuDrawerGrid` (calls `NgaForumStore.setActiveFid()`)
2. `ForumContent` state detects `activeFid` change via listener
3. Creates `NgaRepository` instance with current cookie
4. Calls `repository.fetchForumThreads(fid, page)`
5. `NgaRepository`:
   - Constructs URL with `thread.php?fid=...`
   - Calls `NgaHttpClient.getBytes()` with cookie header
   - Decodes response via `DecodeBestEffort`
   - Parses HTML via `ForumParser.parseForumThreadList()`
6. Returns `List<ThreadItem>` to screen
7. `ForumContent` updates state, renders `ListView`

**Thread Detail Flow:**

1. User taps thread in list (`_openThread`)
2. `Navigator.push()` creates `ThreadScreen(tid: tid, title: title)`
3. `ThreadScreenState` calls `repository.fetchThread(tid)`
4. `NgaRepository`:
   - Constructs URL with `read.php?tid=...`
   - Fetches and decodes response
   - Parses via `ThreadParser.parseThreadPage()`
5. Returns `ThreadDetail` (contains `List<ThreadPost>`)
6. Renders thread posts

**Login Flow:**

1. User taps avatar → opens `LoginWebViewSheet`
2. `WebViewController` loads NGA login page
3. JavaScript channel intercepts `loginSuccess` console logs
4. `NgaUserStore.setUser()` captures user info
5. `WebviewCookieManager` extracts cookies
6. `NgaCookieStore.setCookie()` + `saveToStorage()` persists auth
7. Sheet closes; listeners in `ForumContent` auto-refresh

**State Management:**
- `ValueNotifier` pattern: Stores emit updates, widgets rebuild via `addListener` or `ValueListenableBuilder`
- Persistence: `SharedPreferences` for cookie/user storage (async load/save)

## Key Abstractions

**Repository Pattern:**
- Purpose: Abstract data fetching behind clean API
- Examples: `NgaRepository` in `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/data/nga_repository.dart`
- Pattern: Single class orchestrates HTTP + parsing; exposed methods return typed models

**Static Store Pattern:**
- Purpose: Global reactive singleton state
- Examples:
  - `NgaCookieStore` in `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_cookie_store.dart`
  - `NgaUserStore` in `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_user_store.dart`
  - `NgaForumStore` in `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/nga_forum_store.dart`
- Pattern: Private constructor + static `ValueNotifier` fields + static methods

**Parser Pattern:**
- Purpose: Convert HTML strings to typed Dart objects
- Examples:
  - `ForumParser` in `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/forum_parser.dart`
  - `ThreadParser` in `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/thread_parser.dart`
- Pattern: Constructor + parse methods returning model lists

## Entry Points

**App Entry:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/main.dart`
- Triggers: `main()` async function
- Responsibilities:
  1. Initialize `WidgetsFlutterBinding`
  2. Load cookies and user from `SharedPreferences`
  3. Run `NgaApp` (StatelessWidget)

**Main App Widget:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/main.dart` (`NgaApp` class)
- Responsibilities:
  1. Configure `MaterialApp` with title, theme, darkTheme
  2. Set `themeMode: ThemeMode.system` (follow system)
  3. Set `home: HomeScreen()`

**Home Screen:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/home_screen.dart` (`HomeScreen`)
- Responsibilities:
  1. Scaffold with AppBar, left drawer (MenuDrawerGrid), right drawer (ProfileDrawer)
  2. Body contains `ForumContent` widget
  3. AppBar leading: `MenuButton` (opens left drawer)
  4. AppBar actions: `AvatarButton` (opens right drawer, triggers login)

**Forum Content:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/forum_screen.dart` (`ForumContent`)
- Responsibilities:
  1. Listen to `NgaCookieStore` and `NgaForumStore`
  2. Fetch and display thread list
  3. Handle pagination (load more on scroll)
  4. Navigate to `ThreadScreen` on tap

**Thread Screen:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/thread_screen.dart` (`ThreadScreen`)
- Responsibilities:
  1. Fetch thread detail by `tid`
  2. Display posts in scrollable list
  3. Handle reply composition

## Error Handling

**Strategy:** Try-catch with user-facing error banners

**Patterns:**
- Repository layer throws `Exception` with descriptive messages
- Screen state catches exceptions, sets `_error` state variable
- UI displays error banner when `_error != null`
- Debug mode uses `debugPrint()` for logging; production silent

**Examples:**
```dart
// In ForumContentState
try {
  final threads = await _repository.fetchForumThreads(fid, page: 1);
  setState(() {
    _threads.addAll(uniqueThreads);
    _loading = false;
  });
} catch (e) {
  setState(() {
    _error = e.toString();
    _loading = false;
  });
}
```

## Cross-Cutting Concerns

**Logging:** `debugPrint()` guarded by `kDebugMode` checks
- Prefix: `[NGA]` for easy filtering
- Examples in `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_cookie_store.dart`, `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/data/nga_repository.dart`

**Validation:**
- Model `fromJson` factories validate required fields
- `ForumBoard`, `ForumSubcategory`, `ForumCategory` throw on missing required data
- Helper parsers: `_parseRequiredInt()`, `_parseRequiredString()`

**Authentication:**
- WebView-based login captures cookies from browser session
- Cookie stored in `SharedPreferences` via `NgaCookieStore`
- Cookie header sent with every HTTP request via `NgaHttpClient`
- User info captured from JS console log `loginSuccess` message

**Theming:**
- Centralized in `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/theme/`
- `NgaTheme.light` and `NgaTheme.dark` static getters
- Custom `NgaColors` extension for app-specific colors
- `NgaTypography` for text theme consistency

---

*Architecture analysis: 2026-01-23*
