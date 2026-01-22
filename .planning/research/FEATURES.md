# Feature Research

**Domain:** Mobile Forum Application (NGA Forum)
**Researched:** 2026-01-23
**Confidence:** MEDIUM (WebSearch unavailable, based on codebase analysis and domain knowledge)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Status | Notes |
|---------|--------------|------------|--------|-------|
| **Forum Browsing** | Core forum navigation - forums, subforums, thread lists | MEDIUM | DONE | Currently implemented via ForumScreen |
| **Thread Reading** | View post content with pagination | LOW | DONE | ThreadScreen with page loading |
| **User Authentication** | Login/logout, session persistence | MEDIUM | DONE | Cookie-based via WebView |
| **Reply to Thread** | Post comments on threads | MEDIUM | PARTIAL | Basic composer exists, needs full NGA API support |
| **Dark Mode** | System-appropriate theming | LOW | DONE | NgaTheme.light/dark implemented |
| **Forum Navigation** | Browse and search forums | MEDIUM | PARTIAL | MenuDrawerGrid exists, search missing |
| **Post Author Info** | Avatar, username, user level | LOW | DONE | ThreadUserAvatar implemented |
| **Basic Formatting** | Text, links, basic emoticons | LOW | DONE | html parsing for content |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Native Performance** | 60fps scrolling, instant load | HIGH | Speed-first design per project goals |
| **iOS-Native Feel** | Cupertino widgets, iOS patterns | MEDIUM | Already using cupertino_icons, can expand |
| **Smart Caching** | Offline read, background refresh | MEDIUM | shared_preferences exists, needs expansion |
| **Image Gallery** | Full-screen image viewer with zoom | MEDIUM | Need to implement |
| **Quick Actions** | Long-press menus, swipe actions | LOW | Can add quickly with high ROI |
| **Reading Mode** | Distraction-free, font controls | LOW | Differentiation from web view |
| **Fast Reply** | One-tap reply with templates | LOW | Pre-composed responses |
| **Thread Tracking** | Bookmark, unread indicators | MEDIUM | User engagement feature |
| **Search Integration** | Forum-level search, filters | HIGH | Complex NGA search API |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Full Editor** | Users want rich text | NGA uses BBCode, complex to replicate | Support core formatting only |
| **Push Notifications** | "Don't miss anything" | Battery drain, complexity, NGA doesn't provide | Periodic polling or manual refresh |
| **Offline Mode** | "Read on subway" | Content staleness, storage management | Cached threads only, explicit expiry |
| **Chat/Real-time** | "Modern messaging" | WebView limitations, NGA is async | PM system only, no WebSocket |
| **Social Features** | "Follow users" | NGA doesn't have social graph | Follow forums instead |
| **Content Creation** | "Post from app" | NGA posting API is complex | MVP: reply only, defer new threads |
| **In-App Browser** | "Click links without leaving" | Security, UX fragmentation | Deep link handling, keep in app |

## Feature Dependencies

```
Authentication (Cookie Store)
    └── User Session ──requires──> Login Flow
                              └── WebView Login ──requires──> Cookie Extraction

Forum Browsing
    └── Forum Categories ──requires──> Category Service
                            └── Forum List ──requires──> Category Service
                                └── Thread List ──requires──> NGA HTTP Client
                                    └── Thread Detail ──requires──> Thread Parser
                                        └── Reply ──requires──> Auth + Thread Detail
                                            └── Quote Reply ──requires──> Reply
                                                └── New Thread ──requires──> BBCode Parser

User Features
    └── Profile Drawer ──enhances──> Authentication
    └── Favorites ──requires──> User Session
    └── PM System ──requires──> Authentication + NGA HTTP Client

Reading Experience
    └── Pagination ──enhances──> Thread Detail
    └── Image Gallery ──enhances──> Thread Detail
    └── Caching ──enhances──> All Reading Features
```

### Dependency Notes

- **Reply requires Auth + Thread Detail:** Cannot post without being logged in and viewing a thread
- **New Thread requires BBCode Parser:** NGA uses BBCode, not HTML - needs custom parser
- **Favorites requires User Session:** Must know who the user is to save preferences
- **Caching enhances All Reading Features:** Can be added progressively

## MVP Definition

### Launch With (v1)

Minimum viable product - what's needed to validate the concept.

- [x] Forum category browsing (grid view)
- [x] Thread list with pagination
- [x] Thread detail with post content
- [x] User authentication via WebView login
- [x] Dark mode theming
- [x] Reply to existing threads (basic)

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] **Quote reply** — Reply with quote, common forum pattern
- [ ] **Search** — Forum-level search capability
- [ ] **Image gallery** — Tap images to view full screen
- [ ] **Favorites/Bookmarks** — Save threads for later
- [ ] **User profile detail** — View other users' posts
- [ ] **Post actions** — Vote, report, ignore user

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **New thread creation** — Full BBCode editor, requires significant work
- [ ] **Private messages** — NGA PM system integration
- [ ] **Push notifications** — Background fetch, remote notifications
- [ ] **Offline reading** — Local cache with expiry
- [ ] **Thread subscription** — Track replies to subscribed threads
- [ ] **Search history** — Local storage of search queries

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Phase |
|---------|------------|---------------------|----------|-------|
| Reply to thread | HIGH | MEDIUM | P1 | v1 |
| Quote reply | HIGH | LOW | P2 | v1.x |
| Image gallery | MEDIUM | MEDIUM | P2 | v1.x |
| Search | HIGH | HIGH | P2 | v1.x |
| Favorites | MEDIUM | LOW | P2 | v1.x |
| New thread | MEDIUM | HIGH | P3 | v2 |
| Private messages | MEDIUM | HIGH | P3 | v2 |
| Offline mode | LOW | MEDIUM | P3 | v2 |
| Push notifications | LOW | HIGH | P3 | v2 |

**Priority key:**
- P1: Must have for launch (v1)
- P2: Should have, add when possible (v1.x)
- P3: Nice to have, future consideration (v2+)

## Competitor Feature Analysis

| Feature | NGA Web | Tapatalk | Reddit App | Our Approach |
|---------|---------|----------|------------|--------------|
| Thread reading | Yes | Yes | Yes | Priority 1 - DONE |
| Reply | Yes | Yes | Yes | Priority 1 - PARTIAL |
| Quote reply | Yes | Yes | Yes | Add v1.x |
| Search | Yes | Yes | Yes | Add v1.x - more complex |
| Image viewer | Basic | Basic | Rich | Add gallery v1.x |
| Dark mode | No | Yes | Yes | DONE |
| Offline | No | No | Yes | Defer v2 |
| Push | No | No | Yes | Defer v2 |
| New thread | Yes | Yes | Yes | Defer v2 |

## Sources

- Codebase analysis: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/`
- NGA HTTP client implementation: `nga_app/lib/src/http/nga_http_client.dart`
- Thread parser: `nga_app/lib/src/parser/thread_parser.dart`
- Cookie store: `nga_app/lib/src/auth/nga_cookie_store.dart`
- Theme system: `nga_app/lib/theme/`

**Note:** WebSearch unavailable during research. Confidence is MEDIUM based on:
- Direct codebase analysis
- General forum app patterns (Reddit, Tapatalk, Discourse)
- NGA API exploration via existing HTTP client

---

*Feature research for: NGA Forum Mobile App*
*Researched: 2026-01-23*
