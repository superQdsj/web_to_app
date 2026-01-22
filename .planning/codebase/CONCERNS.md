# Codebase Concerns

**Analysis Date:** 2026-01-23

## Tech Debt

### Incomplete Feature Implementations (Placeholder Handlers)

Multiple UI elements have placeholder handlers that do nothing:

**Files:** `nga_app/lib/screens/widgets/profile_drawer.dart`, `nga_app/lib/screens/widgets/menu_drawer.dart`

**Issue:** Menu items and settings buttons use empty lambda functions `onTap: () {}` instead of proper navigation or feature implementations.

In `profile_drawer.dart`:
- Line 138: `// TODO: 添加个人详情页.` - Personal detail page not implemented
- Line 170: `onTap: () {}` - Settings page placeholder
- Line 176: `onTap: () {}` - About page placeholder

In `menu_drawer.dart`:
- Lines 310, 320, 330: Quick action cards (收藏、历史、消息) show snackbars "功能开发中" (feature under development)
- Line 770-778: Settings button shows "设置功能开发中"
- Lines 791-798: Search FAB shows "搜索功能开发中"

**Impact:** Poor user experience when clicking these elements. Users see "under development" messages instead of actual functionality.

**Fix approach:** Implement the missing pages or remove the clickable elements until features are ready.

### WebView Cookie Synchronization Complexity

**File:** `nga_app/lib/screens/login_webview_sheet.dart`

**Issue:** The login flow uses a complex multi-signal approach to detect when login is complete:
- `onPageFinished` callback
- `onNavigationRequest` for `login_set_cookie_quick` URL pattern
- JavaScript console.log hook for `loginSuccess` message
- Auto-capture with 300ms delay

This creates fragile timing-dependent behavior where login success might be missed if:
- The page finishes loading before cookies are set
- The `login_set_cookie_quick` URL doesn't trigger
- JavaScript injection fails or `console.log` format changes

**Impact:** Users may need to manually click "Use Login" button if auto-capture fails.

**Fix approach:** Consider adding a dedicated JavaScript callback or URL parameter that NGA server could use to signal login completion more reliably.

## Known Bugs

### No explicit bugs identified during analysis

The codebase appears relatively stable with no obvious runtime crashes or bugs. Error handling is present throughout the application.

## Security Considerations

### Cookie Storage Uses SharedPreferences (No Encryption)

**File:** `nga_app/lib/src/auth/nga_cookie_store.dart`

**Issue:** Authentication cookies (`ngaPassportUid`, `ngaPassportCid`) are stored in plaintext using `SharedPreferences`:
```dart
await prefs.setString(_storageKey, cookie.value);
```

These cookies provide full access to the user's NGA account. `SharedPreferences` stores data in plaintext XML files that are accessible to any app with root access or through ADB backup.

**Current mitigation:** None

**Recommendations:**
1. Use `flutter_secure_storage` package instead of `SharedPreferences` for storing authentication tokens
2. Consider adding biometric authentication before allowing sensitive actions
3. Implement cookie expiration checking

### Hardcoded Image URLs in Production Code

**File:** `nga_app/lib/screens/widgets/profile_drawer.dart`

**Issue:** Line 339 loads an image from external URL:
```dart
Image.network(
  'https://img.ngacn.cc/base/common/logo.png',
  height: 24,
  errorBuilder: (context, error, stackTrace) =>
      const Icon(Icons.forum_rounded, size: 24),
),
```

**Risk:** External dependency for static asset. If the URL changes or the service goes down, the logo won't display in the footer.

**Current mitigation:** Fallback icon is provided via `errorBuilder`.

**Recommendations:**
1. Bundle the logo as a local asset in `assets/images/`
2. Use versioned URL or CDN with good uptime guarantees

### Hardcoded API Base URL

**File:** `nga_app/lib/data/nga_repository.dart`

**Issue:** The NGA API base URL is hardcoded:
```dart
static const String _baseUrl = 'https://bbs.nga.cn';
```

**Risk:** If NGA changes their domain or adds regional variants, all API calls will fail without code changes.

**Recommendations:**
1. Move to configuration file or environment variable
2. Consider supporting multiple endpoints

## Performance Bottlenecks

### Large File Parsing with Synchronous HTML Parsing

**File:** `nga_app/lib/src/parser/thread_parser.dart`

**Issue:** The `parseHybrid` and `_parseLegacy` methods parse entire HTML documents synchronously on the main thread:
```dart
final doc = html_parser.parse(htmlText);
```

For threads with many posts (100+), this can cause UI stutter during initial page load.

**Current mitigation:** Uses try-catch with fallback parser, but doesn't prevent main-thread blocking.

**Impact:** UI freeze of 100-500ms on large thread pages.

**Fix approach:**
1. Consider running parsing in an `Isolate`
2. Add loading skeleton while parsing
3. Implement incremental parsing for pagination

### Image Loading Without Caching Strategy

**File:** `nga_app/lib/screens/widgets/profile_drawer.dart`

**Issue:** User avatar images use `NetworkImage` without explicit caching:
```dart
foregroundImage: user?.avatarUrl != null
    ? NetworkImage(user!.avatarUrl!)
    : null,
```

**Impact:** Repeated loading of same avatars when scrolling through threads, increased bandwidth and slower scrolling.

**Fix approach:** Use `cached_network_image` package for automatic caching.

### No Pagination Optimization for Forum Categories

**File:** `nga_app/lib/src/services/forum_category_service.dart`

**Issue:** Forum categories are loaded from JSON file on every `MenuDrawer` init:
```dart
_categoriesFuture = ForumCategoryService.loadCategories();
```

**Impact:** Minor - JSON is small, but this could be optimized with caching.

**Fix approach:** Cache the loaded categories in memory.

## Fragile Areas

### HTML Parser Relies on NGA's HTML Structure

**Files:** `nga_app/lib/src/parser/thread_parser.dart`, `nga_app/lib/src/parser/forum_parser.dart`

**Why fragile:** Parsers use CSS selectors and regex patterns that match NGA's current HTML structure:
```dart
final postRows = doc.querySelectorAll('table.forumbox.postbox');
final pidMatch = RegExp(r'pid(\d+)');
```

**Risk:** If NGA updates their website design or HTML structure, parsing will fail silently (returning empty posts or incorrect data).

**Current mitigation:** Fallback parser exists in `parseThreadPage`, but it's less complete.

**Safe modification approach:**
1. Add comprehensive logging when parsing fails
2. Add unit tests with sample HTML that can be updated
3. Consider adding version detection for different NGA page formats

### JavaScript Injection in WebView

**File:** `nga_app/lib/screens/login_webview_sheet.dart`

**Why fragile:** The login hook relies on parsing `console.log` output:
```dart
if (arg.indexOf('loginSuccess') === -1) continue;
```

**Risk:** If NGA changes their JavaScript logging format, user info capture will fail.

**Safe modification approach:** Add debug logging for the JavaScript hook result, ensure manual "Use Login" button always works as fallback.

## Scaling Limits

### Memory: No Cleanup of Large Thread Data

**Files:** `nga_app/lib/screens/forum_screen.dart`, `nga_app/lib/screens/thread_screen.dart`

**Current capacity:** Can load threads indefinitely; data accumulates in memory.

**Limit:** After loading ~1000+ posts or threads, the app may experience memory pressure on lower-end devices.

**Scaling path:** Implement pagination with data eviction (keep only recent N pages of data).

### Network: No Offline Mode or Local Caching

**Current limitation:** All forum content requires live network connection.

**Scaling path:** Implement local SQLite storage for thread content to enable offline reading.

## Dependencies at Risk

### `html` Package (0.15.6)

**Risk:** The `html` package is in maintenance mode and may not receive updates for newer Dart/Flutter versions. Last significant update was several years ago.

**Impact:** May cause compatibility issues with future Flutter versions.

**Migration plan:** Consider using `package:html` only for DOM parsing. Could be replaced with Flutter's built-in parsing or `xml` package if needed.

### `http` Package (1.6.0)

**Risk:** Standard Dart http package, well-maintained but occasionally has breaking changes.

**Impact:** Low - widely used and stable.

## Missing Critical Features

### No Reply Composer Implementation

**File:** `nga_app/lib/screens/thread/thread_reply_composer.dart`

**Issue:** The `ThreadScreen` has a bottom navigation bar with a reply composer widget, but the composer doesn't actually submit replies.

**Problem:** Users can read threads but cannot post replies.

**Fix approach:** Implement form submission to NGA's reply API.

### No Search Functionality

**Problem:** No search UI or API integration exists.

**Impact:** Users cannot search forum content within the app.

### No Thread/Post Bookmarking

**Problem:** UI shows "收藏" (bookmarks) button but functionality is not implemented.

### No Message/Notification System

**Problem:** UI shows "消息" (messages) button but functionality is not implemented.

### No User Profile Editing

**File:** `nga_app/lib/screens/widgets/profile_drawer.dart`

**Problem:** "个人详情" (personal details) menu item is a TODO placeholder.

## Test Coverage Gaps

### No Unit Tests

**Status:** No test directory files found (`test/` folder is empty or missing).

**What's not tested:**
- Thread parsing logic
- Forum parsing logic
- Cookie storage and retrieval
- HTTP client behavior
- URL utility functions

**Risk:** Changes to parsing logic could break thread/post display without immediate detection.

**Priority:** High - parsing is critical to app functionality.

### No Integration Tests

**What's not tested:**
- Login flow end-to-end
- Forum navigation flow
- Thread reading flow

**Risk:** UI changes could break core user journeys.

### No Widget Tests

**What's not tested:**
- Screen rendering
- State management
- Error display

**Priority:** Medium

---

*Concerns audit: 2026-01-23*
