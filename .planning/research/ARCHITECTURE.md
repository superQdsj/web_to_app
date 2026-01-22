# Flutter Forum App Architecture

**Domain:** Mobile forum client application
**Researched:** 2026-01-23
**Confidence:** HIGH (based on codebase analysis + Flutter best practices)

## Recommended Architecture

The NGA Forum app follows a layered architecture with clear component boundaries. The current implementation shows good separation of concerns, but several enhancements are recommended for performance, maintainability, and iOS-native feel.

### Overall Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   HomeScreen    │  │  ForumScreen    │  │  ThreadScreen   │  │
│  │   (Navigation)  │  │  (Forum List)   │  │  (Thread View)  │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │                    │                    │            │
│  ┌────────┴────────────────────┴────────────────────┴────────┐  │
│  │                    Shared Widgets                          │  │
│  │  MenuDrawer  ProfileDrawer  AvatarButton  ThreadPostWidget │  │
│  └────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                         State Layer                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  NgaCookieStore │  │  NgaForumStore  │  │  NgaUserStore   │  │
│  │  (ValueNotifier)│  │  (ValueNotifier)│  │  (ValueNotifier)│  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                        Data Layer                                │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    NgaRepository                             │ │
│  │  fetchForumThreads()  fetchThread()  _decodeResponse()       │ │
│  └────────────────────────────┬────────────────────────────────┘ │
│                               │                                  │
│  ┌────────────────────────────┴────────────────────────────────┐ │
│  │                      Parsers                                 │ │
│  │  ForumParser  ThreadParser  Hybrid + Legacy fallback         │ │
│  └────────────────────────────┬────────────────────────────────┘ │
│                               │                                  │
│  ┌────────────────────────────┴────────────────────────────────┐ │
│  │                      HTTP Layer                              │ │
│  │  NgaHttpClient  (IOClient wrapper with timeout, encoding)    │ │
│  └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                      External Services                           │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  NGA Web (bbs.nga.cn)  SharedPreferences  WebView (Login)   │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **Screens** | UI composition, user interaction handling | Widgets, State Stores, Repository |
| **Widgets** | Reusable UI elements | Screens (via callbacks) |
| **State Stores** | Global app state (cookie, active forum, user) | Screens, Repository |
| **Repository** | Data orchestration (fetch, parse, return) | State Stores, Parsers, HTTP |
| **Parsers** | HTML -> Domain Models | Repository |
| **HTTP Client** | Network requests | Repository |

### Key Boundary Rules

1. **Screens never call HTTP directly** - Always go through Repository
2. **Parsers are pure functions** - No side effects, same HTML -> same output
3. **State stores are reactive** - Use ValueNotifier for loose coupling
4. **Repository owns parsing logic** - Screens don't know about HTML structure

## Data Flow

### Read Flow (Thread View)

```
User taps thread
    │
    ▼
ThreadScreen.initState()
    │
    ▼
Repository.fetchThread(tid, page)
    │
    ▼
NgaHttpClient.getBytes(url, cookie)
    │
    ▼
_decodeResponse() [encoding detection]
    │
    ▼
ThreadParser.parseThreadPage(html, tid, url, fetchedAt)
    │
    ▼
ThreadDetail (List<ThreadPost>)
    │
    ▼
ThreadScreen.setState() -> UI Update
```

### Write Flow (Login)

```
User taps avatar
    │
    ▼
LoginWebviewSheet (WebView)
    │
    ▼
WebView evaluates: document.cookie
    │
    ▼
NgaCookieStore.setCookie(cookieString)
    │
    ▼
ValueNotifier notifies listeners
    │
    ▼
All screens with cookie listener -> refresh data
```

### State Propagation

```
NgaCookieStore.cookie (ValueNotifier<String>)
    │
    ├──▶ ForumScreen._onCookieChanged() -> recreate Repository + fetch
    ├──▶ ThreadScreen._onCookieChanged() -> recreate Repository + fetch
    └──▶ ProfileDrawer -> update UI based on login state
```

## Current Architecture Assessment

### Strengths

| Aspect | Status | Notes |
|--------|--------|-------|
| Layer separation | Good | Clear boundaries between UI, data, network |
| Parser architecture | Good | Hybrid approach with legacy fallback |
| State management | Adequate | ValueNotifier works for simple cases |
| Error handling | Adequate | Try/catch with user feedback |
| Testing potential | Good | Parsers are pure functions |

### Areas for Enhancement

| Area | Current | Recommended | Priority |
|------|---------|-------------|----------|
| State management | ValueNotifier | Provider/Riverpod/Bloc | Medium |
| HTML parsing | Synchronous | Isolate-based parsing | High |
| Caching | None | Repository-level cache | High |
| Dependency injection | Manual | GetIt/Injector | Low |
| Navigation | Manual | GoRouter | Low |

## Build Order Implications

Based on component dependencies, here is the recommended build order for enhancements:

### Phase 1: Performance Foundation

**Dependencies established first:**
```
1. HTTP Client (no dependencies)
2. Parsers (no dependencies - pure functions)
3. Models (no dependencies)
4. Repository (depends on 1, 2, 3)
5. State Stores (no dependencies)
6. Screens (depends on 4, 5, widgets)
7. Widgets (no dependencies)
```

**Why this order:**
- Parsers must work before Repository can fetch data
- Repository must exist before Screens can display anything
- State Stores are lightweight, can be added anytime

### Phase 2: Performance Optimization

1. **HTML Parsing Isolation**
   - Move parsing to Isolate (compute/Isolate.run)
   - Benefits: Main thread stays responsive during large thread loads
   - Requires: Parser refactoring to be self-contained

2. **Repository-Level Caching**
   - Add memory cache for forum lists and thread details
   - Benefits: Faster navigation, reduced network
   - Requires: Cache invalidation strategy

### Phase 3: Architecture Refinements

1. **State Management Migration**
   - Consider Riverpod for type-safe state
   - Benefits: Better testing, dependency injection
   - Impact: Moderate refactoring of screens

2. **Navigation with GoRouter**
   - Deep linking support
   - Benefits: URL-based navigation, web support
   - Impact: Low (wrapper layer)

## iOS-Native UI Considerations

### Platform-Specific Patterns

| Pattern | Current | iOS-Native Approach |
|---------|---------|---------------------|
| Navigation | Material Scaffold | Use CupertinoNavigationBar |
| Lists | Material ListTile | Prefer CupertinoListTile |
| Loading | CircularProgressIndicator | CupertinoActivityIndicator |
| Refresh | RefreshIndicator | CupertinoSliverRefreshControl |
| Navigation drawer | Left drawer | Tab bar or bottom nav (more iOS-like) |

### Recommended iOS Adaptation

```dart
// Use Cupertino widgets for iOS
CupertinoPageScaffold(
  navigationBar: CupertinoNavigationBar(
    leading: MenuButton(),
    middle: Text('NGA Forum'),
    trailing: AvatarButton(),
  ),
  child: ForumContent(),
)
```

## HTML Parsing Architecture

### Current Approach: Hybrid Parser

The ThreadParser uses a hybrid approach combining:
1. **Regex** for metadata extraction (JSON-like data in script tags)
2. **DOM Parser** for post structure (table.postbox)
3. **Fallback** to legacy DOM-only parsing

### Performance Considerations

| Technique | Use Case | Performance |
|-----------|----------|-------------|
| Regex pre-extraction | Large HTML files | Fast (avoids full DOM) |
| DOM querySelectorAll | Finding elements | O(n) traversal |
| Element.text | Extracting content | Fast |
| String operations | All parsing | CPU-bound |

### Optimization Strategies

1. **Pre-filter with Regex** before DOM parsing
2. **Single DOM parse** per page (not per post)
3. **Isolate parsing** for threads > 100 posts
4. **Incremental parsing** for pagination

### Parser Test Strategy

```dart
// Parser tests should verify:
// 1. Correct extraction (test HTML fixtures)
// 2. Edge cases (missing fields, malformed HTML)
// 3. Performance (benchmarks on large threads)
// 4. Fallback behavior (hybrid -> legacy)
```

## Scalability Considerations

| User Scale | Challenge | Solution |
|------------|-----------|----------|
| 100 users | None | Current architecture handles |
| 10K users | API rate limits | Add request queuing, caching |
| 100K users | Server load | Reduce fetch frequency, aggressive caching |
| 1M users | Network efficiency | CDN, binary protocols (protobuf) |

### Immediate Scalability Improvements

1. **Add cache layer** in Repository
2. **Implement ETag** support in HTTP client
3. **Lazy load images** in thread posts
4. **Paginate** large post lists (virtual scrolling)

## Anti-Patterns to Avoid

### Anti-Pattern 1: State in Parsers
**What:** Parsers storing state between calls
**Why bad:** Race conditions, unpredictable results
**Instead:** Pure functions, stateless parsing

### Anti-Pattern 2: Direct HTTP in Screens
**What:** Screens calling NgaHttpClient directly
**Why bad:** Tight coupling, hard to test, no caching
**Instead:** All network goes through Repository

### Anti-Pattern 3: Synchronous UI Blocking
**What:** Parsing HTML on main thread for large threads
**Why bad:** UI freezes, poor UX
**Instead:** Use compute()/Isolate for parsing

### Anti-Pattern 4: String-Based State
**What:** Storing complex state as JSON strings
**Why bad:** No type safety, serialization errors
**Instead:** Strongly-typed models with toJson/fromJson

## File Structure Reference

```
nga_app/lib/
├── main.dart                 # App entry, theme configuration
├── data/
│   └── nga_repository.dart   # Data orchestration layer
├── screens/
│   ├── home_screen.dart      # Main scaffold with drawers
│   ├── forum_screen.dart     # Thread list (ForumContent)
│   ├── thread_screen.dart    # Post list with reply composer
│   └── widgets/              # Shared UI components
├── src/
│   ├── auth/
│   │   ├── nga_cookie_store.dart   # Cookie persistence
│   │   └── nga_user_store.dart     # User data persistence
│   ├── http/
│   │   └── nga_http_client.dart    # Network layer
│   ├── model/
│   │   ├── thread_detail.dart      # Thread/post models
│   │   ├── thread_item.dart        # Thread list item model
│   │   └── forum_category.dart     # Forum category model
│   ├── parser/
│   │   ├── thread_parser.dart      # Thread HTML parser
│   │   └── forum_parser.dart       # Forum list parser
│   ├── services/
│   │   └── forum_category_service.dart
│   ├── nga_forum_store.dart   # Active forum state
│   ├── nga_fetcher.dart       # Combined HTTP + parsing
│   └── util/
│       └── url_utils.dart     # URL helpers
└── theme/
    ├── app_theme.dart         # Light/dark theme
    ├── app_colors.dart        # Color palette
    └── app_typography.dart    # Typography scale
```

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Component boundaries | HIGH | Based on existing codebase analysis |
| Data flow | HIGH | Verified through code review |
| Build order | MEDIUM | Inferred from dependencies |
| iOS patterns | MEDIUM | Standard Cupertino patterns |
| Performance recommendations | MEDIUM | General Flutter best practices |

## Sources

- Existing codebase analysis (NGA Forum App)
- Flutter official documentation (flutter.dev)
- Dart documentation (dart.dev)
- flutter_html package patterns
- Cupertino design guidelines
