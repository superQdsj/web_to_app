import 'package:flutter/material.dart';
import '../src/nga_fetcher.dart';

import '../config/nga_env.dart';
import '../data/nga_repository.dart';
import '../main.dart' as main_app;
import '../ui/nga_ui.dart';
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
  int _fid = 7;
  final _threads = <ThreadItem>[];

  bool _loading = false;
  String? _error;

  late final NgaRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = main_app.NgaApp.repository;
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _fetchThreads() async {
    final fid = _fid;

    if (!NgaEnv.hasCookie) {
      setState(() {
        _error = 'Cookie not configured.\n'
            'Run with: --dart-define-from-file=../private/nga_cookie.json';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _threads.clear();
    });

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('General Discussion', style: Theme.of(context).textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => showStubSnackBar(context, 'Search: TODO'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () async {
              final fid = await showFidPickerDialog(context, initialFid: _fid);
              if (!mounted) return;
              if (fid == null) return;
              if (fid <= 0) {
                setState(() => _error = 'Invalid fid: $fid');
                return;
              }
              setState(() => _fid = fid);
              await _fetchThreads();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showStubSnackBar(context, 'Compose: TODO'),
        backgroundColor: scheme.primary,
        child: const Icon(Icons.edit_rounded),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.background,
              scheme.background.withOpacity(0.94),
              scheme.background,
            ],
            stops: const [0, 0.4, 1],
          ),
        ),
        child: Column(
          children: [
            if (_error != null) _buildErrorBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: NgaCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _error!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.error, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: NgaCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No threads loaded',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the top-right button to enter a forum fid, then load the list.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final fid = await showFidPickerDialog(
                            context,
                            initialFid: _fid,
                          );
                          if (!mounted) return;
                          if (fid == null) return;
                          if (fid <= 0) {
                            setState(() => _error = 'Invalid fid: $fid');
                            return;
                          }
                          setState(() => _fid = fid);
                          await _fetchThreads();
                        },
                        child: const Text('Load a forum'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchThreads,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        itemCount: _threads.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final thread = _threads[index];
          return _ThreadTile(
            thread: thread,
            pinned: index == 0,
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
    required this.pinned,
  });

  final ThreadItem thread;
  final VoidCallback onTap;
  final bool pinned;

  String _relativeTimeLabel(int? unixSeconds) {
    if (unixSeconds == null || unixSeconds <= 0) return 'recent';
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final author = thread.author ?? 'Unknown';
    final replyCount = thread.replies ?? 0;
    final time = _relativeTimeLabel(thread.postTs);

    return NgaCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NgaRadii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NgaAvatar(seed: author, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'by $author  -  $time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$replyCount',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 12),
                        if (pinned)
                          Chip(
                            label: const Text('Pinned'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: scheme.surfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
