# NGA Forum App

## What This Is

A complete NGA forum replacement app that extracts data from HTML and presents it through an elegant, iOS-native Flutter UI with smooth animations and excellent performance. The app is a pure presentation layer — it retrieves and displays data exactly as NGA provides it, without algorithmic sorting or content curation.

## Core Value

**Fast, beautiful access to all NGA forum features.**

Speed is the primary design constraint. Everything else (animations, features, offline support) matters only insofar as it doesn't compromise core performance.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] **CORE-01**: Browse board/forum list with category organization
- [ ] **CORE-02**: View thread list within a board
- [ ] **CORE-03**: Read thread content (posts, replies)
- [ ] **CORE-04**: Reply to existing threads
- [ ] **CORE-05**: WebView-based authentication (extract cookies)
- [ ] **CORE-06**: Session persistence across app restarts

### Out of Scope

- [Algorithmic content sorting] — Not a content curator, just presents NGA data
- [Push notifications] — Deferred to v2
- [Offline-first architecture] — Deferred to v2 (focus on speed first)

## Context

**Existing codebase:**
- Flutter app with screens: home_screen, forum_screen, thread_screen, login_webview_sheet
- Architecture: models, services, parsers, http, auth modules
- Authentication: WebView cookie extraction for `ngaPassportUid` and `ngaPassportCid`
- HTML parsing: Custom parsers in `src/parser/`

**Known challenges:**
- NGA HTML structure may change, requiring parser updates
- Large threads (100+ pages) need efficient handling
- Image/media loading performance is critical

## Constraints

- **Scope**: MVP first — ship core reading/reply functionality before full feature set
- **Performance**: Speed-first design — instant page loads, 60fps scrolling
- **Architecture**: Build on existing codebase — don't restart from scratch
- **UI Style**: iOS-native design language — smooth animations, Apple's Human Interface Guidelines

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| iOS-native UI | User preference for Apple design language, smooth animations | — Pending |
| MVP approach | Ship core features first, validate before expanding scope | — Pending |
| Pure presentation layer | No algorithmic sorting or curation — present NGA data as-is | — Pending |
| WebView auth | NGA requires browser-based login; extract cookies from WebView | — Pending |

---

*Last updated: 2026-01-23 after project initialization*
