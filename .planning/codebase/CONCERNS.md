# Codebase Concerns

**Analysis Date:** 2026-01-23

## Tech Debt

**Menu Drawer Duplication:**
- Two large drawer implementations exist with similar functionality
- Files: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/widgets/menu_drawer.dart` (837 lines)
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/widgets/menu_drawer_grid.dart` (693 lines)
- Impact: Code duplication, maintenance burden, potential UI inconsistency
- Fix approach: Consolidate into a single, parameterized drawer component

**Unimplemented Profile Detail Page:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/widgets/profile_drawer.dart`
- Line 138 contains TODO: `// TODO: 添加个人详情页.`
- Impact: User cannot view personal details from drawer
- Fix approach: Implement detail page navigation or use existing thread detail pattern

**Thread Parser Fallback Pattern:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/thread_parser.dart`
- Parser has hybrid and legacy fallback modes (lines 20-27)
- Lines 170, 185 return empty maps when user info extraction fails
- Lines 208, 254, 280, 285, 340, 351 return null for missing data
- Impact: Parser degrades silently; may show incomplete content
- Fix approach: Add monitoring/logging for fallback events, consider schema validation

## Known Bugs

**No Error Recovery on Network Failure:**
- Files: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/forum_screen.dart`, `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/thread_screen.dart`
- Symptoms: Network errors show error message but no retry button
- Trigger: Offline state or server timeout
- Workaround: User must manually pull-to-refresh or reopen the screen

**Cookie Synchronization Race Condition:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/login_webview_sheet.dart`
- Lines 70-83: `_autoCaptured` flag prevents multiple captures
- Risk: Rapid login/logout cycles may leave cookies unsynced
- Fix approach: Add explicit state synchronization, handle edge cases

## Security Considerations

**Plaintext Cookie Storage:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_cookie_store.dart`
- Cookies stored in SharedPreferences without encryption (line 73)
- Risk: Device compromise or rooted devices expose session cookies
- Current mitigation: Cookies are marked HttpOnly on server side
- Recommendations: Use flutter_secure_storage for sensitive data, implement cookie expiration checking

**Plaintext User Info Storage:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_user_store.dart`
- User info (uid, username, avatarUrl) stored as plain JSON in SharedPreferences
- Risk: Low (PII is public username), but should still be encrypted
- Fix approach: Migrate to flutter_secure_storage

**No Certificate Pinning:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/http/nga_http_client.dart`
- Uses standard http package with no certificate validation customization
- Risk: Man-in-the-middle attacks on HTTP traffic
- Fix approach: Consider adding certificate pinning for production builds

**No Input Sanitization on User Content:**
- Files parsing HTML: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/thread_parser.dart`
- User content from NGA is parsed and displayed without XSS protection
- Risk: Potential XSS if NGA serves malicious content
- Current mitigation: Flutter's Text widget escapes content automatically
- Fix approach: Ensure all rendered HTML content uses appropriate sanitization

## Performance Bottlenecks

**Menu Drawer Complex Rendering:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/widgets/menu_drawer.dart`
- Lines 79-135: Multiple backdrop filters and gradients
- Glass-morphism effect uses ImageFilter.blur (lines 106-108) on full drawer
- AnimatedContainer on every board card (lines 464-561)
- Impact: Potential frame drops on lower-end devices
- Improvement path: Optimize blur usage, consider caching, reduce animation complexity

**Repeated Future Creation:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/widgets/menu_drawer.dart`
- Line 63: `_categoriesFuture = ForumCategoryService.loadCategories()` created in initState
- Line 144: FutureBuilder rebuilds on every parent rebuild
- Impact: Category data may be fetched multiple times
- Improvement path: Cache the Future or use StateManagement solution

**No Image Caching:**
- Avatar images loaded without explicit caching
- Risk: Increased bandwidth, poor scrolling performance for avatar lists
- Improvement path: Use cached_network_image package

## Fragile Areas

**Thread Parser HTML Structure Dependency:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/thread_parser.dart`
- Fragile because: Relies on NGA's HTML structure and JavaScript variable patterns
- Lines 153-160: Regex extraction of `commonui.userInfo.setAll()`
- Lines 193-209: Complex regex for device type extraction using array index positions
- Why fragile: NGA redesign will break parsing without warning
- Safe modification: Add comprehensive logging, maintain legacy fallback
- Test coverage: Only one integration test exists

**Regex Pattern Fragility:**
- Lines 154-159: User info extraction assumes specific JavaScript format
- Lines 175-178: Group extraction assumes JSON within HTML
- Lines 289-341: PID extraction tries multiple patterns sequentially
- Impact: Any change to NGA HTML output breaks content extraction
- Fix approach: Consider switching to structured API if available

## Scaling Limits

**In-Memory Thread List:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/forum_screen.dart`
- Lines 22-23: Threads stored in memory without pagination beyond basic page loading
- Current capacity: Limited by device memory (thousands of threads)
- Limit: Navigation history with large thread lists
- Scaling path: Implement proper pagination with disk caching

**SharedPreferences Storage:**
- Cookie and user data stored in SharedPreferences
- No size limits enforced
- Risk: Storage bloat over time
- Scaling path: Implement storage cleanup, consider SQLite for large datasets

## Dependencies at Risk

**html Package:**
- File: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/thread_parser.dart`
- Package: `package:html`
- Risk: Not actively maintained for Dart 3 null safety
- Alternative: Consider `html_unescape` or manual parsing
- Migration plan: Evaluate html_unescape for simpler escaping needs

## Missing Critical Features

**Bookmark/Favorites System:**
- UI stubs exist in `menu_drawer.dart` (lines 301-335)
- Click shows "收藏功能开发中" snackbar
- Blocks: Users cannot save threads for later

**Reading History:**
- UI stub exists, shows "历史功能开发中"
- Blocks: Users cannot track previously viewed content

**Private Messages:**
- UI stub exists, shows "消息功能开发中"
- Blocks: Core NGA functionality missing

**Search Functionality:**
- FAB exists (lines 789-811) but shows "搜索功能开发中"
- Blocks: Content discovery within forums

**Settings Page:**
- Settings icon in footer (lines 769-783) shows "设置功能开发中"
- Blocks: User preferences, theme customization, logout

## Test Coverage Gaps

**Minimal Test Coverage:**
- Total Dart files in project: 33
- Test files found: 2 (widget_test.dart, parser/thread_parser_test.dart)
- Unit test coverage: None for models, services, stores
- Integration tests: Only one parser test that requires external HTML file

**Untested Areas:**
- ForumCategory parsing: No tests for JSON deserialization
- ForumBoard parsing: No validation tests
- CookieStore/UserStore: No persistence tests
- HTTP client: No mock tests for network responses
- UI screens: No widget tests for forum_screen, thread_screen
- Menu drawer: Complex UI entirely untested
- Error scenarios: No tests for network failures, parsing errors

**Risk Assessment:**
- What breaks unnoticed: Parser regressions, model changes breaking JSON
- Priority: High - parser breaking means app non-functional

**Recommended Test Priority:**
1. ThreadParser unit tests with mock HTML
2. ForumCategory model JSON parsing tests
3. CookieStore/UserStore persistence tests
4. ForumScreen widget tests
5. HTTP client mock tests

---

*Concerns audit: 2026-01-23*
