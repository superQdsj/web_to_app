import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/nga_rich_repository.dart';
import '../src/auth/nga_cookie_store.dart';
import '../src/model/thread_rich_detail.dart';
import '../src/parser/thread_rich_quote_resolver.dart';
import '../src/services/emoji_service.dart';
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
  final Map<int, String> _rawHtmlByPage = {};

  String get _cookie => NgaCookieStore.cookie.value;

  @override
  void initState() {
    super.initState();
    _repository = NgaRichRepository(cookie: _cookie);
    NgaCookieStore.cookie.addListener(_onCookieChanged);
    _loadEmojiMap();
    _refreshThread();
  }

  Future<void> _loadEmojiMap() async {
    if (EmojiService.isLoaded) {
      return;
    }
    try {
      await EmojiService.ensureLoaded();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // Ignore emoji loading errors; fallback to placeholder.
    }
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
      _rawHtmlByPage.clear();
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
      debugPrint(
        '=== [NGA] Fetch rich thread cookie len=${_cookie.length} ===',
      );
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
      final resolvedUniquePosts = ThreadRichQuoteResolver.resolve(uniquePosts);
      _rawHtmlByPage[page] = detail.rawHtmlText;

      if (page <= 1) {
        setState(() {
          _posts
            ..clear()
            ..addAll(resolvedUniquePosts);
          _hasMore = resolvedUniquePosts.isNotEmpty;
          _loading = false;
        });
      } else if (uniquePosts.isEmpty) {
        setState(() {
          _hasMore = false;
          _loadingMore = false;
        });
      } else {
        final mergedPosts = <ThreadRichPost>[..._posts, ...resolvedUniquePosts];
        final resolvedMergedPosts = ThreadRichQuoteResolver.resolve(
          mergedPosts,
        );
        setState(() {
          _currentPage = page;
          _posts
            ..clear()
            ..addAll(resolvedMergedPosts);
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

  Future<void> _dumpThreadRawHtml() async {
    final mergedHtmlText = _mergeThreadRawHtml();
    if (mergedHtmlText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No raw HTML to save.')));
      return;
    }

    try {
      final dumpDir = await _resolveDumpDirectory();
      final filePath = '${dumpDir.path}/${_buildThreadDumpFileName()}';
      final file = File(filePath);
      await file.writeAsString(mergedHtmlText, flush: true);
      debugPrint('=== [NGA] Saved raw thread html: $filePath ===');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved: $filePath')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _dumpPostContent(ThreadRichPost post) async {
    if (post.rawContent.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No raw content to save.')));
      return;
    }

    try {
      final dumpDir = await _resolveDumpDirectory();
      final filePath = '${dumpDir.path}/${_buildDumpFileName(post)}';
      final file = File(filePath);
      await file.writeAsString(post.rawContent, flush: true);
      if (kDebugMode || Platform.isIOS) {
        debugPrint('=== [NGA] Saved raw post html: $filePath ===');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved: $filePath')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<Directory> _resolveDumpDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Saving is not supported on web.');
    }

    Directory baseDir;
    if (Platform.isAndroid) {
      baseDir =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final dumpDir = Directory('${baseDir.path}/nga_dump');
    if (!await dumpDir.exists()) {
      await dumpDir.create(recursive: true);
    }
    return dumpDir;
  }

  String _buildDumpFileName(ThreadRichPost post) {
    final pid = post.pid?.toString() ?? 'unknown';
    final floor = post.floor?.toString() ?? 'x';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'tid_${widget.tid}_pid_${pid}_floor_${floor}_$stamp.html';
  }

  String _buildThreadDumpFileName() {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final pages = _rawHtmlByPage.keys.toList()..sort();
    final pageLabel = pages.isEmpty ? _currentPage : pages.last;
    return 'tid_${widget.tid}_pages_1_${pageLabel}_$stamp.html';
  }

  String _mergeThreadRawHtml() {
    if (_rawHtmlByPage.isEmpty) {
      return '';
    }
    final pages = _rawHtmlByPage.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final page in pages) {
      final htmlText = _rawHtmlByPage[page]?.trim() ?? '';
      if (htmlText.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln('\n<!-- NGA page $page -->\n');
      }
      buffer.writeln(htmlText);
    }
    return buffer.toString();
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
        actions: [
          IconButton(
            onPressed: _dumpThreadRawHtml,
            icon: const Icon(Icons.save_alt),
            color: colors.textPrimary,
            tooltip: '保存原始HTML',
          ),
        ],
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
            return _PostCard(
              post: post,
              onLongPress: () => _dumpPostContent(post),
            );
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
  const _PostCard({required this.post, this.onLongPress});

  final ThreadRichPost post;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    final author = post.author;
    final avatarUrl = author?.avatar;
    final authorName = author?.username ?? 'UID ${post.authorUid ?? '-'}';
    final floorLabel = post.floor != null ? '#${post.floor}' : '楼层';
    final postDate = post.postDate ?? '';

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
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
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
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
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
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
      return Text('内容为空', style: TextStyle(color: colors.textMuted));
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
      return _QuoteBlock(blocks: block.blocks, header: block.header);
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
    final baseStyle = TextStyle(
      color: colors.textPrimary,
      fontSize: 15,
      height: 1.4,
    );
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: _buildInlineSpans(context, spans, baseStyle: baseStyle),
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.blocks, this.header});

  final List<ThreadContentBlock> blocks;
  final ThreadQuoteHeader? header;

  @override
  Widget build(BuildContext context) {
    final colors = context.ngaColors;
    final hasHeader = header != null;
    final hasContent = blocks.isNotEmpty;
    final headerText = header == null
        ? ''
        : 'by ${header!.authorName}'
              '${header!.postTime != null ? ' (${header!.postTime})' : ''}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.quoteBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colors.divider, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader)
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
                    header!.label,
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
          if (hasHeader && hasContent) const SizedBox(height: 6),
          if (hasContent)
            _QuoteContent(
              blocks: blocks,
              textStyle: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuoteContent extends StatelessWidget {
  const _QuoteContent({required this.blocks, required this.textStyle});

  final List<ThreadContentBlock> blocks;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          _buildQuoteBlock(context, block),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildQuoteBlock(BuildContext context, ThreadContentBlock block) {
    if (block is ThreadParagraphBlock) {
      return RichText(
        text: TextSpan(
          style: textStyle,
          children: _buildInlineSpans(
            context,
            block.spans,
            baseStyle: textStyle,
          ),
        ),
      );
    }
    if (block is ThreadImageBlock) {
      return _ImageBlock(url: block.url);
    }
    if (block is ThreadQuoteBlock) {
      return _QuoteBlock(blocks: block.blocks, header: block.header);
    }
    return const SizedBox.shrink();
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
  {required TextStyle baseStyle,}
) {
  final spans = <InlineSpan>[];
  for (final node in nodes) {
    if (node is ThreadTextNode) {
      spans.addAll(_buildTextNodeSpans(context, node, baseStyle: baseStyle));
    } else if (node is ThreadEmoteNode) {
      spans.add(_buildEmojiSpan(context, node.code, baseStyle: baseStyle));
    }
  }
  return spans;
}

final RegExp _inlineTokenPattern = RegExp(
  r'\[url(?:=[^\]]+)?\].*?\[/url\]|\[s:[^\]]+\]',
  caseSensitive: false,
  dotAll: true,
);

final RegExp _urlTagPattern = RegExp(
  r'^\[url(?:=([^\]]+))?\](.*?)\[/url\]$',
  caseSensitive: false,
  dotAll: true,
);

List<InlineSpan> _buildTextNodeSpans(
  BuildContext context,
  ThreadTextNode node, {
  required TextStyle baseStyle,
}) {
  final spans = <InlineSpan>[];
  final text = node.text;

  final nodeStyle = TextStyle(
    fontWeight: node.bold ? FontWeight.w600 : FontWeight.normal,
    decoration: node.deleted ? TextDecoration.lineThrough : null,
  );

  void flush(String chunk) {
    if (chunk.isEmpty) return;
    spans.add(TextSpan(text: chunk, style: nodeStyle));
  }

  var cursor = 0;
  for (final match in _inlineTokenPattern.allMatches(text)) {
    if (match.start > cursor) {
      flush(text.substring(cursor, match.start));
    }

    final token = match.group(0) ?? '';
    if (token.isEmpty) {
      cursor = match.end;
      continue;
    }

    final lower = token.toLowerCase();
    if (lower.startsWith('[s:')) {
      spans.add(_buildEmojiSpan(context, token, baseStyle: baseStyle));
      cursor = match.end;
      continue;
    }

    if (lower.startsWith('[url')) {
      final urlMatch = _urlTagPattern.firstMatch(token);
      if (urlMatch == null) {
        flush(token);
        cursor = match.end;
        continue;
      }

      final attrUrl = (urlMatch.group(1) ?? '').trim();
      final innerText = (urlMatch.group(2) ?? '').trim();
      final href = (attrUrl.isNotEmpty ? attrUrl : innerText).trim();
      final label = innerText.isNotEmpty ? innerText : href;

      if (href.isEmpty) {
        flush(token);
        cursor = match.end;
        continue;
      }

      spans.add(
        _buildLinkSpan(
          context,
          label: label,
          href: href,
          baseStyle: baseStyle,
          bold: node.bold,
          deleted: node.deleted,
        ),
      );
      cursor = match.end;
      continue;
    }

    flush(token);
    cursor = match.end;
  }

  if (cursor < text.length) {
    flush(text.substring(cursor));
  }
  return spans;
}

InlineSpan _buildLinkSpan(
  BuildContext context, {
  required String label,
  required String href,
  required TextStyle baseStyle,
  required bool bold,
  required bool deleted,
}) {
  final colors = context.ngaColors;
  final normalized = _normalizeExternalUrl(href);

  final decoration = deleted
      ? TextDecoration.combine(
          const [TextDecoration.lineThrough, TextDecoration.underline],
        )
      : TextDecoration.underline;

  final linkStyle = baseStyle.copyWith(
    color: colors.link,
    fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
    decoration: decoration,
  );

  return WidgetSpan(
    alignment: PlaceholderAlignment.baseline,
    baseline: TextBaseline.alphabetic,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: normalized == null
          ? null
          : () => _launchExternalUrl(context, normalized),
      child: Text(label, style: linkStyle),
    ),
  );
}

InlineSpan _buildEmojiSpan(
  BuildContext context,
  String code, {
  required TextStyle baseStyle,
}) {
  final colors = context.ngaColors;
  final baseFontSize = baseStyle.fontSize ?? 14;
  final size = (baseFontSize + 3).clamp(16.0, 20.0);

  final url = EmojiService.resolve(code);
  if (url == null) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.postBackgroundSecondary,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border),
        ),
        child: Icon(Icons.tag_faces, size: size * 0.66, color: colors.textMuted),
      ),
    );
  }

  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (context, _) => Container(
          color: colors.postBackgroundSecondary,
        ),
        errorWidget: (context, _, _) => Container(
          color: colors.postBackgroundSecondary,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image,
            size: size * 0.66,
            color: colors.textMuted,
          ),
        ),
      ),
    ),
  );
}

String? _normalizeExternalUrl(String input) {
  var trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('//')) {
    trimmed = 'https:$trimmed';
  }
  var uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (!uri.hasScheme) {
    trimmed = 'https://$trimmed';
    uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
  }
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return null;
  }
  return uri.toString();
}

Future<void> _launchExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Invalid url: $url')));
    return;
  }

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Open failed: $url')));
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Open failed: $e')));
  }
}
