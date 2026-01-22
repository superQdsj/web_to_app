# External Integrations

**Analysis Date:** 2026-01-23

## APIs & External Services

**NGA Forum (Primary Backend):**
- Base URL: `https://bbs.nga.cn`
- Purpose: Forum browsing, thread list, thread details, login
- HTTP Client: Custom `NgaHttpClient` using `http` package
- Location: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/http/nga_http_client.dart`
- Repository: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/data/nga_repository.dart`

**Key Endpoints:**
| Endpoint | Purpose |
|----------|---------|
| `/nuke.php?__lib=login&__act=account&login` | User login via WebView |
| `/thread.php?fid={fid}&page={page}` | Fetch forum thread list |
| `/read.php?tid={tid}&page={page}` | Fetch thread detail with posts |

## Authentication & Identity

**Authentication Method:** Cookie-based authentication
- Cookies stored via `shared_preferences`
- Key cookies:
  - `ngaPassportUid` - User ID
  - `ngaPassportCid` - Login token (HttpOnly)
- Cookie store implementation: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_cookie_store.dart`
- User store implementation: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_user_store.dart`

**Login Flow:**
- WebView-based login at `https://bbs.nga.cn/nuke.php?__lib=login&__act=account&login`
- JavaScript injection to capture `loginSuccess` console log event
- Cookie extraction via `webview_cookie_manager_plus`
- Implementation: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/login_webview_sheet.dart`

## Data Storage

**Local Storage:**
- `shared_preferences` - Key-value storage for:
  - `nga_cookies` - Authentication cookies
  - `nga_user_info` - User profile data (uid, username, avatar)
- Location: Device secure storage (platform-dependent)

**Static Data:**
- JSON files in `assets/data/` directory
- Forum category data: `assets/data/forum_categories_merged.json`

## WebView Integration

**WebView Platform:**
- `webview_flutter` for cross-platform WebView
- `webview_flutter_android` for Android-specific features
- `webview_cookie_manager_plus` for cookie access

**Purpose:**
- User login (captures NGA session cookies)
- JavaScript channel for login success detection

**Android Specific:**
- Debugging enabled for login flow debugging

## Encoding & Parsing

**Character Encoding:**
- GBK encoding support (NGA uses GBK)
- Custom decoder: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/codec/decode_best_effort.dart`

**HTML Parsing:**
- `html` package for parsing forum pages
- Custom parsers:
  - `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/forum_parser.dart` - Forum thread list
  - `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/thread_parser.dart` - Thread detail and posts

## Monitoring & Observability

**Debug Logging:**
- `debugPrint` via `kDebugMode` checks
- Log prefixes: `[NGA][LoginWebView]`, `[NGA][UserStore]`, `[NGA][NgaCookieStore]`

## CI/CD & Deployment

**Build Commands:**
```bash
cd nga_app && fvm flutter pub get      # Install dependencies
cd nga_app && fvm flutter run          # Development
cd nga_app && fvm flutter build apk    # Android APK
cd nga_app && fvm flutter build ios    # iOS IPA
```

**Development Tools:**
- FVM (Flutter Version Management) for SDK consistency
- Flutter Analyze for linting
- Dart format for code formatting

## Environment Configuration

**No environment variables detected:**
- App does not use `.env` files
- Configuration hardcoded in source files
- Cookie/auth data stored in `shared_preferences`

## Key Files Reference

| Purpose | File Path |
|---------|-----------|
| HTTP Client | `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/http/nga_http_client.dart` |
| Repository | `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/data/nga_repository.dart` |
| Cookie Store | `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_cookie_store.dart` |
| User Store | `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/auth/nga_user_store.dart` |
| Login WebView | `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/screens/login_webview_sheet.dart` |
| Thread Parser | `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/thread_parser.dart` |
| Forum Parser | `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/src/parser/forum_parser.dart` |

---

*Integration audit: 2026-01-23*
