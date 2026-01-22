# Pitfalls Research

**Domain:** Flutter Forum App (NGA-style bulletin board)
**Researched:** 2026-01-23
**Confidence:** MEDIUM
**Note:** Web search unavailable during research. Findings based on codebase analysis and Flutter/domain expertise.

---

## Critical Pitfalls

### Pitfall 1: Brittle HTML Parser — NGA Changes Break Everything

**What goes wrong:**
The app silently displays broken content when NGA updates their HTML structure. Posts render partially, avatars go missing, reply counts show wrong numbers. Users report "it worked yesterday" issues.

**Why it happens:**
NGA's HTML is not designed for API consumption. It's generated server-side with inline styles, table-based layouts, and class names that change without warning. The `html` package parser extracts data by DOM traversal — any structural change cascades to all parsing.

**How to avoid:**
1. **Wrap every parser extraction in defensive fallbacks:**
   ```dart
   String? safeAttribute(Element element, String attr) {
     try {
       return element.attributes[attr];
     } catch (e) {
       return null; // Fail gracefully, don't crash
     }
   }
   ```
2. **Add integration tests that parse real NGA pages** — run periodically against live content
3. **Log parser failures with HTML context** — when parsing fails, save the offending HTML for debugging
4. **Version your parser output** — detect when NGA's format changes

**Warning signs:**
- `ThreadParser` throws exceptions on certain threads
- Missing fields appear as `null` without user notification
- Parser tests pass but real-world threads fail
- Console shows `NullCheckOperatorException` or `RangeError`

**Phase to address:** Performance & Parser Phase

---

### Pitfall 2: Memory Explosion from Large Threads

**What goes wrong:**
Opening a thread with 1000+ replies causes the app to freeze, then crash with `OutOfMemoryError`. Scroll becomes jerky. Memory usage grows unbounded as user scrolls.

**Why it happens:**
The current architecture loads all posts into memory at once (`_posts` list). Each post contains HTML-rendered widgets, image cache entries, and DOM references. Large threads accumulate thousands of post objects, and Flutter's widget tree becomes too large to render efficiently.

**How to avoid:**
1. **Implement virtual scrolling with limited viewport widgets** — use `ListView.builder` with fixed item extent, not `ListView` with all children
2. **Lazy-load images only when approaching viewport** — `precacheImage` only for visible items
3. **Paginate post rendering** — keep only N posts in memory, discard off-screen posts
4. **Compress post content** — parse HTML to styled widgets once, don't keep raw HTML strings

**Warning signs:**
- Memory profiler shows linear growth during scroll
- FPS drops below 30 when scrolling long threads
- Android shows "app not responding" on large threads
- iOS memory warning notifications

**Phase to address:** Performance Phase

---

### Pitfall 3: iOS Design Inconsistency — Material/Cupertino Mismatch

**What goes wrong:**
The app looks Android-y on iOS. Navigation transitions feel wrong, pull-to-refresh behaves differently, tab bars don't match iOS conventions. Users perceive it as "not a real iOS app."

**Why it happens:**
The app uses Material Design components (`Scaffold`, `AppBar`, `Material` widgets) without Cupertino alternatives. iOS users expect platform-specific conventions: swipe-back navigation, card-style sheets, Safari-style toolbars.

**How to avoid:**
1. **Use `CupertinoApp` wrapper with `ThemeData.dark()` for iOS** — or use `AdaptiveTheme` package
2. **Replace `Scaffold` with conditional platform widgets:**
   ```dart
   Platform.isIOS
       ? CupertinoPageScaffold(child: content)
       : Scaffold(body: content)
   ```
3. **Use `CupertinoNavigationBar` on iOS** — maintains proper back-swipe behavior
4. **Adopt iOS scroll conventions** — large titles, rubber-banding, pull-to-refresh style

**Warning signs:**
- iOS users report "weird navigation"
- Back button requires tap instead of swipe
- App doesn't appear in iOS app switcher correctly
- Platform-specific bugs only on iOS

**Phase to address:** iOS Design Phase

---

### Pitfall 4: Cookie Authentication Fragility

**What goes wrong:**
Users log in successfully, but API calls still fail. Or users stay logged in initially, then get logged out unexpectedly. Cookie expiry causes silent authentication failures.

**Why it happens:**
WebView cookie extraction is platform-dependent. iOS and Android handle WebView cookies differently. NGA's cookies have varying expiry times, and the app doesn't validate cookie freshness before API calls. Cookie storage may not persist across app restarts.

**How to avoid:**
1. **Validate cookie before every API call** — check `ngaPassportUid` and `ngaPassportCid` exist
2. **Implement cookie refresh flow** — if API returns 401, trigger re-login silently
3. **Separate cookie storage by platform:**
   - iOS: Use `webview_cookie_manager_plus` properly
   - Android: Handle cookie persistence manually if needed
4. **Add cookie expiry tracking** — warn users before cookies expire

**Warning signs:**
- 401 errors appear after app restart
- Login works in WebView but API fails
- Cookie values are empty or malformed
- Platform-specific auth bugs

**Phase to address:** Authentication Phase (or Core Foundation)

---

### Pitfall 5: Image Loading Performance — Network Flood

**What goes wrong:**
Opening a thread with 50 posts containing images triggers 50+ concurrent image requests. Users see slow loading, wasted bandwidth, and potential rate-limiting from NGA's CDN. Cached images consume too much memory.

**Why it happens:**
Each `Image.network()` widget starts its own HTTP request. Without caching strategy, images reload on every view. Large images are downloaded at full resolution for thumbnail display.

**How to avoid:**
1. **Use `CachedNetworkImage` package** — handles disk/memory caching automatically
2. **Implement thumbnail-first loading** — load small images first, lazy-load full resolution
3. **Add request throttling** — max 3-5 concurrent image downloads
4. **Progressive image loading** — show placeholder while loading, fade in when ready

**Warning signs:**
- Network tab shows burst of 50+ image requests
- Thread load time exceeds 5 seconds
- Users report "too many connections" errors
- Memory spikes when opening image-heavy threads

**Phase to address:** Performance Phase

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Parse HTML with regex | Fast initial implementation | Breaks on any HTML change | Never — use proper parser |
| Load all posts at once | Simple list rendering | Memory explosion on large threads | Only for threads < 100 posts |
| Skip error boundaries | Less boilerplate | App crashes on parsing errors | Never |
| Hardcode fid/tid values | No configuration needed | Breaks when NGA changes IDs | Only in throwaway prototypes |
| Skip image placeholder | Cleaner UI code | Poor perceived performance | Never for forum apps |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| NGA API | Assuming stable HTML structure | Defensive parsing with fallbacks |
| WebView Login | Not handling WebView lifecycle | Dispose properly, extract cookies before close |
| Cookie Storage | Plain text storage | Use encrypted storage (Flutter Secure Storage) |
| HTTP Client | Not setting proper timeouts | 30s timeout minimum, handle retries |
| Image Loading | No cache strategy | CachedNetworkImage + disk cache |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Synchronous HTML parsing | UI freezes for 500ms+ | Parse in isolate, use `compute()` | Threads > 50 posts |
| No image caching | Every visit re-downloads | CachedNetworkImage | Threads with images |
| Widget rebuild on scroll | Scroll jank, high CPU | Use `const` constructors, `ListView.builder` | Any scrollable list > 20 items |
| Large image decoding | Memory spike on load | Downsample for thumbnails | Images > 1MB |
| No pagination | Memory grows linearly | Pagination at 100 posts | Threads > 500 posts |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing cookies in plain text | Cookie theft if device compromised | Use `flutter_secure_storage` |
| Not validating HTTPS certificates | Man-in-the-middle attacks | Keep default certificate validation |
| Logging cookie values | Exposure in crash reports | Sanitize logs, never log credentials |
| Allowing arbitrary WebView navigation | Phishing in login flow | Restrict WebView to NGA domain only |
| No session expiration | Stale sessions persist indefinitely | Implement session timeout (24h max) |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Loading spinner without context | Users don't know if progress is happening | Show "Loading posts...", "Retrying..." |
| No pull-to-refresh | Users can't update content naturally | Platform-native pull-to-refresh |
| Infinite scroll without end indicator | Users don't know when content ends | Show "No more posts" footer |
| Images break silently | Broken image icons confuse users | Show placeholder with alt text |
| Long threads have no navigation | Can't jump to specific post | Add post number search, quick-jump |

---

## "Looks Done But Isn't" Checklist

- [ ] **Parser:** Handles missing fields gracefully? Verify with malformed HTML
- [ ] **Images:** Cached properly? Test airplane mode on previously loaded thread
- [ ] **Auth:** Survives app restart? Test after force-kill
- [ ] **iOS:** Uses Cupertino widgets? Compare with Safari on iOS
- [ ] **Large threads:** Don't crash? Test with 1000+ reply thread
- [ ] **Error handling:** Users see useful messages? Test with network offline
- [ ] **Dark mode:** All widgets support? Test all screens in dark mode
- [ ] **Back navigation:** Works as expected? Test hardware back button on Android

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Brittle HTML parser | MEDIUM | 1. Identify failing selector from crash logs 2. Update parser with new selector 3. Add integration test |
| Memory explosion | HIGH | 1. Profile with DevTools 2. Implement lazy loading 3. Add memory monitoring |
| iOS design mismatch | LOW | 1. Add platform-specific widgets 2. Test on iOS device 3. Verify transitions |
| Cookie auth failure | LOW | 1. Check cookie extraction flow 2. Verify WebView lifecycle 3. Add validation |
| Image network flood | LOW | 1. Add CachedNetworkImage 2. Configure disk cache 3. Throttle requests |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Brittle HTML Parser | Performance & Parser | Integration tests against live NGA |
| Memory Explosion | Performance | Test with 1000+ post thread |
| iOS Design Inconsistency | iOS Design | Test on physical iOS device |
| Cookie Authentication | Authentication | Verify login persists after restart |
| Image Loading Performance | Performance | Profile network requests, verify caching |

---

## Sources

- Flutter documentation on platform-adaptive design
- NGA forum HTML structure analysis (current codebase)
- Flutter performance best practices (DevTools profiling)
- iOS Human Interface Guidelines for navigation patterns
- Common Flutter forum app patterns (domain expertise)

---

*Pitfalls research for: NGA Forum App*
*Researched: 2026-01-23*
