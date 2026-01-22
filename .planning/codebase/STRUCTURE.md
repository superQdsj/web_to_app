# Codebase Structure

**Analysis Date:** 2026-01-23

## Directory Layout

```
nga_app/
├── lib/
│   ├── main.dart                # App entry point
│   ├── screens/                 # UI screens and widgets
│   │   ├── home_screen.dart     # Main scaffold with drawers
│   │   ├── forum_screen.dart    # Forum thread list
│   │   ├── thread_screen.dart   # Thread detail view
│   │   ├── login_webview_sheet.dart  # WebView login modal
│   │   └── widgets/             # Reusable UI components
│   ├── data/                    # Repository layer
│   │   └── nga_repository.dart  # Data fetching orchestration
│   ├── theme/                   # Theming system
│   │   ├── app_theme.dart       # Light/dark themes
│   │   ├── app_colors.dart      # Custom color palette
│   │   └── app_typography.dart  # Text styles
│   └── src/                     # Core implementation
│       ├── auth/                # Authentication stores
│       ├── http/                # HTTP client
│       ├── parser/              # HTML parsers
│       ├── codec/               # Encoding/decoding
│       ├── model/               # Data models
│       ├── services/            # Business logic services
│       └── nga_fetcher.dart     # Barrel export
├── test/                        # Unit tests
├── assets/
│   └── data/                    # Static JSON data
│       └── forum_categories_merged.json
├── pubspec.yaml                 # Flutter dependencies
└── analysis_options.yaml        # Linting rules
```

## Directory Purposes

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/`:**
- Purpose: Page-level widgets and screen controllers
- Contains: `home_screen.dart`, `forum_screen.dart`, `thread_screen.dart`, `login_webview_sheet.dart`
- Key files: `home_screen.dart` (main scaffold), `forum_screen.dart` (thread list)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/widgets/`:**
- Purpose: Reusable UI components used across screens
- Contains: `avatar_button.dart`, `menu_button.dart`, `menu_drawer.dart`, `menu_drawer_grid.dart`, `profile_drawer.dart`
- Key files: `menu_drawer_grid.dart` (forum navigation), `profile_drawer.dart` (user profile)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/data/`:**
- Purpose: Repository layer - coordinate data fetching and parsing
- Contains: `nga_repository.dart`
- Key files: `nga_repository.dart` (single source for forum/thread data)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/theme/`:**
- Purpose: Centralized styling configuration
- Contains: `app_theme.dart`, `app_colors.dart`, `app_typography.dart`
- Key files: `app_theme.dart` (Material 3 theming with NGA colors)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/`:**
- Purpose: Authentication state management
- Contains: `nga_cookie_store.dart`, `nga_user_store.dart`
- Key files: `nga_cookie_store.dart` (cookie persistence), `nga_user_store.dart` (user profile)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/http/`:**
- Purpose: Low-level HTTP communication
- Contains: `nga_http_client.dart`
- Key files: `nga_http_client.dart` (wraps package:http with NGA-specific headers)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/`:**
- Purpose: Convert HTML responses to Dart objects
- Contains: `forum_parser.dart`, `thread_parser.dart`
- Key files: `thread_parser.dart` (hybrid regex + DOM parsing)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/codec/`:**
- Purpose: Character encoding detection and handling
- Contains: `decode_best_effort.dart`
- Key files: `decode_best_effort.dart` (GBK/UTF-8 fallback)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/model/`:**
- Purpose: Data structures for domain objects
- Contains: `forum_category.dart`, `thread_item.dart`, `thread_detail.dart`
- Key files: `forum_category.dart` (ForumCategory, ForumSubcategory, ForumBoard)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/services/`:**
- Purpose: Business logic services
- Contains: `forum_category_service.dart`
- Key files: `forum_category_service.dart` (loads JSON data with caching)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/`:**
- Purpose: Core utilities and barrel exports
- Contains: `nga_fetcher.dart` (re-exports all core modules), `nga_forum_store.dart` (forum state), `util/` (URL utilities)
- Key files: `nga_fetcher.dart` (convenient re-export), `nga_forum_store.dart` (active forum ID)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/test/`:**
- Purpose: Unit and widget tests
- Contains: `widget_test.dart`, `parser/thread_parser_test.dart`
- Key files: `parser/thread_parser_test.dart` (parser unit tests)

**`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/assets/data/`:**
- Purpose: Static embedded data
- Contains: `forum_categories_merged.json`
- Generated: No (maintained manually or via script)
- Committed: Yes (version controlled)

## Key File Locations

**Entry Points:**
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/main.dart` - App bootstrap, theme configuration
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/home_screen.dart` - Main screen with drawer navigation
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/forum_screen.dart` - Thread list (ForumContent widget)

**Configuration:**
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/pubspec.yaml` - Dependencies, assets, version
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/analysis_options.yaml` - Linting rules (flutter_lints)

**Core Logic:**
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/data/nga_repository.dart` - Data orchestration
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/http/nga_http_client.dart` - HTTP layer
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/thread_parser.dart` - HTML parsing

**State:**
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_cookie_store.dart` - Cookie state
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_user_store.dart` - User state
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/nga_forum_store.dart` - Active forum state

**Testing:**
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/test/widget_test.dart` - Default widget test
- `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/test/parser/thread_parser_test.dart` - Parser tests

## Naming Conventions

**Files:**
- Pattern: `snake_case.dart`
- Examples: `home_screen.dart`, `nga_http_client.dart`, `thread_parser_test.dart`

**Directories:**
- Pattern: `snake_case`
- Examples: `screens/`, `widgets/`, `test/parser/`, `assets/data/`

**Classes:**
- Pattern: `UpperCamelCase`
- Examples: `HomeScreen`, `NgaRepository`, `ThreadParser`, `ForumCategory`

**Functions/Methods:**
- Pattern: `lowerCamelCase`
- Examples: `fetchForumThreads()`, `setActiveFid()`, `parseThreadPage()`

**Variables:**
- Pattern: `lowerCamelCase`
- Examples: `activeFid`, `cookie`, `threadIds`

**Constants:**
- Pattern: `lowerCamelCase` or `kCamelCase` (for const)
- Examples: `_baseUrl`, `_storageKey`, `kDebugMode`

**Private Members:**
- Pattern: Prefix with underscore `_`
- Examples: `_cookie`, `_repository`, `_fetchThreads()`

## Where to Add New Code

**New Screen:**
- Primary code: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/new_screen.dart`
- Tests: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/test/new_screen_test.dart`
- Route: Add to `MaterialApp.routes` in `main.dart` if standalone route needed

**New Widget:**
- Implementation: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/widgets/new_widget.dart`
- Follow existing patterns: Stateful if needs state, Stateless if pure UI

**New Model:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/model/new_model.dart`
- Pattern: Class with final fields, `fromJson()` factory, `toJson()` method
- Export from `nga_fetcher.dart` if widely used

**New Service:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/services/new_service.dart`
- Pattern: Static methods with internal caching if needed

**New Parser:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/new_parser.dart`
- Pattern: Class with parse methods returning typed models

**New Store:**
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/new_store.dart` or in appropriate subdirectory
- Pattern: Static `ValueNotifier` fields, private constructor, persistence methods

**New Test:**
- Unit test: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/test/unit/new_feature_test.dart`
- Widget test: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/test/widget/new_widget_test.dart`
- Parser test: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/test/parser/new_parser_test.dart`

## Special Directories

**`.claude/`:**
- Purpose: Claude Code configuration, skills, and agent definitions
- Generated: Yes (by Claude Code setup)
- Committed: Yes (project configuration)

**`.fvm/`:**
- Purpose: Flutter Version Management configuration
- Contains: `versions/` with pinned Flutter SDK version
- Generated: Yes (by fvm)
- Committed: Yes (ensures team consistency)

**`assets/data/`:**
- Purpose: Static JSON data embedded in the app
- Contains: `forum_categories_merged.json` (forum hierarchy)
- Generated: No (maintained manually or via external process)
- Committed: Yes (required for app to function)

**`.planning/codebase/`:**
- Purpose: Architecture documentation for GSD workflow
- Contains: `ARCHITECTURE.md`, `STRUCTURE.md`, etc.
- Generated: Yes (by `/gsd:map-codebase`)
- Committed: Yes (for planner/executor reference)

---

*Structure analysis: 2026-01-23*
