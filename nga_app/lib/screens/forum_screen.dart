import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/nga_fetcher.dart';

import '../data/nga_repository.dart';
import '../src/auth/nga_cookie_store.dart';
import '../src/nga_forum_store.dart';
import 'thread_screen.dart';

/// Forum content widget (embeddable).
///
/// Displays forum thread list. Allows user to input a forum ID (fid)
/// and fetch the thread list. Designed to be embedded within a Scaffold.
class ForumContent extends StatefulWidget {
  const ForumContent({super.key});

  @override
  State<ForumContent> createState() => _ForumContentState();
}

class _ForumContentState extends State<ForumContent> {
  final _threads = <ThreadItem>[];
  final _threadIds = <int>{};
  final _scrollController = ScrollController();

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  int? _activeFid;
  int _currentPage = 1;

  late NgaRepository _repository;

  String get _cookie => NgaCookieStore.cookie.value;

  @override
  void initState() {
    super.initState();
    _repository = NgaRepository(cookie: _cookie);
    NgaCookieStore.cookie.addListener(_onCookieChanged);
    NgaForumStore.activeFid.addListener(_onFidChanged);

    // Initial fetch if we have cookie
    if (NgaCookieStore.hasCookie) {
      _fetchThreads();
    }
  }

  void _onCookieChanged() {
    // Recreate repository so subsequent fetches use the latest cookie.
    _repository.close();
    _repository = NgaRepository(cookie: _cookie);
    if (mounted) {
      setState(() {});
      // 如果已选中版块，登录后自动重新加载数据
      if (NgaForumStore.activeFid.value != null && NgaCookieStore.hasCookie) {
        _fetchThreads();
      }
    }
  }

  void _onFidChanged() {
    _fetchThreads();
  }

  @override
  void dispose() {
    NgaCookieStore.cookie.removeListener(_onCookieChanged);
    NgaForumStore.activeFid.removeListener(_onFidChanged);
    _scrollController.dispose();
    _repository.close();
    super.dispose();
  }

  Future<void> _fetchThreads() async {
    final fid = NgaForumStore.activeFid.value;
    if (fid == null) {
      setState(() {
        _threads.clear();
        _threadIds.clear();
        _activeFid = null;
        _hasMore = false;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
      return;
    }

    if (!NgaCookieStore.hasCookie) {
      setState(() {
        _error =
            'Cookie not configured.\n'
            '请点击右上角头像完成登录。';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _threads.clear();
      _threadIds.clear();
      _activeFid = fid;
      _currentPage = 1;
      _hasMore = true;
    });

    if (kDebugMode) {
      debugPrint('=== [NGA] Fetch forum cookie len=${_cookie.length} ===');
      debugPrint(
        '=== [NGA] Fetch forum cookie cookies: '
        '${NgaCookieStore.summarizeCookieHeader(_cookie)} ===',
      );
    }

    try {
      final threads = await _repository.fetchForumThreads(fid, page: 1);
      final uniqueThreads = threads
          .where((t) => _threadIds.add(t.tid))
          .toList(growable: false);

      setState(() {
        _threads.addAll(uniqueThreads);
        _hasMore = uniqueThreads.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchMoreThreads() async {
    if (_loading || _loadingMore || !_hasMore) {
      return;
    }
    final fid = _activeFid;
    if (fid == null) {
      return;
    }

    setState(() {
      _loadingMore = true;
      _error = null;
    });

    try {
      final nextPage = _currentPage + 1;
      final threads = await _repository.fetchForumThreads(fid, page: nextPage);
      final uniqueThreads = threads
          .where((t) => _threadIds.add(t.tid))
          .toList(growable: false);

      setState(() {
        if (uniqueThreads.isEmpty) {
          _hasMore = false;
        } else {
          _currentPage = nextPage;
          _threads.addAll(uniqueThreads);
        }
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingMore = false;
      });
    }
  }

  void _openThread(ThreadItem thread) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ThreadScreen(tid: thread.tid, title: thread.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_error != null) _buildErrorBanner(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.all(12),
      child: Text(_error!, style: TextStyle(color: Colors.red.shade900)),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threads.isEmpty) {
      return const Center(child: Text('暂无内容，选择版块后会显示主题列表。'));
    }

    return RefreshIndicator(
      onRefresh: _fetchThreads,
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
          const loadMoreThreshold = 200.0;
          if (position.pixels >= position.maxScrollExtent - loadMoreThreshold) {
            _fetchMoreThreads();
          }
          return false;
        },
        child: ListView.separated(
          controller: _scrollController,
          itemCount: _threads.length + 1,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index >= _threads.length) {
              return _buildLoadMoreFooter();
            }
            final thread = _threads[index];
            return _ThreadTile(
              thread: thread,
              onTap: () => _openThread(thread),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    if (_threads.isEmpty) {
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

    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '没有更多了',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '上拉加载更多',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final ThreadItem thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(thread.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${thread.author ?? 'Unknown'} | Replies: ${thread.replies ?? 0}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
