# Phase 2: Forum Browsing - Research

**Researched:** 2026-01-23
**Domain:** NGA Forum API, Flutter hierarchical navigation, pagination patterns
**Confidence:** HIGH

## Summary

Phase 2 Forum Browsing leverages an existing codebase with significant infrastructure already in place. The app already implements forum category navigation through `MenuDrawerGrid`, thread list fetching via `NgaRepository`, and pagination through `ForumContent`. The primary research focus is identifying gaps between current implementation and the stated requirements (FORUM-01, FORUM-02, FORUM-03), and documenting remaining implementation work.

NGA forum data follows a three-level hierarchy: **Category** (e.g., "魔兽世界") -> **Subcategory** (e.g., "主版块") -> **Board** (e.g., "艾泽拉斯议事厅" with fid=7). Categories are loaded from a static JSON asset, while thread lists are fetched dynamically via the NGA API at `https://bbs.nga.cn/thread.php?fid={fid}&page={page}`. Authentication via cookies is required for API access.

The current implementation has a functional foundation but requires completion work: ensuring smooth navigation from category selection to thread display, improving the user experience when no forum is selected, and potentially implementing proper navigation stack behavior for board selection.

**Primary recommendation:** Complete the forum browsing flow by ensuring MenuDrawerGrid properly triggers thread list display, implementing a more prominent empty state when no board is selected, and adding visual feedback for navigation between hierarchical levels.

## Standard Stack

The established libraries and patterns for this domain:

### Core

| Library/Pattern | Version/Type | Purpose | Why Standard |
|-----------------|--------------|---------|--------------|
| `html` package | Flutter HTML parser | Parse NGA forum HTML responses | Official Dart package, robust selector support |
| `ValueNotifier` | Flutter state management | `NgaForumStore.activeFid` for forum selection | Built-in, simple, reactive |
| `FutureBuilder` | Flutter async widget | Loading states in `MenuDrawerGrid` | Standard pattern for async data |
| `ScrollController` | Flutter scroll management | Pagination trigger in `ForumContent` | Required for detecting scroll position |

### Supporting

| Pattern | Purpose | When to Use |
|---------|---------|-------------|
| `NgaRepository` | Centralized API client | All NGA data fetching |
| `ForumParser` | HTML parsing service | Extracting thread data from HTML |
| `ForumCategoryService` | Static data loader | Loading categories from assets |

### API Endpoints

| Endpoint | Parameters | Purpose |
|----------|------------|---------|
| `https://bbs.nga.cn/thread.php` | `fid` (required), `page` (optional) | Fetch thread list for a board |
| `https://bbs.nga.cn/read.php` | `tid` (required), `page` (optional) | Fetch thread detail (for Phase 3) |

**Installation (existing):**
```bash
cd nga_app && fvm flutter pub get
# Dependencies already in pubspec.yaml
```

## Architecture Patterns

### Recommended Project Structure

```
nga_app/lib/
├── screens/
│   ├── home_screen.dart          # Main scaffold with drawers
│   ├── forum_screen.dart         # ForumContent widget (already exists)
│   └── thread_screen.dart        # Thread detail (Phase 3)
├── widgets/
│   ├── menu_drawer_grid.dart     # Category/board navigation (exists)
│   ├── menu_drawer.dart          # Legacy drawer
│   └── avatar_button.dart        # User profile access
├── src/
│   ├── model/
│   │   ├── forum_category.dart   # Category hierarchy models (exists)
│   │   └── thread_item.dart      # Thread data model (exists)
│   ├── services/
│   │   └── forum_category_service.dart  # Category loader (exists)
│   ├── parser/
│   │   ├── forum_parser.dart     # Thread list HTML parser (exists)
│   │   └── thread_parser.dart    # Thread detail parser (exists)
│   ├── http/
│   │   └── nga_http_client.dart  # HTTP client with cookies (exists)
│   ├── nga_forum_store.dart      # Active forum state (exists)
│   └── auth/
│       └── nga_cookie_store.dart # Cookie management (exists)
└── data/
    └── nga_repository.dart       # Data repository (exists)
```

### Pattern 1: Hierarchical Navigation (Already Implemented)

**What:** Navigation from Category -> Subcategory -> Board -> Thread List using expandable accordion drawer.

**When to use:** When browsing forum hierarchy with multiple nested levels.

**Example from existing code:**
```dart
// Source: menu_drawer_grid.dart, forum_screen.dart
class MenuDrawerGrid extends StatefulWidget {
  // Expands categories to show subcategories and boards
  // Tapping a board calls NgaForumStore.setActiveFid(board.fid)
}

class ForumContent extends StatefulWidget {
  // Listens to NgaForumStore.activeFid changes
  // Automatically fetches threads when fid changes
}
```

### Pattern 2: Pagination with Scroll Detection (Already Implemented)

**What:** Load more threads when user scrolls near bottom of list.

**When to use:** Forum thread lists with more than one page of results.

**Example from existing code:**
```dart
// Source: forum_screen.dart
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return false;
    }
    const loadMoreThreshold = 200.0;
    if (position.pixels >= position.maxScrollExtent - loadMoreThreshold) {
      _fetchMoreThreads();
    }
    return false;
  },
  child: ListView.separated(
    itemCount: _threads.length + 1,  // +1 for load more footer
    // ...
  ),
)
```

### Pattern 3: State-Driven UI (Already Implemented)

**What:** UI automatically responds to state changes without manual refresh calls.

**When to use:** When data changes should trigger UI updates across different widgets.

**Example:**
```dart
// Source: nga_forum_store.dart, forum_screen.dart
class NgaForumStore {
  static final ValueNotifier<int?> activeFid = ValueNotifier<int?>(null);
}

class ForumContent extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    NgaForumStore.activeFid.addListener(_onFidChanged);
  }

  void _onFidChanged() {
    _fetchThreads();  // Auto-fetch when fid changes
  }
}
```

### Anti-Patterns to Avoid

- **Don't manually trigger refreshes:** Let ValueNotifier drive state changes automatically
- **Don't hardcode forum IDs:** Use the fid from JSON data (some fids are large numbers like 510502)
- **Don't skip authentication checks:** Always verify `NgaCookieStore.hasCookie` before API calls

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML parsing from NGA | Custom regex/string parsing | `html` package with CSS selectors | NGA HTML structure is complex; existing `ForumParser` handles edge cases |
| Cookie management | Custom storage | `NgaCookieStore` with `flutter_secure_storage` | Cookies contain auth tokens that must be encrypted |
| HTTP client | Raw `http.Client` | `NgaHttpClient` with proper UA, encoding, timeout | NGA requires specific User-Agent and GBK encoding handling |
| Category hierarchy | Build from scratch | `ForumCategoryService.loadCategories()` from JSON | Categories already defined with proper hierarchy in assets |

**Key insight:** The existing `ForumParser` extracts thread data using CSS selectors (`#topicrows tr.topicrow`), handling author, replies, post date, and last replier. This parsing logic is non-trivial due to NGA's variable HTML structure.

## Common Pitfalls

### Pitfall 1: Empty State Confusion
**What goes wrong:** Users open the app, see "暂无内容，选择版块后会显示主题列表" (No content, select a board to see thread list), and don't understand they need to open the drawer.

**Why it happens:** The empty state message is visible but the connection to the drawer is not obvious. The drawer button (MenuButton) may not clearly indicate its purpose.

**How to avoid:**
- Add a prominent hint or illustration pointing to the drawer
- Consider a bottom sheet or modal to select a board when none is active
- Add a "pulse" or highlight animation to the menu button when no forum is selected

**Warning signs:** Users report confusion in feedback, high bounce rate on first screen

### Pitfall 2: Deep Hierarchy Navigation
**What goes wrong:** Users navigate deep into categories but have no back button or breadcrumb to understand where they are.

**Why it happens:** The drawer navigation is modal (dismisses on selection) without preserving navigation context.

**How to avoid:**
- Consider whether `Navigator.pop(context)` after board selection is the right behavior
- Add a breadcrumb or header showing current path: "魔兽世界 > 主版块 > 艾泽拉斯议事厅"
- Implement proper back navigation with `WillPopScope` if needed

**Warning signs:** Users get lost, tap back expecting to return to previous drawer state

### Pitfall 3: Pagination Edge Cases
**What goes wrong:** Empty pages, duplicate threads, or infinite loading when reaching end of results.

**Why it happens:** NGA may return empty arrays, the same threads on different pages, or have inconsistent page counts.

**How to avoid:**
- Implement deduplication using `Set<int>` for thread IDs (already done with `_threadIds`)
- Handle empty page responses by setting `_hasMore = false`
- Add timeout for pagination requests

**Warning signs:** Log output shows duplicate thread IDs, infinite loading spinners

### Pitfall 4: Network Errors During Pagination
**What goes wrong:** User scrolls to load more, network fails silently, user stuck with no indication.

**Why it happens:** Error handling sets `_error` but may not be visible in the footer area.

**How to avoid:**
- Show error snackbar when pagination fails
- Allow retry by tapping the "上拉加载更多" (Pull to load more) footer
- Preserve loaded threads when pagination fails

**Warning signs:** Users report "load more doesn't work" in feedback

## Code Examples

### Fetching Thread List (Existing Pattern)
```dart
// Source: nga_repository.dart
Future<List<ThreadItem>> fetchForumThreads(int fid, {int page = 1}) async {
  final url = Uri.parse('$_baseUrl/thread.php').replace(
    queryParameters: <String, String>{
      'fid': fid.toString(),
      if (page > 1) 'page': page.toString(),
    },
  );

  final resp = await _client.getBytes(
    url,
    cookieHeaderValue: _cookie,
    timeout: const Duration(seconds: 30),
  );

  if (resp.statusCode != 200) {
    throw Exception('Failed to fetch forum: HTTP ${resp.statusCode}');
  }

  final htmlText = _decodeResponse(resp);
  final items = ForumParser().parseForumThreadList(htmlText);
  return items;
}
```

### Parsing Thread Items (Existing Pattern)
```dart
// Source: forum_parser.dart
List<ThreadItem> parseForumThreadList(String htmlText) {
  final doc = html_parser.parse(htmlText);
  final rows = doc.querySelectorAll('#topicrows tr.topicrow');
  final items = <ThreadItem>[];

  for (final row in rows) {
    final topicLink = row.querySelector('a.topic');
    if (topicLink == null) continue;

    final href = topicLink.attributes['href'];
    if (href == null || href.trim().isEmpty) continue;

    final tid = extractTidFromReadHref(href);
    if (tid == null) continue;

    final title = topicLink.text.trim();
    final repliesText = row.querySelector('a.replies')?.text;
    final replies = tryParseInt(repliesText);
    final authorLink = row.querySelector('a.author');
    final author = authorLink?.text.trim();

    items.add(ThreadItem(
      tid: tid,
      url: resolveNgaUrl(href).toString(),
      title: title,
      replies: replies,
      author: author,
      authorUid: extractUidFromHref(authorLink?.attributes['href'] ?? ''),
      postTs: tryParseInt(row.querySelector('span.postdate')?.text),
      lastReplyer: row.querySelector('span.replyer')?.text.trim(),
    ));
  }

  return items;
}
```

### Board Selection with State Update (Existing Pattern)
```dart
// Source: menu_drawer_grid.dart
InWell(
  onTap: () {
    NgaForumStore.setActiveFid(board.fid);
    Navigator.pop(context);  // Close drawer
  },
  child: // Board card UI
)
```

### Pagination Scroll Detection (Existing Pattern)
```dart
// Source: forum_screen.dart
Widget _buildLoadMoreFooter() {
  if (_loadingMore) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  if (!_hasMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '没有更多了',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(child: Text('上拉加载更多')),
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static category hardcoding | JSON asset loading | Pre-existing | Easier maintenance, no code changes for new categories |
| Raw HTTP requests | `NgaHttpClient` wrapper | Pre-existing | Consistent headers, encoding handling, timeout |
| Manual refresh | ValueNotifier state-driven | Pre-existing | Automatic UI updates, cleaner code |
| Basic pagination | Scroll threshold detection | Pre-existing | Smoother infinite scroll experience |

**Deprecated/outdated:**
- NGA's old JSON API (deprecated in favor of HTML scraping)
- Manual cookie parsing (now handled by `NgaCookieStore`)

## Open Questions

1. **Board Icon Loading Performance**
   - What we know: Board icons are loaded from external URLs (e.g., `https://img4.nga.178.com/proxy/cache_attach/ficon/7u.png`)
   - What's unclear: Network image caching strategy, fallback behavior when icons fail to load
   - Recommendation: Use `cached_network_image` package if icon loading causes performance issues

2. **Navigation Stack Behavior**
   - What we know: Currently, tapping a board closes the drawer with `Navigator.pop(context)`
   - What's unclear: Whether users expect to return to the same drawer state when navigating back
   - Recommendation: Test with users; consider preserving drawer state or adding breadcrumb navigation

3. **Category Data Freshness**
   - What we know: Categories are loaded from static JSON (`forum_categories_merged.json`)
   - What's unclear: How often NGA adds/removes categories, whether JSON needs periodic updates
   - Recommendation: Monitor NGA for category changes; consider adding a "refresh categories" option

## Sources

### Primary (HIGH confidence)
- Existing codebase implementation at `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/lib/`
- `forum_category_service.dart` - Category loading from JSON
- `nga_repository.dart` - API endpoint patterns
- `forum_screen.dart` - Pagination and state management
- `menu_drawer_grid.dart` - Hierarchical navigation UI

### Secondary (MEDIUM confidence)
- NGA forum structure observed from `forum_categories_merged.json`
- API endpoint patterns verified through existing code

### Tertiary (LOW confidence)
- NGA HTML structure for thread parsing (not officially documented, reverse-engineered)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Built on existing codebase with proven patterns
- Architecture: HIGH - Follows Flutter best practices already implemented
- Pitfalls: MEDIUM - Based on code review, not user testing yet

**Research date:** 2026-01-23
**Valid until:** 2026-07-23 (6 months - stable codebase)
