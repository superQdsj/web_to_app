import 'package:html/parser.dart' as html_parser;

import '../model/thread_rich_detail.dart';

class ThreadRichContentParser {
  List<ThreadContentBlock> parse(String rawHtml) {
    final normalized = _normalizeHtml(rawHtml);
    final blocks = <ThreadContentBlock>[];

    final quotePattern = RegExp(r'\[quote\](.*?)\[/quote\]', dotAll: true);
    var cursor = 0;
    for (final match in quotePattern.allMatches(normalized)) {
      final before = normalized.substring(cursor, match.start);
      _appendTextBlocks(before, blocks);

      final quoteText = match.group(1) ?? '';
      final cleaned = _stripMetaTags(quoteText);
      final spans = _parseInline(cleaned);
      if (spans.isNotEmpty) {
        blocks.add(ThreadQuoteBlock(spans: spans));
      }
      cursor = match.end;
    }
    final tail = normalized.substring(cursor);
    _appendTextBlocks(tail, blocks);
    return blocks;
  }

  void _appendTextBlocks(String text, List<ThreadContentBlock> blocks) {
    if (text.trim().isEmpty) return;
    final cleaned = _stripMetaTags(text);

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

  String _stripMetaTags(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'\[pid=[^\]]+\](.*?)\[/pid\]'), r'$1')
        .replaceAll(RegExp(r'\[tid=[^\]]+\](.*?)\[/tid\]'), r'$1')
        .replaceAll(RegExp(r'\[uid=[^\]]+\](.*?)\[/uid\]'), r'$1');
    return cleaned;
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
