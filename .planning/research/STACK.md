# Stack Research

**Domain:** Flutter Forum App (NGA)
**Researched:** 2025-01-23
**Confidence:** MEDIUM

Research note: WebSearch unavailable during research. Used pub.dev official documentation for package verification. Some recommendations based on existing codebase patterns and general Flutter ecosystem knowledge.

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter SDK | 3.27+ | Mobile UI framework | Latest stable with improved iOS performance, Impeller renderer by default |
| Dart | 3.5+ | Language | Required for Flutter 3.27+, supports sealed classes, pattern matching |
| CupertinoIcons | 1.0.8+ | iOS-style icons | Native iOS look, already in use |

### Networking

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **dio** | 5.9.0 | HTTP client | Interceptors, FormData, timeout control, global config — superior to `http` for forum apps |
| http | 1.6.0 | HTTP client (keep) | Fallback for simple requests, well-tested |

**Recommendation:** Add `dio: ^5.9.0` alongside `http` for complex API calls. Forum apps need cookie handling, interceptors for auth refresh, and request queuing — dio handles these natively.

### WebView & Authentication

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| webview_flutter | 4.13.1 | Core WebView | Official plugin, good iOS support, already in use |
| webview_flutter_android | 4.7.0 | Android implementation | Already in use |
| webview_flutter_platform_interface | 2.13.0 | Platform abstraction | Already in use |
| webview_cookie_manager_plus | 2.0.17 | Cookie management | Simplifies cookie sync across webviews, already in use |

**Keep current WebView stack.** All packages are current (verified via pub.dev, Jan 2025). The `webview_cookie_manager_plus` is essential for forum auth cookie persistence.

### HTML Parsing

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **html** | 0.15.6 | HTML parser | Already in use, Dart implementation, good for NGA's HTML-heavy pages |
| **charset** | 2.0.1 | GBK/GB2312 encoding | Required for NGA forum — Chinese encoding support |

**Keep current HTML stack.** The `html` package (from dart-lang) parses NGA's HTML correctly. `charset` package handles the GBK encoding that NGA uses.

**Alternative considered:** `html_unescape` — useful for decoding HTML entities, consider adding if NGA uses many entities.

### State Management

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **GetX** | 4.7.3 | State management + DI + Navigation | All-in-one solution, minimal boilerplate, very popular in China (relevant for NGA) |
| Provider | 6.1.x | State management | Simpler alternative, official Flutter documentation uses it |

**Recommendation:** Add `GetX: ^4.7.3`. Benefits for forum apps:
- Navigation without context (`Get.to()`)
- Reactive state management for forum threads
- Dependency injection for services
- Internationalization built-in

### UI/UX Enhancements

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| shimmer | 3.0.0 | Loading skeletons | Better UX for forum list loading, 835K downloads |
| cached_network_image | 3.4.1 | Image caching | Avatar/thread thumbnail caching, 1.65M downloads |
| fluttertoast | 9.0.0 | Toast messages | User feedback for actions, cross-platform |
| flutter_markdown_plus | latest | Markdown rendering | If NGA adds Markdown support, better than discontinued flutter_markdown |

**Recommendation:** Add `shimmer: ^3.0.0` and `cached_network_image: ^3.4.1` for immediate UX improvement.

### Performance

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| flutter_isolate | 2.1.0 | Background isolates | Heavy HTML parsing off main thread |
| isolate_handler | 1.0.2 | Isolate management | Simpler API than raw isolates |

**Recommendation:** Add `flutter_isolate: ^2.1.0` for parsing NGA's large HTML pages without blocking UI.

### iOS Native Polish

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| flutter_native_splash | 2.4.7 | Launch screen | Native iOS splash experience |
| flutter_launcher_icons | 0.14.4 | App icons | iOS 18+ dark mode/tinted icon support |

**Recommendation:** Add both for iOS-native polish. `flutter_native_splash` generates native iOS code for smooth launch experience.

### Local Storage

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| shared_preferences | 2.5.4 | Simple key-value storage | Already in use — user settings, cached data |
| hive | 2.2.x | Local database | Forum thread caching, offline reading |

**Recommendation:** Keep `shared_preferences`. Add `hive: ^2.2.3` if offline forum reading is needed.

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| flutter_lints | Linting | Already in use (`^6.0.0`) |
| freezed | Code generation | Immutable models, 3.2.4, Flutter Favorite |
| json_serializable | JSON serialization | Works with freezed for API models |

---

## Installation

```bash
# Core networking
cd nga_app && flutter pub add dio

# WebView (already present, verify versions)
# flutter pub add webview_flutter webview_cookie_manager_plus

# State management
flutter pub add get

# UI/UX
flutter pub add shimmer cached_network_image fluttertoast

# Performance
flutter pub add flutter_isolate

# iOS polish
flutter pub add flutter_native_splash flutter_launcher_icons

# Development
flutter pub add -D freezed json_serializable build_runner
```

---

## Alternatives Considered

| Category | Recommended | Alternative | When to Use Alternative |
|----------|-------------|-------------|------------------------|
| HTTP Client | dio | http | If only simple GET/POST needed, dio overhead not justified |
| State Management | GetX | Provider | When team prefers official/Flutter team solution |
| Image Loading | cached_network_image | NetworkImage + custom | When custom caching logic needed |
| HTML Parsing | html (keep) | cheerio | Only if migrating to web/dart:html |
| WebView | webview_flutter | flutter_inappwebview | When need headless webviews, custom chrome tabs |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| flutter_inappwebview | Heavy dependency (1MB+), conflicts with webview_flutter | webview_flutter (already working) |
| flutter_webview_plugin | Deprecated, not maintained | webview_flutter |
| html_unescape (standalone) | Basic functionality only | Add if html package insufficient |
| dio_cookie_manager | Less maintained than webview_cookie_manager_plus | webview_cookie_manager_plus |
| android_intent | Not needed for forum app | Use URL launcher if needed |

---

## Stack Patterns by Variant

**If forum thread parsing is slow:**
- Add `flutter_isolate` for background parsing
- Implement pagination with `cached_network_image`
- Use `shimmer` during loading states

**If iOS native feel is priority:**
- Use `CupertinoNavigationBar` with `CupertinoSliverNavigationBar`
- Add `flutter_native_splash` and `flutter_launcher_icons`
- Implement pull-to-refresh with `CupertinoActivityIndicator`

**If offline reading needed:**
- Add `hive` for thread/content caching
- Store parsed thread data for offline access
- Use `shared_preferences` for bookmarks

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| dio 5.9.0 | Dart 3.5+, Flutter 3.27+ | Uses modern Dart features |
| GetX 4.7.3 | Dart 3.0+ | Some features need Dart 3 |
| shimmer 3.0.0 | All Flutter versions | Stable, widely used |
| cached_network_image 3.4.1 | Flutter 3.10+ | Requires Flutter 3.10 minimum |
| flutter_native_splash 2.4.7 | iOS 12+, Android 21+ | Check iOS deployment target |
| freezed 3.2.4 | Dart 3.0+ | Requires Dart 3 for sealed classes |

**Note:** Verify Flutter SDK version in `pubspec.yaml` — currently uses `sdk: ^3.10.7`, which supports all recommended packages.

---

## Current Project Dependencies (Verified)

These are already in use and verified current:

| Package | Current Version | Status |
|---------|-----------------|--------|
| cupertino_icons | 1.0.8 | Current |
| http | 1.6.0 | Current |
| html | 0.15.6 | Current |
| charset | 2.0.1 | Current |
| webview_flutter | 4.13.1 | Current |
| webview_flutter_android | 4.7.0 | Current |
| webview_flutter_platform_interface | 2.13.0 | Current |
| webview_cookie_manager_plus | 2.0.17 | Current |
| shared_preferences | 2.5.4 | Current |
| flutter_lints | 6.0.0 | Current |

---

## Recommended Additions Summary

| Priority | Package | Version | Reason |
|----------|---------|---------|--------|
| High | dio | 5.9.0 | Better HTTP for forum API |
| High | GetX | 4.7.3 | State + navigation + DI |
| High | shimmer | 3.0.0 | Loading UX |
| High | cached_network_image | 3.4.1 | Image performance |
| Medium | flutter_isolate | 2.1.0 | Performance |
| Medium | flutter_native_splash | 2.4.7 | iOS polish |
| Medium | flutter_launcher_icons | 0.14.4 | iOS polish |
| Low | fluttertoast | 9.0.0 | User feedback |
| Low | flutter_markdown_plus | latest | Future Markdown support |

---

## Sources

- [dio pub.dev](https://pub.dev/packages/dio) — Version 5.9.0, verified Jan 2025
- [webview_flutter pub.dev](https://pub.dev/packages/webview_flutter) — Version 4.13.1, verified Jan 2025
- [html pub.dev](https://pub.dev/packages/html) — Version 0.15.6, verified Jan 2025
- [GetX pub.dev](https://pub.dev/packages/get) — Version 4.7.3, verified Jan 2025
- [shimmer pub.dev](https://pub.dev/packages/shimmer) — Version 3.0.0, verified Jan 2025
- [cached_network_image pub.dev](https://pub.dev/packages/cached_network_image) — Version 3.4.1, verified Jan 2025
- [flutter_native_splash pub.dev](https://pub.dev/packages/flutter_native_splash) — Version 2.4.7, verified Jan 2025
- [flutter_launcher_icons pub.dev](https://pub.dev/packages/flutter_launcher_icons) — Version 0.14.4, verified Jan 2025
- [flutter_isolate pub.dev](https://pub.dev/packages/flutter_isolate) — Version 2.1.0, verified Jan 2025
- [fluttertoast pub.dev](https://pub.dev/packages/fluttertoast) — Version 9.0.0, verified Jan 2025
- [freezed pub.dev](https://pub.dev/packages/freezed) — Version 3.2.4, verified Jan 2025
- [flutter_markdown_plus pub.dev](https://pub.dev/packages/flutter_markdown_plus) — Replaces discontinued flutter_markdown

---

*Stack research for: NGA Forum App*
*Researched: 2025-01-23*
