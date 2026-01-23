# Phase 4: Replies - Research

**Researched:** 2026-01-23
**Domain:** NGA Forum Reply API integration, Flutter form handling, and state management
**Confidence:** MEDIUM (API details unverified due to web search limitations; patterns verified from codebase)

## Summary

This phase implements reply functionality for the NGA Forum Flutter app. The existing codebase provides substantial infrastructure:
- **NgaHttpClient** already supports POST requests with cookie injection
- **NgaRepository** follows the established pattern for API operations
- **NgaCookieStore** manages authentication state reactively
- **Reply composer UI** exists as a stub in `thread_reply_composer.dart`

The key challenge is integrating with NGA's reply API, which requires:
1. POST request to the reply endpoint with thread ID and content
2. Form validation and loading states in the composer
3. Success/error feedback with proper state management
4. Optional: quote reply support (referencing a specific post PID)

**Primary recommendation:** Extend NgaRepository with a `postReply()` method, wire it to the existing composer UI with proper state management, and implement loading/success/error states. Start with plain text replies; defer BBCode formatting for future phases.

## Standard Stack

The established libraries for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| http | 1.6.0 | HTTP client | Already in use; handles POST with proper encoding |
| shared_preferences | 2.5.4 | Persistent storage | Already in use for cookie persistence |
| html | 0.15.6 | HTML parsing | Already in use; parses reply confirmation page |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none needed) | - | Additional validation | Rely on Flutter's built-in TextFormField validators |
| (none needed) | - | State management | Use existing ValueNotifier pattern |

**Installation:**
```bash
cd nga_app && flutter pub get
# No new dependencies required for MVP reply functionality
```

## Architecture Patterns

### Recommended Project Structure
```
nga_app/lib/
├── data/
│   └── nga_repository.dart        # Add postReply() method here
├── screens/
│   └── thread/
│       ├── thread_reply_composer.dart  # Full implementation
│       └── thread_reply_widgets.dart   # Add reply feedback UI
└── src/
    ├── http/
    │   └── nga_http_client.dart    # Already supports POST
    └── auth/
        └── nga_cookie_store.dart   # Already provides auth state
```

### Pattern 1: Reply API Integration in Repository
**What:** Add `postReply()` method to NgaRepository following existing fetch patterns
**When to use:** For any API mutation (reply, quote, future thread creation)

**Example:**
```dart
// Based on existing fetchThread pattern in nga_repository.dart
Future<void> postReply(int tid, String content, {int? pid}) async {
  final url = Uri.parse('$_baseUrl/post.php').replace(
    queryParameters: <String, String>{
      'act': 'reply',
      'tid': tid.toString(),
      if (pid != null) 'pid': pid.toString(),
    },
  );

  final body = utf8.encode('content=$content');

  final resp = await _client.postBytes(
    url,
    cookieHeaderValue: _cookie,
    bodyBytes: body,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  );

  if (resp.statusCode != 200) {
    throw Exception('Failed to post reply: HTTP ${resp.statusCode}');
  }

  // Parse response to verify success
  final htmlText = _decodeResponse(resp);
  if (!_isReplySuccess(htmlText)) {
    throw Exception('Reply may have failed - confirmation not found');
  }
}

bool _isReplySuccess(String htmlText) {
  // Check for success indicators in NGA response
  return htmlText.contains('发布成功') ||
         htmlText.contains('发帖成功') ||
         htmlText.contains('reply_success');
}
```

### Pattern 2: Stateful Reply Composer with Loading State
**What:** Convert stateless `_ReplyComposer` to stateful widget with submission handling
**When to use:** When composer needs to manage text input, validation, and API submission

**Example:**
```dart
// Based on thread_reply_composer.dart existing structure
class _ReplyComposer extends StatefulWidget {
  const _ReplyComposer({required this.tid});

  final int tid;

  @override
  State<_ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<_ReplyComposer> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repository = NgaRepository(cookie: NgaCookieStore.cookie.value);
      await repository.postReply(widget.tid, content);

      // Success: clear input and show feedback
      _textController.clear();
      if (mounted) {
        _showSuccessSnackBar();
        // Optionally trigger thread refresh
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('回复发布成功'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).extension<NgaColors>()?.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _ThreadPalette;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.backgroundLight,
          border: Border(top: BorderSide(color: palette.borderLight)),
        ),
        child: Row(
          children: [
            const _UserAvatar(name: 'You', size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: !_submitting,
                decoration: InputDecoration(
                  hintText: 'Add a reply...',
                  hintStyle: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: palette.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                ),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 3,
                onSubmitted: _submitting ? null : (_) => _submitReply(),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 36,
              width: 36,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: palette.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.send, size: 18),
                        color: Colors.white,
                        onPressed: _textController.text.trim().isEmpty
                            ? null
                            : _submitReply,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Pattern 3: Quote Reply Integration
**What:** Support replying to a specific post (quote reply)
**When to use:** When user taps reply on a specific post card

**Example:**
```dart
// Add to ThreadScreenState
int? _quotePid;

void _initiateQuoteReply(ThreadPost post) {
  setState(() {
    _quotePid = post.pid;
  });

  // Focus the reply composer
  _scrollController.animateTo(
    _scrollController.position.maxScrollExtent,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  // Could also show quoted content in composer
}

// Modify _ReplyComposer to accept optional quote
class _ReplyComposer extends StatefulWidget {
  const _ReplyComposer({required this.tid, this.quotePid, this.quoteContent});

  final int tid;
  final int? quotePid;
  final String? quoteContent;

  @override
  State<_ReplyComposer> createState() => _ReplyComposerState();
}

// In build(), show quoted content if present
if (widget.quoteContent != null) {
  children.add(
    Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ngaColors.quoteBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '"${widget.quoteContent}"',
        style: TextStyle(
          color: ngaColors.textSecondary,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );
}
```

### Anti-Patterns to Avoid

- **Don't block the entire UI during submission:** Use local loading indicator in the composer, not a full-screen dialog
- **Don't clear the thread state after successful reply:** Let the user manually refresh or auto-refresh after a delay
- **Don't ignore quote content in the post body:** NGA expects quoted content in a specific format
- **Don't make the composer full-screen by default:** Keep it as a bottom bar; expand on tap for better UX

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP POST with form data | Manual URL encoding | `utf8.encode()` + `http.postBytes()` | Handles Chinese characters correctly |
| Loading indicator | Custom animation | `CircularProgressIndicator` | Platform-native, accessible |
| Error message display | Toast library | `SnackBar` | Built into Scaffold, accessible |
| Text input validation | Custom validator | `TextFormField` validator parameter | Integrates with field styling |
| Connection timeout | Custom timer | `NgaHttpClient` timeout (30s) | Already configured, consistent |

**Key insight:** The existing infrastructure (NgaHttpClient, NgaRepository, ValueNotifier state) covers 90% of what reply functionality needs. Focus on wiring these together correctly.

## Common Pitfalls

### Pitfall 1: NGA Reply API Changes Without Warning
**What goes wrong:** Reply functionality breaks when NGA updates their API (endpoint, parameters, response format)
**Why it happens:** NGA's API is not versioned or documented for third-party use
**How to avoid:**
1. Wrap API calls in try/catch with user-friendly error messages
2. Log the raw response for debugging when failures occur
3. Consider adding a "test reply" mode that doesn't post but shows what would be sent
4. Monitor for NGA forum announcements about changes

**Warning signs:**
- "Failed to post reply" errors without specific cause
- Responses that don't contain expected success indicators
- Users reporting replies not appearing after "success"

### Pitfall 2: Race Condition Between Multiple Rapid Replies
**What goes wrong:** User submits multiple replies quickly, causing out-of-order posting or rate limiting
**Why it happens:** NGA may have rate limiting, and the app doesn't queue submissions
**How to avoid:**
1. Disable the send button while submission is in progress
2. Show clear loading state on the button
3. Consider a simple debounce (though less critical for forum posting)

**Warning signs:**
- "You are posting too fast" errors from NGA
- Replies appearing in wrong order
- Network errors during rapid submission

### Pitfall 3: Chinese Character Encoding Issues
**What goes wrong:** Chinese characters appear as garbage or question marks in the posted reply
**Why it happens:** Incorrect encoding in POST body; NGA expects GBK or UTF-8
**How to avoid:**
1. Use UTF-8 encoding (standard for modern NGA)
2. Set proper `Content-Type: application/x-www-form-urlencoded; charset=UTF-8`
3. Test with sample Chinese text before release

**Warning signs:**
- Server returns 200 but content is mangled
- "Invalid content" errors from NGA
- Test replies showing wrong characters

### Pitfall 4: Cookie Not Sent with POST Request
**What goes wrong:** 401 Unauthorized even though user is logged in
**Why it happens:** Cookie header missing from POST request (only GET had it before)
**How to avoid:** The existing NgaHttpClient already handles cookie injection for POST via `postBytes()`. Verify the cookie is passed:
```dart
// In postReply(), ensure cookie is passed:
await _client.postBytes(
  url,
  cookieHeaderValue: _cookie,  // This line is critical
  bodyBytes: bodyBytes,
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
);
```

**Warning signs:**
- "Not logged in" or authentication errors on reply attempts
- Works for GET requests but not POST
- Cookie works in browser but not in app

## Code Examples

### Complete Reply Submission Flow
```dart
// Based on existing patterns in nga_repository.dart and thread_screen.dart
class NgaRepository {
  // ... existing code ...

  static const String _baseUrl = 'https://bbs.nga.cn';

  /// Posts a reply to a thread.
  ///
  /// [tid] - Thread ID to reply to
  /// [content] - Reply content (plain text or BBCode)
  /// [pid] - Optional post ID to quote/reply to
  ///
  /// Returns the PID of the new post if available.
  Future<int?> postReply(
    int tid,
    String content, {
    int? pid,
  }) async {
    assert(tid > 0, 'Thread ID must be positive');
    assert(content.trim().isNotEmpty, 'Content cannot be empty');

    final url = Uri.parse('$_baseUrl/post.php').replace(
      queryParameters: <String, String>{
        'act': 'reply',
        'tid': tid.toString(),
        if (pid != null) 'pid': pid.toString(),
      },
    );

    // URL-encode the content for form submission
    final encodedContent = Uri.encodeComponent(content);
    final body = utf8.encode('content=$encodedContent');

    if (kDebugMode) {
      debugPrint('=== [NGA] Posting reply to tid=$tid ===');
      debugPrint('=== [NGA] URL: $url ===');
      debugPrint('=== [NGA] Content length: ${content.length} ===');
    }

    final resp = await _client.postBytes(
      url,
      cookieHeaderValue: _cookie,
      bodyBytes: body,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      timeout: const Duration(seconds: 30),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to post reply: HTTP ${resp.statusCode}');
    }

    final htmlText = _decodeResponse(resp);

    // Verify the reply was accepted
    if (!_isReplySuccess(htmlText)) {
      if (kDebugMode) {
        debugPrint('=== [NGA] Reply may have failed ===');
        debugPrint('=== [NGA] Response preview: ${htmlText.substring(0, 500)} ===');
      }
      throw Exception('Reply failed - please try again');
    }

    if (kDebugMode) {
      debugPrint('=== [NGA] Reply posted successfully ===');
    }

    // Try to extract the new post PID from response
    return _extractNewPostPid(htmlText);
  }

  bool _isReplySuccess(String htmlText) {
    // Check for various success indicators
    return htmlText.contains('发布成功') ||
           htmlText.contains('发帖成功') ||
           htmlText.contains('回复成功') ||
           htmlText.contains('操作成功') ||
           htmlText.contains('pid=');  // PID in URL often means success
  }

  int? _extractNewPostPid(String htmlText) {
    // Look for patterns like: pid123456 or "pid":123456
    final patterns = [
      RegExp(r'pid(\d+)'),
      RegExp(r'"pid":\s*(\d+)'),
      RegExp(r'#pid(\d+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(htmlText);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }
}
```

### Composer State Management
```dart
// Integrating reply composer with thread screen state
class _ThreadScreenState extends State<ThreadScreen> {
  // ... existing state ...

  bool _replySubmitting = false;
  String? _replyError;

  Future<void> _submitReply() async {
    if (_replySubmitting) return;

    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _replySubmitting = true;
      _replyError = null;
    });

    try {
      final repository = NgaRepository(cookie: NgaCookieStore.cookie.value);
      await repository.postReply(widget.tid, content);

      // Success
      _replyController.clear();
      _showSuccessMessage();

      // Optional: Auto-refresh thread after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _refreshThread();
      });
    } catch (e) {
      setState(() {
        _replyError = '发送失败: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _replySubmitting = false;
        });
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('回复发布成功'),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Block UI with dialog | In-composer loading indicator | Existing pattern | Better UX, non-blocking |
| Manual HTTP handling | NgaRepository pattern | Existing code | Consistent, testable |
| String cookie handling | ValueNotifier reactive state | Existing code | Automatic UI updates |
| Manual encoding | UTF-8 + Uri.encodeComponent | This phase | Correct Chinese handling |

**Deprecated/outdated:**
- `http.post()` - Replaced by `NgaHttpClient.postBytes()` for better control
- SetState for all state - Use ValueNotifier for cross-widget state

## Open Questions

1. **NGA Reply API Endpoint Verification**
   - What we know: NGA uses `post.php` for posting; the `act=reply` parameter is common
   - What's unclear: Exact endpoint URL, required parameters beyond `tid` and `content`
   - Recommendation: Test with a simple reply to verify the API works, then iterate on the implementation
   - **Confidence:** LOW - Need to verify via actual API call

2. **BBCode Support in Replies**
   - What we know: NGA supports BBCode formatting (b, i, quote, etc.)
   - What's unclear: Whether plain text is auto-converted or if BBCode is required
   - Recommendation: Start with plain text; add BBCode support in a future phase if needed
   - **Confidence:** MEDIUM - Based on forum conventions

3. **Rate Limiting Behavior**
   - What we know: Forums typically have posting rate limits
   - What's unclear: NGA's specific rate limits (requests per minute, etc.)
   - Recommendation: Implement basic rate limiting in composer (disable button during submission)
   - **Confidence:** MEDIUM - Based on forum patterns

4. **Reply Confirmation Handling**
   - What we know: NGA returns HTML pages (not JSON) after posting
   - What's unclear: Exact success/failure indicators in the response
   - Recommendation: Check for multiple success strings, log response for debugging
   - **Confidence:** LOW - Need to verify via actual API response

## Sources

### Primary (HIGH confidence)
- Existing codebase: `nga_app/lib/data/nga_repository.dart` - Repository pattern for API calls
- Existing codebase: `nga_app/lib/src/http/nga_http_client.dart` - HTTP client with POST support
- Existing codebase: `nga_app/lib/screens/thread/thread_reply_composer.dart` - Reply composer UI stub
- Existing codebase: `nga_app/lib/src/auth/nga_cookie_store.dart` - Authentication state management

### Secondary (MEDIUM confidence)
- Flutter documentation on TextFormField validation and state management
- Common forum API patterns (based on domain expertise)
- Previous phase research documents (FEATURES.md, PITFALLS.md)

### Tertiary (LOW confidence)
- NGA API documentation - Not accessible via web search during research
- BBCode formatting requirements - Deferred to future research
- Rate limiting specifics - Need to test empirically

## Metadata

**Confidence breakdown:**
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Uses existing, verified dependencies |
| Architecture | HIGH | Extends existing patterns correctly |
| API Integration | LOW | NGA API details unverified |
| Error Handling | MEDIUM | Based on forum conventions, needs testing |
| UI Patterns | HIGH | Uses existing Flutter patterns |

**Research date:** 2026-01-23
**Valid until:** 2026-04-23 (3 months - API details need verification via actual testing)

**Key finding:** The existing codebase infrastructure is sufficient for reply implementation. The main uncertainty is NGA's specific API endpoint and response format. The recommended approach is to implement with defensive error handling and test against the live API.

**Research notes:**
- WebSearch unavailable during research session (API errors)
- NGA API Wiki URL was inaccessible (404)
- Previous phase research documents provided valuable context
- Codebase analysis verified existing patterns are production-ready
