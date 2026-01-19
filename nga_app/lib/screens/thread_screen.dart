import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/nga_fetcher.dart';

import '../data/nga_repository.dart';
import '../src/auth/nga_cookie_store.dart';

class _ThreadPalette {
  const _ThreadPalette._();

  static const Color backgroundLight = Color(0xFFFFF0CF);
  static const Color surfaceLight = Color(0xFFFFF7E9);
  static const Color borderLight = Color(0xFFEAE0C8);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF5C4D32);
  static const Color primary = Color(0xFF1337EC);
}

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
      debugPrint('=== [NGA] Fetch thread cookie len=${_cookie.length} ===');
      debugPrint(
        '=== [NGA] Fetch thread cookie cookies: '
        '${NgaCookieStore.summarizeCookieHeader(_cookie)} ===',
      );
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
      body: _buildBody(),
      bottomNavigationBar: const _ReplyComposer(),
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

    final mainPost = posts.first;
    final replies = posts.length > 1 ? posts.sublist(1) : <ThreadPost>[];
    final hotReplies = replies.take(2).toList();

    return RefreshIndicator(
      onRefresh: _fetchThread,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _MainPostHeader(post: mainPost),
          const SizedBox(height: 8),
          const _PostActionsRow(),
          const SizedBox(height: 12),
          const Divider(
            height: 1,
            thickness: 1,
            color: _ThreadPalette.borderLight,
          ),
          if (hotReplies.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionHeader(
              icon: Icons.local_fire_department,
              title: 'Hot Replies',
              iconColor: Colors.red,
            ),
            const SizedBox(height: 12),
            ...hotReplies.map(
              (post) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ReplyCard(post: post),
              ),
            ),
          ],
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(
              height: 1,
              thickness: 1,
              color: _ThreadPalette.borderLight,
            ),
            const SizedBox(height: 8),
            _SectionHeader(
              title: 'All Replies (${replies.length})',
            ),
            const SizedBox(height: 4),
            ...replies.map(
              (post) => _ReplyTile(post: post),
            ),
          ],
          if (replies.isEmpty) ...[
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No replies yet.',
                style: TextStyle(color: _ThreadPalette.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MainPostHeader extends StatelessWidget {
  const _MainPostHeader({
    required this.post,
  });

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final authorLabel = post.author?.username ?? 'Anonymous';
    final timeLabel = post.floor != null ? '#${post.floor}' : 'Just now';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAvatar(
            name: authorLabel,
            avatarUrl: post.author?.avatar,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        authorLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _ThreadPalette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _ThreadPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.contentText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: _ThreadPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActionsRow extends StatelessWidget {
  const _PostActionsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: const [
          _ActionPill(
            icon: Icons.arrow_upward,
            label: '1.2k',
            foreground: _ThreadPalette.primary,
            background: Color(0x1A1337EC),
          ),
          _ActionPill(
            icon: Icons.arrow_downward,
            label: '15',
            foreground: _ThreadPalette.textSecondary,
            background: _ThreadPalette.surfaceLight,
          ),
          _ActionPill(
            icon: Icons.bookmark_border,
            label: '234',
            foreground: _ThreadPalette.textSecondary,
            background: _ThreadPalette.surfaceLight,
          ),
          _ActionPill(
            icon: Icons.share_outlined,
            label: '89',
            foreground: _ThreadPalette.textSecondary,
            background: _ThreadPalette.surfaceLight,
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.icon,
    this.iconColor,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _ThreadPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.post,
  });

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final authorLabel = post.author?.username ?? 'Anonymous';
    final timeLabel = post.floor != null ? '#${post.floor}' : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ThreadPalette.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(
                name: authorLabel,
                avatarUrl: post.author?.avatar,
                size: 32,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            authorLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _ThreadPalette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _ThreadPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.contentText,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: _ThreadPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _ReplyActionsRow(
            alignEnd: true,
          ),
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    required this.post,
  });

  final ThreadPost post;

  @override
  Widget build(BuildContext context) {
    final authorLabel = post.author?.username ?? 'Anonymous';
    final timeLabel = post.floor != null ? '#${post.floor}' : 'Just now';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAvatar(
            name: authorLabel,
            avatarUrl: post.author?.avatar,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        authorLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _ThreadPalette.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _ThreadPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  post.contentText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: _ThreadPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const _ReplyActionsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyActionsRow extends StatelessWidget {
  const _ReplyActionsRow({
    this.alignEnd = false,
  });

  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _InlineAction(icon: Icons.thumb_up_outlined, label: '98'),
        SizedBox(width: 16),
        _InlineAction(icon: Icons.thumb_down_outlined, label: '2'),
        SizedBox(width: 16),
        _InlineAction(icon: Icons.reply, label: 'Reply', showLabel: false),
      ],
    );

    if (!alignEnd) {
      return content;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [content],
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _ThreadPalette.textSecondary),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: _ThreadPalette.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    required this.size,
    this.avatarUrl,
  });

  final String name;
  final double size;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final fallbackLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final imageProvider = (avatarUrl?.isNotEmpty ?? false)
        ? NetworkImage(avatarUrl!)
        : null;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _ThreadPalette.surfaceLight,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              fallbackLetter,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _ThreadPalette.textSecondary,
              ),
            )
          : null,
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: _ThreadPalette.backgroundLight,
          border: Border(
            top: BorderSide(color: _ThreadPalette.borderLight),
          ),
        ),
        child: Row(
          children: [
            const _UserAvatar(name: 'You', size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Add a reply...',
                  hintStyle: const TextStyle(
                    color: _ThreadPalette.textSecondary,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: _ThreadPalette.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  color: _ThreadPalette.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: _ThreadPalette.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.send, size: 18),
                color: Colors.white,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
