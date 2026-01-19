import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/nga_fetcher.dart';

import '../data/nga_repository.dart';
import '../src/auth/nga_cookie_store.dart';

part 'thread/thread_body.dart';
part 'thread/thread_palette.dart';
part 'thread/thread_post_widgets.dart';
part 'thread/thread_reply_composer.dart';
part 'thread/thread_reply_widgets.dart';
part 'thread/thread_user_avatar.dart';

/// Thread detail screen.
///
/// Displays the posts (first page) of a thread.
class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    required this.tid,
    this.title,
  });

  final int tid;
  final String? title;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _posts = <ThreadPost>[];
  final _postKeys = <String>{};
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _loadMoreError;

  int _currentPage = 1;

  late NgaRepository _repository;

  String get _cookie => NgaCookieStore.cookie.value;

  @override
  void initState() {
    super.initState();
    _repository = NgaRepository(cookie: _cookie);
    NgaCookieStore.cookie.addListener(_onCookieChanged);
    _refreshThread();
  }

  void _onCookieChanged() {
    _repository.close();
    _repository = NgaRepository(cookie: _cookie);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    NgaCookieStore.cookie.removeListener(_onCookieChanged);
    _scrollController.dispose();
    _repository.close();
    super.dispose();
  }

  Future<void> _refreshThread() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _hasMore = true;
      _error = null;
      _loadMoreError = null;
      _currentPage = 1;
      _posts.clear();
      _postKeys.clear();
    });

    await _fetchThreadPage(1);
  }

  Future<void> _fetchMoreThread() async {
    if (_loading || _loadingMore || !_hasMore) {
      return;
    }
    await _fetchThreadPage(_currentPage + 1);
  }

  Future<void> _fetchThreadPage(int page) async {
    if (!NgaCookieStore.hasCookie) {
      setState(() {
        _error = 'Cookie not configured.';
        _loading = false;
      });
      return;
    }

    if (page <= 1) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _loadingMore = true;
        _loadMoreError = null;
      });
    }

    if (kDebugMode) {
      debugPrint('=== [NGA] Fetch thread cookie len=${_cookie.length} ===');
      debugPrint(
        '=== [NGA] Fetch thread cookie cookies: '
        '${NgaCookieStore.summarizeCookieHeader(_cookie)} ===',
      );
    }

    try {
      final detail = await _repository.fetchThread(
        widget.tid,
        page: page,
      );
      final uniquePosts = detail.posts
          .where((post) => _postKeys.add(_threadPostKey(post)))
          .toList(growable: false);

      if (kDebugMode) {
        debugPrint(
          '=== [NGA] Thread tid=${widget.tid} page=$page url=${detail.url} '
          'posts=${detail.posts.length} unique=${uniquePosts.length} ===',
        );
      }

      setState(() {
        if (page <= 1) {
          _posts.addAll(uniquePosts);
          _hasMore = uniquePosts.isNotEmpty;
          _loading = false;
        } else {
          if (uniquePosts.isEmpty) {
            _hasMore = false;
          } else {
            _currentPage = page;
            _posts.addAll(uniquePosts);
          }
          _loadingMore = false;
        }
      });
    } catch (e) {
      setState(() {
        if (page <= 1) {
          _error = e.toString();
          _loading = false;
        } else {
          _loadMoreError = e.toString();
          _loadingMore = false;
        }
      });
    }
  }

  String _threadPostKey(ThreadPost post) {
    final pid = post.pid;
    if (pid != null) {
      return 'pid:$pid';
    }
    final normalized = post.contentText.trim();
    final uid = post.authorUid ?? post.author?.uid ?? -1;
    final hash = _fnv1a32(normalized);
    return 'u:$uid|h:$hash|l:${normalized.length}';
  }

  int _fnv1a32(String input) {
    const fnvPrime = 16777619;
    var hash = 2166136261;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThreadPalette.backgroundLight,
      appBar: AppBar(
        backgroundColor: _ThreadPalette.backgroundLight,
        surfaceTintColor: _ThreadPalette.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: _ThreadPalette.borderLight),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new),
          color: _ThreadPalette.textPrimary,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(
          widget.title ?? 'Post Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ThreadPalette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            color: _ThreadPalette.textPrimary,
            tooltip: 'More',
          ),
        ],
      ),
      body: _ThreadBody(
        loading: _loading,
        error: _error,
        posts: _posts,
        scrollController: _scrollController,
        loadingMore: _loadingMore,
        hasMore: _hasMore,
        loadMoreError: _loadMoreError,
        onRefresh: _refreshThread,
        onLoadMore: _fetchMoreThread,
      ),
      bottomNavigationBar: const _ReplyComposer(),
    );
  }
}
