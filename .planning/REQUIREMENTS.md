# Requirements: NGA Forum App

**Defined:** 2026-01-23
**Core Value:** Fast, beautiful access to all NGA forum features

## v1 Requirements

Requirements for MVP release. Each maps to roadmap phases.

### Authentication

- [x] **AUTH-01**: User can log in via WebView and extract NGA cookies
- [x] **AUTH-02**: User session persists across app restarts
- [x] **AUTH-03**: User identity (avatar, username) displayed throughout app

### Forum Browsing

- [ ] **FORUM-01**: User can browse board/forum list organized by category
- [ ] **FORUM-02**: User can view thread list within a selected board
- [ ] **FORUM-03**: User can navigate pages of thread list (pagination)

### Thread Reading

- [ ] **THREAD-01**: User can read thread content with posts and author info
- [ ] **THREAD-02**: Images in posts load efficiently with caching
- [ ] **THREAD-03**: Large threads (100+ pages) load with lazy loading
- [ ] **THREAD-04**: User can tap images to view full size

### Replies

- [ ] **REPLY-01**: User can compose and post replies to existing threads
- [ ] **REPLY-02**: Reply posting shows loading state and success/error feedback

### Performance

- [ ] **PERF-01**: HTML parsing runs off main thread (Isolate)
- [ ] **PERF-02**: Thread list scrolls at 60fps without jank
- [ ] **PERF-03**: Images load progressively with placeholders

### iOS Native UI

- [ ] **UI-01**: App uses Cupertino widgets for iOS-native feel
- [ ] **UI-02**: Navigation follows iOS patterns (back swipe, proper transitions)
- [ ] **UI-03**: Loading states use shimmer skeletons

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Interactions

- **QUOTE-01**: User can quote and reply to specific posts
- **NEWTHREAD-01**: User can create new threads in a board
- **NEWTHREAD-02**: User can attach images to new threads

### User Features

- **PROFILE-01**: User can view their own profile
- **PROFILE-02**: User can view other users' profiles
- **FAV-01**: User can bookmark/favorite threads
- **FAV-02**: User can view favorited threads in a list
- **SEARCH-01**: User can search within forums
- **SEARCH-02**: User can search within a specific board

### Notifications

- **NOTIF-01**: User receives notifications for replies to their threads
- **NOTIF-02**: User receives notifications for quoted replies
- **NOTIF-03**: User can configure notification preferences

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Algorithmic content sorting | Pure presentation layer — present NGA data as-is |
| Push notifications | Deferred to v2 — focus on core performance first |
| Offline-first architecture | Deferred to v2 — focus on speed first |
| In-app browser for external links | Use system browser to avoid complexity |
| Social features (follow, DM) | Not core to forum reading experience |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Complete |
| AUTH-02 | Phase 1 | Complete |
| AUTH-03 | Phase 1 | Complete |
| FORUM-01 | Phase 2 | Pending |
| FORUM-02 | Phase 2 | Pending |
| FORUM-03 | Phase 2 | Pending |
| THREAD-01 | Phase 3 | Pending |
| THREAD-02 | Phase 3 | Pending |
| THREAD-03 | Phase 3 | Pending |
| THREAD-04 | Phase 3 | Pending |
| REPLY-01 | Phase 4 | Pending |
| REPLY-02 | Phase 4 | Pending |
| PERF-01 | Phase 5 | Pending |
| PERF-02 | Phase 5 | Pending |
| PERF-03 | Phase 5 | Pending |
| UI-01 | Phase 5 | Pending |
| UI-02 | Phase 5 | Pending |
| UI-03 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0 ✓

---

*Requirements defined: 2026-01-23*
*Last updated: 2026-01-23 after roadmap creation*
