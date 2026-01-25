import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/nga_thread_dom_repository.dart';
import '../src/auth/nga_cookie_store.dart';
import '../src/parser/full_parse.dart';
import '../theme/app_colors.dart';

/// Thread detail screen using DOM-based parsing.
///
/// Displays thread posts parsed by [NgaThreadDomParser].
class ThreadDomScreen extends StatefulWidget {
  const ThreadDomScreen({super.key, required this.tid, this.title});

  final int tid;
  final String? title;

  @override
  State<ThreadDomScreen> createState() => _ThreadDomScreenState();
}

class _ThreadDomScreenState extends State<ThreadDomScreen> {
  final _posts = <ThreadPost>[];
  final _postPids = <int>{};
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _loadMoreError;
  String _topicTitle = '';

  int _currentPage = 1;
  late NgaThreadDomRepository _repository;

  String get _cookie => NgaCookieStore.cookie.value;

  @override
  void initState() {
    super.initState();
    _repository = NgaThreadDomRepository(cookie: _cookie);
    NgaCookieStore.cookie.addListener(_onCookieChanged);
    _refreshThread();
  }

  @override
  void dispose() {
    NgaCookieStore.cookie.removeListener(_onCookieChanged);
    _scrollController.dispose();
    _repository.close();
    super.dispose();
  }

  void _onCookieChanged() {
    _repository.close();
    _repository = NgaThreadDomRepository(cookie: _cookie);
    if (mounted) {
      setState(() {});
    }
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
      _postPids.clear();
    });

    _repository.clearCache();
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
      debugPrint(
        '=== [NGA] Fetch DOM thread tid=${widget.tid} page=$page ===',
      );
    }

    try {
      final sw = Stopwatch()..start();
      final threadData = await _repository.fetchThread(widget.tid, page: page);
      final uniquePosts = threadData.posts
          .where((post) => _postPids.add(post.pid))
          .toList(growable: false);
      if (kDebugMode) {
        final minFloor = threadData.posts.isEmpty
            ? null
            : threadData.posts
                .map((p) => p.floor)
                .reduce((a, b) => a < b ? a : b);
        final maxFloor = threadData.posts.isEmpty
            ? null
            : threadData.posts
                .map((p) => p.floor)
                .reduce((a, b) => a > b ? a : b);
        debugPrint(
          '=== [NGA] DOM thread data tid=${widget.tid} page=$page '
          'titleLen=${threadData.topicTitle.length} posts=${threadData.posts.length} '
          'uniqueAdded=${uniquePosts.length} floor=[$minFloor,$maxFloor] '
          'elapsed=${sw.elapsedMilliseconds}ms ===',
        );
      }

      if (page <= 1) {
        setState(() {
          _topicTitle = threadData.topicTitle;
          _posts
            ..clear()
            ..addAll(uniquePosts);
          _hasMore = uniquePosts.isNotEmpty;
          _loading = false;
        });
      } else if (uniquePosts.isEmpty) {
        setState(() {
          _hasMore = false;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _currentPage = page;
          _posts.addAll(uniquePosts);
          _loadingMore = false;
        });
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '=== [NGA] DOM thread fetch FAILED tid=${widget.tid} page=$page ===',
        );
        debugPrint(e.toString());
        debugPrint(st.toString());
      }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    final displayTitle = widget.title ?? _topicTitle;

    return Scaffold(
      backgroundColor: colors.postBackground,
      appBar: AppBar(
        backgroundColor: colors.postBackground,
        surfaceTintColor: colors.postBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new),
          color: colors.textPrimary,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(
          displayTitle.isNotEmpty ? displayTitle : 'Post Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshThread,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Center(child: Text('No posts found.'));
    }

    return RefreshIndicator(
      onRefresh: _refreshThread,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (!_scrollController.hasClients) {
            return false;
          }
          final position = _scrollController.position;
          if (!position.hasContentDimensions ||
              position.maxScrollExtent <= 0 ||
              position.pixels <= 0) {
            return false;
          }
          if (position.pixels >= position.maxScrollExtent - 200) {
            _fetchMoreThread();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _posts.length + 1,
          itemBuilder: (context, index) {
            if (index >= _posts.length) {
              return _buildLoadMoreFooter(context);
            }
            final post = _posts[index];
            return _PostCard(post: post);
          },
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter(BuildContext context) {
    final colors = context.ngaColors;
    if (_posts.isEmpty) {
      return const SizedBox.shrink();
    }
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

    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadMoreError!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _fetchMoreThread,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('没有更多了', style: TextStyle(color: colors.textMuted)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text('上拉加载更多', style: TextStyle(color: colors.textMuted)),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    final author = post.author;
    final authorName = author.nickname.isNotEmpty
        ? author.nickname
        : 'UID ${author.uid}';
    final floorLabel = '#${post.floor}';
    final replyTime = post.replyTime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.postBackgroundSecondary,
                child: Icon(Icons.person, color: colors.textMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$floorLabel  $replyTime',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (post.deviceType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.postBackgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.deviceType,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Quote block (if present)
          if (post.quote != null) _QuoteCard(quote: post.quote!),

          // Content
          if (post.content.isNotEmpty)
            Text(
              post.content,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            )
          else
            Text(
              '内容为空',
              style: TextStyle(color: colors.textMuted),
            ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final PostQuote quote;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    final headerText = 'by ${quote.quotedUser}'
        '${quote.quotedTime.isNotEmpty ? ' (${quote.quotedTime})' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.quoteBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colors.divider, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.postBackgroundSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'R',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headerText,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          if (quote.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              quote.content,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
