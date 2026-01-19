import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/nga_fetcher.dart';

import '../data/nga_repository.dart';
import '../src/auth/nga_cookie_store.dart';
import 'thread_screen.dart';

/// Forum thread list screen.
///
/// Allows user to input a forum ID (fid) and fetch the thread list.
class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _fidController = TextEditingController(text: '7');
  final _threads = <ThreadItem>[];

  bool _loading = false;
  String? _error;

  late NgaRepository _repository;

  String get _cookie => NgaCookieStore.cookie.value;

  @override
  void initState() {
    super.initState();
    _repository = NgaRepository(cookie: _cookie);
    NgaCookieStore.cookie.addListener(_onCookieChanged);
  }

  void _onCookieChanged() {
    // Recreate repository so subsequent fetches use the latest cookie.
    _repository.close();
    _repository = NgaRepository(cookie: _cookie);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    NgaCookieStore.cookie.removeListener(_onCookieChanged);
    _fidController.dispose();
    _repository.close();
    super.dispose();
  }

  Future<void> _fetchThreads() async {
    final fidText = _fidController.text.trim();
    final fid = int.tryParse(fidText);

    if (fid == null) {
      setState(() => _error = 'Invalid fid: $fidText');
      return;
    }

    if (!NgaCookieStore.hasCookie) {
      setState(() {
        _error = 'Cookie not configured.\n'
            '请到「个人」页完成登录。';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _threads.clear();
    });

    if (kDebugMode) {
      debugPrint('=== [NGA] Fetch forum cookie len=${_cookie.length} ===');
      debugPrint(
        '=== [NGA] Fetch forum cookie cookies: '
        '${NgaCookieStore.summarizeCookieHeader(_cookie)} ===',
      );
    }

    try {
      final threads = await _repository.fetchForumThreads(fid);

      setState(() {
        _threads.addAll(threads);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGA Forum'),
      ),
      body: Column(
        children: [
          _buildInputBar(),
          if (_error != null) _buildErrorBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text('fid: '),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _fidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _loading ? null : _fetchThreads,
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Load'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.all(12),
      child: Text(
        _error!,
        style: TextStyle(color: Colors.red.shade900),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threads.isEmpty) {
      return const Center(
        child: Text('Enter fid and tap Load to fetch threads.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchThreads,
      child: ListView.separated(
        itemCount: _threads.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return _ThreadTile(
            thread: thread,
            onTap: () => _openThread(thread),
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.onTap,
  });

  final ThreadItem thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        thread.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${thread.author ?? 'Unknown'} | Replies: ${thread.replies ?? 0}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
