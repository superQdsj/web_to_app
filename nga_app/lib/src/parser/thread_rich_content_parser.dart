import 'package:html/parser.dart' as html_parser;

import '../model/thread_rich_detail.dart';

class ThreadRichContentParser {
  List<ThreadContentBlock> parse(String rawHtml) {
    return _parseBlocks(rawHtml);
  }

  List<ThreadContentBlock> _parseBlocks(
    String rawHtml, {
    bool allowReplyHeader = true,
  }) {
    final normalized = _normalizeHtml(rawHtml);
    final blocks = <ThreadContentBlock>[];

    const openTag = '[quote]';
    const closeTag = '[/quote]';
    var cursor = 0;
    while (true) {
      final start = normalized.indexOf(openTag, cursor);
      if (start == -1) break;
      final before = normalized.substring(cursor, start);
      _appendTextBlocks(before, blocks, allowReplyHeader: allowReplyHeader);

      final end = _findMatchingQuoteEnd(normalized, start + openTag.length);
      if (end == null) {
        _appendTextBlocks(
          normalized.substring(start),
          blocks,
          allowReplyHeader: allowReplyHeader,
        );
        cursor = normalized.length;
        break;
      }

      final quoteText = normalized.substring(start + openTag.length, end);
      final parsedQuote = _parseQuoteContent(quoteText);
      final quoteBlocks = _parseBlocks(
        parsedQuote.body,
        allowReplyHeader: false,
      );
      if (quoteBlocks.isNotEmpty || parsedQuote.header != null) {
        blocks.add(
          ThreadQuoteBlock(
            blocks: quoteBlocks,
            header: parsedQuote.header,
          ),
        );
      }
      cursor = end + closeTag.length;
    }
    final tail = normalized.substring(cursor);
    _appendTextBlocks(tail, blocks, allowReplyHeader: allowReplyHeader);
    return blocks;
  }

  void _appendTextBlocks(
    String text,
    List<ThreadContentBlock> blocks, {
    bool allowReplyHeader = true,
  }) {
    if (text.trim().isEmpty) return;
    var working = text;
    if (allowReplyHeader) {
      final replyParsed = _parseReplyHeader(working);
      if (replyParsed != null) {
        blocks.add(
          ThreadQuoteBlock(
            blocks: const [],
            header: replyParsed.header,
          ),
        );
        working = replyParsed.remaining;
        if (working.trim().isEmpty) return;
      }
    }
    final cleaned = _stripMetaTags(working);

    final imagePattern = RegExp(
      r'\[(img|attachimg)(?:=[^\]]+)?\](.*?)\[/\1\]',
      dotAll: true,
    );

    var cursor = 0;
    for (final match in imagePattern.allMatches(cleaned)) {
      final before = cleaned.substring(cursor, match.start);
      _appendParagraphs(before, blocks);

      final url = _resolveImageUrl(match.group(2) ?? '');
      if (url.isNotEmpty) {
        blocks.add(ThreadImageBlock(url: url));
      }
      cursor = match.end;
    }
    final tail = cleaned.substring(cursor);
    _appendParagraphs(tail, blocks);
  }

  void _appendParagraphs(String text, List<ThreadContentBlock> blocks) {
    final parts = text.split(RegExp(r'\n{2,}'));
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final spans = _parseInline(trimmed);
      if (spans.isNotEmpty) {
        blocks.add(ThreadParagraphBlock(spans: spans));
      }
    }
  }

  String _normalizeHtml(String html) {
    var normalized = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
        .replaceAll('\u00A0', ' ');

    final fragmentText = html_parser.parseFragment(normalized).text ?? '';
    normalized = fragmentText;
    return normalized.trim();
  }

  int? _findMatchingQuoteEnd(String text, int startIndex) {
    const openTag = '[quote]';
    const closeTag = '[/quote]';
    var depth = 1;
    var cursor = startIndex;
    while (cursor < text.length) {
      final nextOpen = text.indexOf(openTag, cursor);
      final nextClose = text.indexOf(closeTag, cursor);
      if (nextClose == -1) return null;
      if (nextOpen != -1 && nextOpen < nextClose) {
        depth += 1;
        cursor = nextOpen + openTag.length;
        continue;
      }
      depth -= 1;
      if (depth == 0) return nextClose;
      cursor = nextClose + closeTag.length;
    }
    return null;
  }

  String _stripMetaTags(String text) {
    var cleaned = text;
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[pid=[^\]]+\](.*?)\[/pid\]'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[tid=[^\]]+\](.*?)\[/tid\]'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[uid=[^\]]+\](.*?)\[/uid\]'),
      (match) => match.group(1) ?? '',
    );
    return cleaned;
  }

  ({ThreadQuoteHeader header, String remaining})? _parseReplyHeader(
    String text,
  ) {
    final trimmed = text.trimLeft();
    final replyToPattern = RegExp(
      r'^\[b\]Reply to \[pid=(\d+),(\d+),(\d+)\]Reply\[/pid\]\s*'
      r'Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\)',
      dotAll: true,
    );
    final match = replyToPattern.firstMatch(trimmed);
    if (match == null) return null;

    final pid = int.tryParse(match.group(1) ?? '');
    final tid = int.tryParse(match.group(2) ?? '');
    final authorUid = int.tryParse(match.group(4) ?? '');
    final authorName = match.group(5)?.trim();
    final postTime = match.group(6)?.trim();
    var remaining = trimmed.substring(match.end);
    remaining = remaining.replaceFirst(RegExp(r'^\s*\[/b\]\s*'), '');
    remaining = remaining.replaceFirst(RegExp(r'\s*\[/b\]\s*$'), '');
    remaining = remaining.trimLeft();

    return (
      header: ThreadQuoteHeader(
        authorName: authorName?.isNotEmpty == true ? authorName! : 'Unknown',
        pid: pid,
        tid: tid,
        authorUid: authorUid,
        postTime: postTime?.isNotEmpty == true ? postTime : null,
      ),
      remaining: remaining,
    );
  }

  ({ThreadQuoteHeader? header, String body}) _parseQuoteContent(String text) {
    final trimmed = text.trim();
    final quotePattern = RegExp(
      r'^\[pid=(\d+),(\d+),(\d+)\]Reply\[/pid\]\s*'
      r'\[b\]Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\):\[/b\]'
      r'(.*)$',
      dotAll: true,
    );
    final topicPattern = RegExp(
      r'^\[tid=(\d+)\]Topic\[/tid\]\s*'
      r'\[b\]Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\):\[/b\]'
      r'(.*)$',
      dotAll: true,
    );

    var match = quotePattern.firstMatch(trimmed);
    if (match != null) {
      final pid = int.tryParse(match.group(1) ?? '');
      final tid = int.tryParse(match.group(2) ?? '');
      final authorUid = int.tryParse(match.group(4) ?? '');
      final authorName = match.group(5)?.trim();
      final postTime = match.group(6)?.trim();
      final body = match.group(7)?.trim() ?? '';
      return (
        header: ThreadQuoteHeader(
          authorName: authorName?.isNotEmpty == true ? authorName! : 'Unknown',
          pid: pid,
          tid: tid,
          authorUid: authorUid,
          postTime: postTime?.isNotEmpty == true ? postTime : null,
        ),
        body: body,
      );
    }

    match = topicPattern.firstMatch(trimmed);
    if (match != null) {
      final tid = int.tryParse(match.group(1) ?? '');
      final authorUid = int.tryParse(match.group(2) ?? '');
      final authorName = match.group(3)?.trim();
      final postTime = match.group(4)?.trim();
      final body = match.group(5)?.trim() ?? '';
      return (
        header: ThreadQuoteHeader(
          authorName: authorName?.isNotEmpty == true ? authorName! : 'Unknown',
          tid: tid,
          authorUid: authorUid,
          postTime: postTime?.isNotEmpty == true ? postTime : null,
        ),
        body: body,
      );
    }

    return (header: null, body: trimmed);
  }

  String _resolveImageUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    if (trimmed.startsWith('./')) {
      return 'https://img.nga.178.com/attachments/${trimmed.substring(2)}';
    }
    return 'https://img.nga.178.com/attachments/$trimmed';
  }

  List<ThreadInlineNode> _parseInline(String text) {
    final nodes = <ThreadInlineNode>[];
    final tokenPattern = RegExp(r'\[/?b\]|\[/?del\]|\[s:[^\]]+\]');
    var cursor = 0;
    var bold = false;
    var deleted = false;

    void flush(String chunk) {
      if (chunk.isEmpty) return;
      nodes.add(
        ThreadTextNode(text: chunk, bold: bold, deleted: deleted),
      );
    }

    for (final match in tokenPattern.allMatches(text)) {
      if (match.start > cursor) {
        flush(text.substring(cursor, match.start));
      }

      final token = match.group(0) ?? '';
      switch (token) {
        case '[b]':
          bold = true;
          break;
        case '[/b]':
          bold = false;
          break;
        case '[del]':
          deleted = true;
          break;
        case '[/del]':
          deleted = false;
          break;
        default:
          if (token.startsWith('[s:')) {
            nodes.add(ThreadEmoteNode(code: token));
          } else {
            flush(token);
          }
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      flush(text.substring(cursor));
    }
    return nodes;
  }
}
