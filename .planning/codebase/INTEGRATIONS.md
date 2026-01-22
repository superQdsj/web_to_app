# External Integrations

**Analysis Date:** 2026-01-23

## APIs & External Services

**NGA Forum (bbs.nga.cn):**
- Primary backend for forum data
- Base URL: `https://bbs.nga.cn`
- Authentication: Cookie-based (ngaPassportUid, ngaPassportCid)
- Endpoints:
  - `GET /thread.php?fid={forum_id}&page={page}` - Fetch forum thread list
  - `GET /read.php?tid={thread_id}&page={page}` - Fetch thread detail
  - `GET /nuke.php?__lib=login&__act=account&login` - Login page

## Data Storage

**Local Storage (SharedPreferences):**
- Cookies: `nga_cookies` key - Full cookie header string
- User Info: `nga_user_info` key - JSON with uid, username, avatarUrl
- Storage: `shared_preferences` package (iOS NSUserDefaults, Android SharedPreferences)
- No file storage for user-generated content

**File Storage:**
- Local assets only: `assets/data/forum_categories_merged.json`
- No cloud file storage integration

**Caching:**
- None detected - No explicit caching layer

## Authentication & Identity

**Auth Provider: NGA Forum (Custom Cookie-Based)**
- Implementation: WebView-based login flow
  - `login_webview_sheet.dart` - WebView login widget
  - `webview_cookie_manager_plus` - Extract cookies from WebView
- Cookie extraction:
  - `ngaPassportUid` - User ID
  - `ngaPassportCid` - Login token (HttpOnly)
- Cookie persistence:
  - `nga_cookie_store.dart` - Cookie storage service
  - `nga_user_store.dart` - User info storage service
- Session duration: Until cookies expire or user logs out

**JavaScript Bridge:**
- NGA login page outputs `loginSuccess` JSON via console.log
- Hook injects JavaScript to capture via `NGA_LOGIN_SUCCESS` channel
- Captures: uid, username, avatar

## Monitoring & Observability

**Error Tracking:**
- None detected - No Sentry, Crashlytics, or similar integration

**Logs:**
- `debugPrint()` for development logging
- Log prefix: `[NGA][Category]` for filtering
- Debug mode checks via `kDebugMode`

## CI/CD & Deployment

**Hosting:**
- Not configured - Development in progress

**CI Pipeline:**
- Not detected - No GitHub Actions, Bitrise, or CI/CD configuration

## Environment Configuration

**Required configuration:**
- All configuration hardcoded in source
- No environment-specific builds

**Secrets location:**
- No dedicated secrets management
- Cookies stored in SharedPreferences (not committed to git)
- `private/` folder git-ignored for development data

## Webhooks & Callbacks

**Incoming:**
- JavaScript message channel for login success callback
- `NGA_LOGIN_SUCCESS` channel receives JSON from injected script

**Outgoing:**
- HTTP requests to NGA API endpoints
- No outgoing webhooks configured

## Data Encoding

**Character Encoding:**
- `charset` package handles GB18030, GBK, UTF-8
- Best-effort decoding from response headers and HTML meta tags
- Chinese forum content requires GBK/GB18030 support

**Content Parsing:**
- `html` package for HTML parsing
- Custom parsers: `forum_parser.dart`, `thread_parser.dart`

---

*Integration audit: 2026-01-23*
