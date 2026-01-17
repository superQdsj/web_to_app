import 'package:flutter/material.dart';
import '../src/nga_fetcher.dart';

import '../config/nga_env.dart';
import '../data/nga_repository.dart';
import '../main.dart' as main_app;
import '../ui/nga_ui.dart';

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
  static const int kHotRepliesCount = 2;

  ThreadDetail? _detail;
  bool _loading = true;
  String? _error;

  late final NgaRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = main_app.NgaApp.repository;
    _fetchThread();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _fetchThread() async {
    if (!NgaEnv.hasCookie) {
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
          'Post Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () => showStubSnackBar(context, 'More: TODO'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildReplyBar(),
    );
  }

  Widget _buildBody() {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: NgaCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _fetchThread,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final posts = _detail?.posts ?? [];

    if (posts.isEmpty) {
      return const Center(child: Text('No posts found.'));
    }

    final mainPost = posts.first;
    final replies = posts.length > 1 ? posts.sublist(1) : const <ThreadPost>[];
    final hotReplies = replies.take(kHotRepliesCount).toList();
    final otherReplies = replies.skip(kHotRepliesCount).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.background,
            scheme.background.withOpacity(0.92),
            scheme.background,
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _fetchThread,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
            _MainPostCard(post: mainPost),
            const SizedBox(height: 14),
            _ActionRow(),
            const SizedBox(height: 18),
            if (hotReplies.isNotEmpty) ...[
              Text(
                'Hot Replies',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              for (final p in hotReplies) ...[
                _ReplyCard(post: p, dense: false),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
            ],
            Text(
              'All Replies (${replies.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            if (otherReplies.isEmpty && replies.isNotEmpty)
              for (final p in replies) ...[
                _ReplyCard(post: p, dense: true),
                const SizedBox(height: 10),
              ]
            else
              for (final p in otherReplies) ...[
                _ReplyCard(post: p, dense: true),
                const SizedBox(height: 10),
              ],
            if (replies.isEmpty)
              NgaCard(
                child: Text(
                  'No replies yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: scheme.background.withOpacity(0.92),
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  'Add a reply...',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
                boxShadow: NgaShadows.soft(scheme),
              ),
              child: IconButton(
                onPressed: () => showStubSnackBar(context, 'Reply: TODO'),
                icon: Icon(Icons.send_rounded, color: scheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainPostCard extends StatelessWidget {
  const _MainPostCard({required this.post});

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final author = post.author ?? 'AuthorUsername';

    return NgaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NgaAvatar(seed: author, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRelativeTime(_detail?.fetchedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_horiz_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            post.contentText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          NgaPill(
            icon: Icons.arrow_upward_rounded,
            label: '1.2k',
            emphasis: true,
            onTap: () => showStubSnackBar(context, 'Upvote: TODO'),
          ),
          const SizedBox(width: 10),
          NgaPill(
            icon: Icons.arrow_downward_rounded,
            label: '15',
            onTap: () => showStubSnackBar(context, 'Downvote: TODO'),
          ),
          const SizedBox(width: 10),
          NgaPill(
            icon: Icons.bookmark_border_rounded,
            label: '234',
            onTap: () => showStubSnackBar(context, 'Bookmark: TODO'),
          ),
          const SizedBox(width: 10),
          NgaPill(
            icon: Icons.share_rounded,
            label: '89',
            onTap: () => showStubSnackBar(context, 'Share: TODO'),
          ),
        ],
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.post,
    required this.dense,
  });

  final ThreadPost post;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final author = post.author ?? (dense ? 'CommenterX' : 'ReplyUsername1');

    return NgaCard(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: dense ? 12 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NgaAvatar(seed: author, size: dense ? 36 : 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRelativeTime(_detail?.fetchedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              if (!dense)
                Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined,
                        size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      dense ? '67' : '98',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            post.contentText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.thumb_up_alt_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                dense ? '42' : '98',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.reply_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Reply',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
