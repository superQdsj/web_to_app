# Phase 1: Foundation & Authentication - Context

**Gathered:** 2026-01-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can log in with NGA credentials via WebView, have cookies extracted automatically, and stay logged in across app restarts. Avatar and username displayed in authenticated state. Logout clears session and returns to unauthenticated state.

</domain>

<decisions>
## Implementation Decisions

### Login Flow
- **WebView presentation:** Modal sheet (current implementation exists, needs UI improvement for aesthetics)
- **Success detection:** Cookie change listener to detect when `ngaPassportUid` and `ngaPassportCid` are set
- **Transition:** Show success animation before dismissing WebView
- **Close behavior:** Allow cancel with close button (X) in WebView

### Session Storage
- **Storage approach:** SharedPreferences (user preference for now)
- **Data persisted:** Cookies (`ngaPassportUid`, `ngaPassportCid`), username, avatar URL
- **App restart:** Auto-login if session data exists
- **Expiration:** No local expiration (server handles expiration)

### Logout Behavior
- **Location:** Existing profile drawer widget has logout button
- **Data cleared:** All session data (cookies, username, avatar URL)
- **UI transition:** Confirm dialog then update current view to unauthenticated state
- **Confirmation:** Simple confirm dialog ("Are you sure you want to log out?")

### Error Handling
- **Network failure:** Fail fast - show error immediately
- **Invalid credentials:** Stay on login screen with error message
- **Partial/corrupt session:** Prompt user to re-login via dialog
- **Session expiration:** Server handles all expiration logic

</decisions>

<specifics>
## Specific Ideas

- Modal sheet WebView needs aesthetic improvement (current implementation is "rough and unattractive")
- User has existing profile drawer widget with logout button - don't recreate

</specifics>

<deferred>
## Deferred Ideas

- Secure storage upgrade (flutter_secure_storage) for better security - future consideration
- Remember username pre-fill after logout - Phase 1+ scope

</deferred>

---

*Phase: 01-foundation-authentication*
*Context gathered: 2026-01-23*
