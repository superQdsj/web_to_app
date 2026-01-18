import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/nga_fetcher.dart';

import '../data/nga_repository.dart';
import '../src/auth/nga_cookie_store.dart';

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
  ThreadDetail? _detail;
  bool _loading = true;
  String? _error;

  late NgaRepository _repository;

  String get _cookie => NgaCookieStore.cookie.value;

  @override
  void initState() {
    super.initState();
    _repository = NgaRepository(cookie: _cookie);
    NgaCookieStore.cookie.addListener(_onCookieChanged);
    _fetchThread();
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
    _repository.close();
    super.dispose();
  }

  Future<void> _fetchThread() async {
    if (!NgaCookieStore.hasCookie) {
      setState(() {
        _error = 'Cookie not configured.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    if (kDebugMode) {
      debugPrint('=== [NGA] Fetch thread using cookie (full) ===');
      debugPrint(_cookie);
      debugPrint('=== [NGA] Fetch thread cookie len=${_cookie.length} ===');
    }

    try {
      final detail = await _repository.fetchThread(widget.tid);

      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Thread #${widget.tid}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
                onPressed: _fetchThread,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final posts = _detail?.posts ?? [];

    if (posts.isEmpty) {
      return const Center(child: Text('No posts found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchThread,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final post = posts[index];
          return _PostTile(post: post, index: index);
        },
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.post,
    required this.index,
  });

  final ThreadPost post;
  final int index;

  @override
  Widget build(BuildContext context) {
    final floorLabel = post.floor != null ? '#${post.floor}' : '#${index + 1}';
    final authorLabel = post.author ?? 'Anonymous';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                floorLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  authorLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            post.contentText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
