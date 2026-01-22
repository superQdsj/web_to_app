# Roadmap: NGA Forum App

**Version:** 1.0
**Created:** 2026-01-23
**Depth:** Standard

## Overview

Five-phase roadmap to deliver a fast, beautiful iOS-native NGA forum client. Phases are ordered by dependency: Foundation/Auth first (enables everything), Forum Browsing second (core reading entry), Thread Reading third (core content), Replies fourth (interactive extension), and Polish/Performance last (optimization layer).

## Progress

| Phase | Goal | Status | Plans |
|-------|------|--------|-------|
| 1 | Foundation & Authentication | Planning | 4 plans |
| 2 | Forum Browsing | Pending | - |
| 3 | Thread Reading | Pending | - |
| 4 | Replies | Pending | - |
| 5 | Polish & Performance | Pending | - |

---

## Phase 1: Foundation & Authentication

**Goal:** Users can log in and have their session persist across app restarts.

**Dependencies:** None (foundational)

**Requirements:** AUTH-01, AUTH-02, AUTH-03

### Plans

- [ ] 01-01-PLAN.md — Splash screen and auth state initialization
- [ ] 01-02-PLAN.md — Login WebView sheet UI polish with success animation
- [ ] 01-03-PLAN.md — Auth-aware header with avatar and username display
- [ ] 01-04-PLAN.md — Long-press avatar logout integration

### Success Criteria

1. User can tap login button to open WebView, complete NGA credentials, and have cookies (`ngaPassportUid`, `ngaPassportCid`) extracted automatically.
2. User can close and reopen the app without needing to log in again (cookies persisted to secure storage).
3. User's avatar and username appear in the app header after successful login.
4. User can tap logout to clear session and return to unauthenticated state.

---

## Phase 2: Forum Browsing

**Goal:** Users can navigate from forum categories to boards to thread lists with pagination.

**Dependencies:** Phase 1 (authentication required for API calls)

**Requirements:** FORUM-01, FORUM-02, FORUM-03

### Success Criteria

1. User sees forum categories (e.g., "游戏区", "技术区") organized hierarchically on the home screen.
2. User can tap a category to expand and see its boards/forums.
3. User can tap a board to see its thread list with titles, authors, and reply counts.
4. User can scroll to the bottom of thread list and tap "Next Page" to load more threads (pagination).

---

## Phase 3: Thread Reading

**Goal:** Users can read thread content including posts with images, with efficient handling of large threads.

**Dependencies:** Phase 2 (need board to select thread from)

**Requirements:** THREAD-01, THREAD-02, THREAD-03, THREAD-04

### Success Criteria

1. User can tap a thread in the list and see all posts with author info, timestamps, and content.
2. User can tap an image in a post to view it full-screen in a gallery view.
3. User can scroll through large threads (100+ pages) without the app freezing (lazy/paginated loading).
4. Images in posts load progressively with placeholders, reducing perceived load time.

---

## Phase 4: Replies

**Goal:** Users can compose and post replies to existing threads with clear feedback.

**Dependencies:** Phase 3 (need thread to reply to)

**Requirements:** REPLY-01, REPLY-02

### Success Criteria

1. User can tap a "Reply" button on any thread to open a composer with a text field.
2. User can type their reply and submit it to the NGA server.
3. User sees a loading indicator while the reply is posting.
4. User receives success confirmation when the reply is posted, or an error message if posting fails.

---

## Phase 5: Polish & Performance

**Goal:** The app achieves 60fps scrolling, smooth loading states, and responsive performance through background processing.

**Dependencies:** All previous phases

**Requirements:** PERF-01, PERF-02, PERF-03, UI-01, UI-02, UI-03

### Success Criteria

1. Thread list scrolls smoothly at 60fps without jank or dropped frames.
2. HTML parsing runs on a background Isolate, keeping the UI responsive during data processing.
3. Loading states across the app use shimmer skeleton screens instead of spinners.
4. App navigation follows iOS patterns: swipe-back gesture works, page transitions are smooth.
5. App uses Cupertino widgets throughout for native iOS appearance.

---

## Phase Ordering Rationale

1. **Foundation & Auth first:** Authentication is prerequisite for all API calls. Without login, users can only browse (read-only), but session persistence and identity display require auth foundation.

2. **Forum Browsing second:** The core reading workflow starts here. Users must select a forum before they can view threads.

3. **Thread Reading third:** Depends on forum browsing (need to select a board to view threads from). This is the primary content consumption experience.

4. **Replies fourth:** Interactive feature built on top of thread reading. Users reply to threads they can already read.

5. **Polish last:** Performance optimizations and UI polish layer on top of completed features. Cannot optimize what is not yet built.

---

## Coverage

| Requirement | Phase |
|-------------|-------|
| AUTH-01: WebView login with cookie extraction | 1 |
| AUTH-02: Session persistence | 1 |
| AUTH-03: User identity display | 1 |
| FORUM-01: Board list with categories | 2 |
| FORUM-02: Thread list in board | 2 |
| FORUM-03: Thread list pagination | 2 |
| THREAD-01: Thread content with posts | 3 |
| THREAD-02: Image loading with caching | 3 |
| THREAD-03: Large thread lazy loading | 3 |
| THREAD-04: Image tap-to-view | 3 |
| REPLY-01: Compose and post replies | 4 |
| REPLY-02: Reply feedback (loading/success/error) | 4 |
| PERF-01: HTML parsing off main thread | 5 |
| PERF-02: 60fps scrolling | 5 |
| PERF-03: Progressive image loading | 5 |
| UI-01: Cupertino widgets | 5 |
| UI-02: iOS navigation patterns | 5 |
| UI-03: Shimmer loading states | 5 |

**Total:** 17/17 requirements mapped

---

*Roadmap created: 2026-01-23*
*Phase 1 plans added: 2026-01-23*
*Plan 01-04 added: 2026-01-23*
