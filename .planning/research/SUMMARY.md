# Project Research Summary

**Project:** NGA Mobile Forum App
**Domain:** Mobile Forum Client Application
**Researched:** 2026-01-23
**Confidence:** MEDIUM

## Executive Summary

The NGA Forum App is a Flutter-based mobile client for browsing the NGA bulletin board system. Research indicates the core foundation is already in place with functional forum browsing, thread reading, and WebView-based authentication. The recommended approach focuses on strategic package additions (dio for HTTP, GetX for state management, CachedNetworkImage for performance) while preserving the existing working WebView and HTML parsing stack. The primary risks are NGA's unstable HTML structure breaking the parser, memory issues with large threads, and iOS design inconsistencies. The app should prioritize performance optimizations and defensive coding patterns before expanding feature set.

Key recommendations: Add dio and GetX for better HTTP handling and state management; implement defensive HTML parsing with fallbacks; use CachedNetworkImage to prevent network flooding; adopt Cupertino widgets for iOS-native feel; defer complex features like new thread creation and push notifications to v2+.

## Key Findings

### Recommended Stack

The existing Flutter stack (SDK 3.10.7+) is solid but benefits from strategic additions. The research recommends adding **dio 5.9.0** for superior HTTP capabilities including interceptors, FormData support, and request queuing — essential for forum API calls. **GetX 4.7.3** provides all-in-one state management, dependency injection, and navigation without context, reducing boilerplate significantly. For performance, **flutter_isolate** moves heavy HTML parsing off the main thread, while **CachedNetworkImage** and **shimmer** dramatically improve perceived performance.

The current webview stack (webview_flutter 4.13.1 + webview_cookie_manager_plus) is verified current and should be preserved. The HTML parsing approach using `html` + `charset` packages handles NGA's GBK encoding correctly.

**Core technologies to add:**
- **dio 5.9.0**: HTTP client with interceptors and cookie handling
- **GetX 4.7.3**: State management + DI + navigation
- **CachedNetworkImage 3.4.1**: Image caching with disk/memory support
- **flutter_isolate 2.1.0**: Background HTML parsing
- **shimmer 3.0.0**: Loading skeleton UI

### Expected Features

Core functionality is largely implemented: forum category browsing, thread list with pagination, thread detail view, cookie-based authentication via WebView, and dark mode theming. The remaining table stake is **reply functionality** which exists partially but needs full NGA API integration.

Differentiators for v1.x include quote reply, image gallery (tap-to-view fullscreen), forum-level search, and favorites/bookmarks. These provide competitive advantage without requiring v2-level effort.

Features to defer to v2+: new thread creation (requires BBCode parser), private messages (complex NGA API), push notifications (battery/complexity), and offline reading (storage/staleness management).

**Must have (table stakes):**
- Forum browsing — DONE
- Thread reading — DONE
- User authentication — DONE
- Reply to threads — PARTIAL (needs completion)
- Dark mode — DONE

**Should have (competitive advantage):**
- Quote reply — P2, v1.x
- Image gallery — P2, v1.x
- Search — P2, v1.x (complex NGA API)
- Favorites/Bookmarks — P2, v1.x

**Defer (v2+):**
- New thread creation
- Private messages
- Push notifications
- Offline reading mode

### Architecture Approach

The app follows a clean layered architecture: Presentation (Screens, Widgets), State (ValueNotifier stores), Data (Repository, Parsers, HTTP Client). Current architecture is sound with clear component boundaries, but needs enhancement in state management (ValueNotifier to GetX/Provider), HTML parsing performance (synchronous to isolate-based), and caching (none currently).

The hybrid parser approach combining regex pre-extraction with DOM traversal is performant but brittle — any NGA HTML change cascades to all parsing. Critical rule: parsers must remain pure functions with no side effects.

**Major components:**
1. **Screens** — UI composition, user interaction (HomeScreen, ForumScreen, ThreadScreen)
2. **Repository** — Data orchestration, fetch/parse/return
3. **Parsers** — HTML to domain models (ThreadParser, ForumParser)
4. **State Stores** — Global state (NgaCookieStore, NgaForumStore, NgaUserStore)
5. **HTTP Client** — Network requests with encoding handling

### Critical Pitfalls

1. **Brittle HTML Parser** — NGA updates HTML structure without warning, causing silent content breakage. Prevention: defensive parsing with null fallbacks, integration tests against live content, parser version detection.

2. **Memory Explosion** — Large threads (1000+ replies) freeze and crash the app. Prevention: virtual scrolling with ListView.builder, lazy image loading, post pagination.

3. **iOS Design Inconsistency** — Material widgets on iOS feel wrong (no swipe-back, wrong transitions). Prevention: use CupertinoPageScaffold, CupertinoNavigationBar, platform-adaptive components.

4. **Cookie Authentication Fragility** — Platform-dependent WebView cookie handling causes silent auth failures. Prevention: validate cookies before API calls, separate storage by platform, track expiry.

5. **Image Loading Performance** — Burst of 50+ concurrent image requests floods network and CDN. Prevention: CachedNetworkImage with disk cache, request throttling, thumbnail-first loading.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Foundation & Performance
**Rationale:** Core functionality needs completion and stability before adding features. Authentication and parsing are foundational — if these break, nothing else matters.

**Delivers:** Complete reply functionality, defensive HTML parser with fallbacks, image loading optimization, GetX state management migration.

**Addresses:** Pitfall 1 (brittle parser), Pitfall 5 (image loading), P1 features (reply completion).

**Avoids:** Memory explosion by implementing pagination before large thread handling.

### Phase 2: iOS Native Experience
**Rationale:** Project goal is iOS-native feel. Once performance is stable, adapt UI to Cupertino design patterns.

**Delivers:** Cupertino widgets throughout, proper iOS navigation patterns, platform-adaptive theming.

**Addresses:** Pitfall 3 (iOS design inconsistency).

### Phase 3: User Features
**Rationale:** After foundation and platform feel are solid, add differentiating features that increase user engagement.

**Delivers:** Quote reply, image gallery, favorites/bookmarks, user profile enhancements.

**Implements:** Differentiator features from FEATURES.md.

### Phase 4: Search & Discovery (Optional)
**Rationale:** Search is complex due to NGA's search API. Only attempt after other phases are stable.

**Delivers:** Forum-level search with filters.

**Research flag:** Likely needs `/gsd:research-phase` during planning — NGA search API is not well documented.

### Phase Ordering Rationale

- Foundation first: Authentication and parsing must work before any feature can function
- Performance before UI: Memory issues and network flooding must be fixed before iOS polish
- User features after stability: Adding features to unstable foundation causes technical debt
- Search last: Complex integration with high uncertainty, defer until product-market fit

### Research Flags

Phases needing deeper research during planning:
- **Phase 3 (User Features):** Quote reply requires understanding NGA's BBCode/quote API format
- **Phase 4 (Search):** NGA search API is complex and undocumented — likely needs dedicated research

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** GetX migration, dio integration are well-documented patterns
- **Phase 2 (iOS):** Cupertino widgets are standard Flutter components

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | WebSearch unavailable, used pub.dev verification only |
| Features | MEDIUM | Based on codebase analysis, missing user validation |
| Architecture | HIGH | Direct codebase analysis + Flutter best practices |
| Pitfalls | MEDIUM | Domain expertise, some patterns inferred |

**Overall confidence:** MEDIUM

### Gaps to Address

- **NGA API specifics:** Reply, quote, and new thread API formats need verification via actual HTTP inspection
- **Search API complexity:** NGA's search may require JSESSION handling or other undocumented requirements
- **User feedback loop:** No user research conducted on feature priorities
- **Performance baseline:** Current thread parsing performance not benchmarked — need metrics before optimization

## Sources

### Primary (HIGH confidence)
- Existing codebase analysis (`/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/`)
- pub.dev package verification (Jan 2025)
- Flutter official documentation (flutter.dev)

### Secondary (MEDIUM confidence)
- NGA HTTP client implementation analysis
- Thread parser and cookie store code review
- General forum app patterns (Reddit, Tapatalk, Discourse)

### Tertiary (LOW confidence)
- NGA API behavior — inferred from existing HTTP client, not documented
- iOS design patterns — standard Cupertino guidelines, not NGA-specific

---

*Research completed: 2026-01-23*
*Ready for roadmap: yes*
