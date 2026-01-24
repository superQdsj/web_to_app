import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/nga_rich_repository.dart';
import '../src/auth/nga_cookie_store.dart';
import '../src/model/thread_rich_detail.dart';
import '../theme/app_colors.dart';

class ThreadRichScreen extends StatefulWidget {
  const ThreadRichScreen({super.key, required this.tid, this.title});

  final int tid;
  final String? title;

  @override
  State<ThreadRichScreen> createState() => _ThreadRichScreenState();
}

class _ThreadRichScreenState extends State<ThreadRichScreen> {
  final _posts = <ThreadRichPost>[];
  final _postKeys = <String>{};
  final _scrollController = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _loadMoreError;

  int _currentPage = 1;
  late NgaRichRepository _repository;

  String get _cookie => NgaCookieStore.cookie.value;

  @override
  void initState() {
    super.initState();
    _repository = NgaRichRepository(cookie: _cookie);
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
    _repository = NgaRichRepository(cookie: _cookie);
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
      debugPrint('=== [NGA] Fetch rich thread cookie len=${_cookie.length} ===');
      debugPrint(
        '=== [NGA] Fetch rich thread cookie cookies: '
        '${NgaCookieStore.summarizeCookieHeader(_cookie)} ===',
      );
    }

    try {
      final detail = await _repository.fetchThread(widget.tid, page: page);
      final uniquePosts = detail.posts
          .where((post) => _postKeys.add(_threadPostKey(post)))
          .toList(growable: false);

      if (page <= 1) {
        setState(() {
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
        final mergedPosts = <ThreadRichPost>[..._posts, ...uniquePosts];
        setState(() {
          _currentPage = page;
          _posts
            ..clear()
            ..addAll(mergedPosts);
          _loadingMore = false;
        });
      }
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

  String _threadPostKey(ThreadRichPost post) {
    final pid = post.pid;
    if (pid != null) {
      return 'pid:$pid';
    }
    final normalized = post.rawContent.trim();
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
    final colors = context.ngaColors;
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
          widget.title ?? 'Post Details',
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
            return _PostCard(post: _posts[index]);
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
          child: Text(
            '没有更多了',
            style: TextStyle(color: colors.textMuted),
          ),
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

  final ThreadRichPost post;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    final author = post.author;
    final avatarUrl = author?.avatar;
    final authorName = author?.username ?? 'UID ${post.authorUid ?? '-'}';
    final floorLabel = post.floor != null ? '#${post.floor}' : '楼层';
    final postDate = post.postDate ?? '';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.postBackgroundSecondary,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, color: colors.textMuted)
                    : null,
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
                      '$floorLabel  $postDate',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.deviceType != null && post.deviceType!.isNotEmpty)
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
                    post.deviceType!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _PostContent(blocks: post.contentBlocks),
        ],
      ),
    );
  }
}

class _PostContent extends StatelessWidget {
  const _PostContent({required this.blocks});

  final List<ThreadContentBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    if (blocks.isEmpty) {
      return Text(
        '内容为空',
        style: TextStyle(color: colors.textMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          _buildBlock(context, block),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildBlock(BuildContext context, ThreadContentBlock block) {
    if (block is ThreadImageBlock) {
      return _ImageBlock(url: block.url);
    }
    if (block is ThreadQuoteBlock) {
      return _QuoteBlock(spans: block.spans);
    }
    if (block is ThreadParagraphBlock) {
      return _ParagraphBlock(spans: block.spans);
    }
    return const SizedBox.shrink();
  }
}

class _ParagraphBlock extends StatelessWidget {
  const _ParagraphBlock({required this.spans});

  final List<ThreadInlineNode> spans;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          height: 1.4,
        ),
        children: _buildInlineSpans(context, spans),
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.spans});

  final List<ThreadInlineNode> spans;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.quoteBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colors.divider, width: 3)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            height: 1.35,
          ),
          children: _buildInlineSpans(context, spans),
        ),
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, _) => Container(
            color: colors.postBackgroundSecondary,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, _, _) => Container(
            color: colors.postBackgroundSecondary,
            alignment: Alignment.center,
            child: Icon(Icons.broken_image, color: colors.textMuted),
          ),
        ),
      ),
    );
  }
}

List<InlineSpan> _buildInlineSpans(
  BuildContext context,
  List<ThreadInlineNode> nodes,
) {
  final colors = context.ngaColors;
  final spans = <InlineSpan>[];
  for (final node in nodes) {
    if (node is ThreadTextNode) {
      spans.add(
        TextSpan(
          text: node.text,
          style: TextStyle(
            fontWeight: node.bold ? FontWeight.w600 : FontWeight.normal,
            decoration: node.deleted ? TextDecoration.lineThrough : null,
          ),
        ),
      );
    } else if (node is ThreadEmoteNode) {
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.postBackgroundSecondary,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.tag_faces, size: 12, color: colors.textMuted),
          ),
        ),
      );
    }
  }
  return spans;
}
