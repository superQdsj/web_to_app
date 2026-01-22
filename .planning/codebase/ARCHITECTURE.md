# Architecture

**Analysis Date:** 2026-01-23

## Pattern Overview

**Overall:** Layered Clean Architecture with Flutter-specific adaptations

**Key Characteristics:**
- Clear separation between UI (presentation), business logic, and data access
- StatelessWidget/StatefulWidget for UI with ValueNotifier for reactive state
- Repository pattern for data abstraction
- HTML parsing layer for web scraping NGA forum content
- Singleton stores for global state (cookie, user, forum)

## Layers

**Presentation Layer (UI):**
- Purpose: Render UI, handle user interactions
- Location: `nga_app/lib/screens/`
- Contains: `HomeScreen`, `ForumScreen`, `ThreadScreen`, `LoginWebViewSheet`
- Sub-layer: Reusable widgets in `screens/widgets/`
- Sub-layer: Thread screen parts using `part` directives in `screens/thread/`

**Service Layer:**
- Purpose: Business logic and data loading
- Location: `nga_app/lib/src/services/`
- Contains: `ForumCategoryService` - loads forum categories from JSON assets
- Pattern: Static methods with caching

**Repository Layer:**
- Purpose: Coordinate data fetching and parsing
- Location: `nga_app/lib/data/nga_repository.dart`
- Contains: `NgaRepository` - orchestrates HTTP client, decoding, and parsers
- Depends on: `NgaHttpClient`, `DecodeBestEffort`, `ForumParser`, `ThreadParser`
- Used by: Screen widgets for data operations

**HTTP/Network Layer:**
- Purpose: HTTP requests with cookie authentication
- Location: `nga_app/lib/src/http/nga_http_client.dart`
- Contains: `NgaHttpClient`, `NgaHttpResponse`
- Features: Custom User-Agent, cookie header injection, timeout handling

**Parser Layer:**
- Purpose: Parse HTML responses into typed objects
- Location: `nga_app/lib/src/parser/`
- Contains: `ForumParser`, `ThreadParser`
- Uses: `package:html/parser`

**Model Layer:**
- Purpose: Data structures with JSON serialization
- Location: `nga_app/lib/src/model/`
- Contains: `ThreadItem`, `ThreadDetail`, `ForumCategory`, `ForumBoard`, `ForumSubcategory`
- Pattern: Plain Dart classes with `fromJson` factory constructors

**Auth/State Stores:**
- Purpose: Global reactive state for authentication and app state
- Location: `nga_app/lib/src/auth/`, `nga_app/lib/src/nga_forum_store.dart`
- Contains: `NgaCookieStore`, `NgaUserStore`, `NgaForumStore`
- Pattern: Singleton with `ValueNotifier` for reactive updates

**Utility Layer:**
- Purpose: Encoding detection and URL utilities
- Location: `nga_app/lib/src/codec/`, `nga_app/lib/src/util/`
- Contains: `DecodeBestEffort`, `url_utils`

**Theme Layer:**
- Purpose: Centralized theming with Material 3
- Location: `nga_app/lib/theme/`
- Contains: `NgaTheme`, `NgaColors`, `NgaTypography`
- Features: Light/dark theme with custom color scheme

## Data Flow

**Fetching Forum Threads:**

1. User selects a forum board from `MenuDrawerGrid`
2. `NgaForumStore.activeFid` is updated
3. `ForumContent` widget observes the change and calls `_fetchThreads()`
4. `ForumContent` creates `NgaRepository` instance with cookie
5. `NgaRepository.fetchForumThreads()` builds URL with fid/page
6. `NgaHttpClient.getBytes()` makes HTTP request with cookie header
7. Response body decoded via `DecodeBestEffort`
8. `ForumParser.parseForumThreadList()` extracts HTML data
9. `ThreadItem` objects returned and displayed in `ListView`

**Authentication Flow:**

1. User taps avatar button to open `ProfileDrawer`
2. `LoginWebViewSheet` displayed as modal bottom sheet
3. WebView loads NGA login page
4. JavaScript hook injects `NGA_LOGIN_SUCCESS` channel
5. On successful login, cookies detected via `login_set_cookie_quick` or JS callback
6. `NgaCookieStore.setCookie()` updates global state
7. `NgaCookieStore.saveToStorage()` persists to SharedPreferences
8. WebView closes and app refreshes data

**State Management:**
- `ValueNotifier` for simple reactive state (cookie, user, activeFid)
- `setState()` for local widget state (loading, error, lists)
- No external state management library (Riverpod, Bloc, etc.)

## Key Abstractions

**Repository Pattern:**
- `NgaRepository` abstracts HTTP and parsing details from UI
- Constructor accepts cookie and optional client
- Methods return typed objects: `List<ThreadItem>`, `ThreadDetail`

**Store Pattern:**
- Static singleton classes with `ValueNotifier`
- `NgaCookieStore.cookie` - global auth state
- `NgaUserStore.user` - authenticated user info
- `NgaForumStore.activeFid` - current forum selection
- Load/save from SharedPreferences for persistence

**Parser Pattern:**
- Single-purpose classes with parsing methods
- `ForumParser.parseForumThreadList(String htmlText)`
- `ThreadParser.parseThreadPage(...)`
- Returns typed domain models

## Entry Points

**main.dart:**
- Location: `nga_app/lib/main.dart`
- Responsibilities: Initialize stores, run app with MaterialApp
- Initializes: `NgaCookieStore.loadFromStorage()`, `NgaUserStore.loadFromStorage()`

**HomeScreen:**
- Location: `nga_app/lib/screens/home_screen.dart`
- Triggers: App launch (set as `home` in MaterialApp)
- Responsibilities: Scaffold with drawers, contains `ForumContent`

**ForumContent:**
- Location: `nga_app/lib/screens/forum_screen.dart`
- Triggers: `NgaForumStore.activeFid` changes, cookie changes
- Responsibilities: Display thread list, handle pagination

**ThreadScreen:**
- Location: `nga_app/lib/screens/thread_screen.dart`
- Triggers: User taps thread in list
- Responsibilities: Display posts, handle pagination, reply composer
- Uses: `part` directives for modular components

## Error Handling

**Strategy:** Try/catch with widget state updates

**Patterns:**
- Screen methods wrap async calls in try/catch
- Error state stored in widget local state (`_error`, `_loadMoreError`)
- Error banner displayed at top of screen
- Debug logging via `debugPrint` with `[NGA]` prefix

**Examples:**
```dart
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

**Logging:** `debugPrint` with `[NGA]` prefix for NGA-specific logs, conditionally skipped in release builds with `kDebugMode`

**Validation:** Parsers skip invalid data gracefully (continue on null fields, return empty lists on no matches)

**Authentication:** Cookie-based via SharedPreferences; WebView for login capture; singleton store for app-wide access

**Encoding:** `DecodeBestEffort` handles GBK/GB2312 detection for NGA's Chinese encoding

**Theming:** Centralized `NgaTheme` with Material 3; custom colors via `ColorScheme.fromSeed()`; light/dark theme toggle

---

*Architecture analysis: 2026-01-23*
