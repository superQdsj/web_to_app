# Codebase Structure

**Analysis Date:** 2026-01-23

## Directory Layout

```
nga_app/
├── lib/
│   ├── main.dart                # Application entry point
│   ├── screens/                 # UI screens
│   │   ├── home_screen.dart     # Main screen with drawers
│   │   ├── forum_screen.dart    # Forum thread list content
│   │   ├── thread_screen.dart   # Thread detail with replies
│   │   ├── login_webview_sheet.dart  # Login modal
│   │   ├── widgets/             # Reusable UI components
│   │   │   ├── avatar_button.dart
│   │   │   ├── menu_button.dart
│   │   │   ├── menu_drawer.dart
│   │   │   ├── menu_drawer_grid.dart
│   │   │   └── profile_drawer.dart
│   │   └── thread/              # Thread screen parts (part of)
│   │       ├── thread_body.dart
│   │       ├── thread_palette.dart
│   │       ├── thread_post_widgets.dart
│   │       ├── thread_reply_composer.dart
│   │       ├── thread_reply_widgets.dart
│   │       └── thread_user_avatar.dart
│   ├── src/                     # Core libraries
│   │   ├── auth/                # Authentication stores
│   │   │   ├── nga_cookie_store.dart
│   │   │   └── nga_user_store.dart
│   │   ├── http/                # HTTP client
│   │   │   └── nga_http_client.dart
│   │   ├── model/               # Data models
│   │   │   ├── forum_category.dart
│   │   │   ├── thread_detail.dart
│   │   │   └── thread_item.dart
│   │   ├── parser/              # HTML parsers
│   │   │   ├── forum_parser.dart
│   │   │   └── thread_parser.dart
│   │   ├── services/            # Business logic
│   │   │   └── forum_category_service.dart
│   │   ├── codec/               # Encoding utilities
│   │   │   └── decode_best_effort.dart
│   │   ├── util/                # General utilities
│   │   │   └── url_utils.dart
│   │   ├── nga_fetcher.dart     # Barrel export
│   │   └── nga_forum_store.dart # Global forum state
│   ├── theme/                   # Theming
│   │   ├── app_theme.dart       # Theme configuration
│   │   ├── app_colors.dart      # Color extensions
│   │   └── app_typography.dart  # Typography styles
│   └── data/                    # Data layer
│       └── nga_repository.dart  # Repository pattern impl
├── test/                        # Test files
│   └── parser/                  # Parser tests
├── assets/
│   └── data/                    # Static JSON data
│       └── forum_categories_merged.json
├── pubspec.yaml                 # Flutter dependencies
└── pubspec.lock                 # Locked versions
```

## Directory Purposes

**lib/main.dart:**
- Purpose: Application bootstrap
- Contains: `main()` function, `NgaApp` widget

**lib/screens/:**
- Purpose: Full-page or major content widgets
- Contains: Screen widgets, embedded content widgets (e.g., `ForumContent`)
- Key files: `home_screen.dart`, `forum_screen.dart`, `thread_screen.dart`, `login_webview_sheet.dart`

**lib/screens/widgets/:**
- Purpose: Reusable UI components
- Contains: Buttons, drawers, custom widgets
- Used by: Screens in parent directory

**lib/screens/thread/:**
- Purpose: Thread screen modular components
- Contains: Parts of `ThreadScreen` using `part`/`part of`
- Pattern: Breaking large screen into manageable files

**lib/src/:**
- Purpose: Core application library (not directly exported)
- Subdirectories organized by concern (auth, http, model, parser, services)

**lib/src/auth/:**
- Purpose: Authentication and user state management
- Contains: Singleton stores for cookie and user persistence

**lib/src/http/:**
- Purpose: HTTP networking layer
- Contains: Custom HTTP client wrapper

**lib/src/model/:**
- Purpose: Data transfer objects
- Contains: Plain Dart classes with JSON serialization

**lib/src/parser/:**
- Purpose: HTML parsing logic
- Contains: Parsers that convert HTML to model objects

**lib/src/services/:**
- Purpose: Business logic services
- Contains: Category loading, icon mapping

**lib/src/codec/:**
- Purpose: Character encoding handling
- Contains: Encoding detection and conversion utilities

**lib/src/util/:**
- Purpose: General utilities
- Contains: URL manipulation helpers

**lib/theme/:**
- Purpose: Centralized theming
- Contains: Theme data, colors, typography

**lib/data/:**
- Purpose: Repository pattern implementation
- Contains: Data coordination layer

**assets/data/:**
- Purpose: Static JSON data for forum categories
- Contains: `forum_categories_merged.json`

**test/:**
- Purpose: Unit tests
- Contains: Parser tests in `test/parser/`

## Key File Locations

**Entry Points:**
- `nga_app/lib/main.dart`: Application start, theme configuration

**Configuration:**
- `nga_app/pubspec.yaml`: Dependencies, assets configuration
- `nga_app/lib/theme/`: Theme configuration files

**Core Logic:**
- `nga_app/lib/data/nga_repository.dart`: Data fetching coordination
- `nga_app/lib/src/parser/`: HTML parsing logic
- `nga_app/lib/src/http/nga_http_client.dart`: HTTP layer

**State Management:**
- `nga_app/lib/src/auth/nga_cookie_store.dart`: Auth state
- `nga_app/lib/src/auth/nga_user_store.dart`: User profile
- `nga_app/lib/src/nga_forum_store.dart`: Forum selection

**Testing:**
- `nga_app/test/parser/`: Parser unit tests

## Naming Conventions

**Files:**
- Pattern: `lowercase_with_underscores.dart`
- Examples: `home_screen.dart`, `nga_cookie_store.dart`, `thread_parser.dart`

**Classes:**
- Pattern: `UpperCamelCase`
- Examples: `HomeScreen`, `NgaCookieStore`, `ForumParser`

**Variables/Functions:**
- Pattern: `lowerCamelCase`
- Examples: `activeFid`, `fetchForumThreads`, `_onCookieChanged`

**Private Members:**
- Pattern: Prefixed with underscore `_`
- Examples: `_cookie`, `_onFidChanged`, `_buildBody`

**Constants:**
- Pattern: `lowerCamelCase` or `kUpperCamelCase`
- Examples: `_baseUrl`, `kDebugMode`

**Constants Class:**
- Pattern: Private constructor with static constants
- Examples: `NgaTheme._()`, `_ThreadPalette`

## Where to Add New Code

**New Screen:**
- Location: `nga_app/lib/screens/`
- Widget class: UpperCamelCase, extends StatefulWidget or StatelessWidget
- Tests: `nga_app/test/` (parallel structure)

**New Reusable Widget:**
- Location: `nga_app/lib/screens/widgets/`
- File: `widget_name.dart`
- Naming: Descriptive noun, e.g., `avatar_button.dart`

**New Model:**
- Location: `nga_app/lib/src/model/`
- File: `lowercase_name.dart`
- Class: UpperCamelCase
- Methods: `fromJson(Map)`, `toJson()`

**New Parser:**
- Location: `nga_app/lib/src/parser/`
- File: `context_parser.dart`
- Class: `ContextParser` with parsing methods

**New Service:**
- Location: `nga_app/lib/src/services/`
- File: `lowercase_service.dart`
- Pattern: Static methods with caching if needed

**New Utility:**
- Location: `nga_app/lib/src/util/` or `nga_app/lib/src/codec/`
- File: `purpose_utils.dart` or `purpose_codec.dart`

**Thread Screen Component:**
- Location: `nga_app/lib/screens/thread/`
- Pattern: Use `part` in parent, `part of` in child
- Examples: `thread_body.dart`, `thread_palette.dart`

**Global State Store:**
- Location: `nga_app/lib/src/` (or `auth/` for auth-related)
- File: `nga_feature_store.dart`
- Pattern: Static singleton with ValueNotifier

## Special Directories

**assets/data/:**
- Purpose: Static JSON data files (forum categories)
- Generated: No (committed manually)
- Committed: Yes

**nga_app/lib/src/:**
- Purpose: Core library not exposed in public API
- Generated: No
- Committed: Yes

**nga_app/lib/screens/thread/:**
- Purpose: Thread screen components using `part` pattern
- Pattern: Not importable individually; must use via parent
- Committed: Yes

**test/parser/:**
- Purpose: Parser unit tests
- Pattern: Mirror `lib/src/parser/` structure

---

*Structure analysis: 2026-01-23*
