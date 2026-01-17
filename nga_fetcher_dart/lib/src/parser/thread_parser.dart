import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../model/thread_detail.dart';
import '../util/url_utils.dart';

class ThreadParser {
  /// Parses a thread page HTML (first page only).
  ///
  /// MVP goals:
  /// - extract a list of post bodies as `content_text`
  /// - author name may be unavailable in raw HTML (often populated by JS)
  ThreadDetail parseThreadPage(
    String htmlText, {
    required int tid,
    required String url,
    required int fetchedAt,
  }) {
    final doc = html_parser.parse(htmlText);

    // NGA post bodies are usually `#postcontent{index}` with class `postcontent ubbcode`.
    // Note: post authors in the raw HTML are often empty strings and filled by JS.
    final preferred = doc.querySelectorAll('.postcontent.ubbcode');
    final candidates = preferred.isNotEmpty
        ? preferred
        : doc.querySelectorAll('.postcontent');

    final posts = <ThreadPost>[];
    for (final el in candidates) {
      final contentText = _extractContentText(el);
      if (contentText.isEmpty) continue;

      final floor = _tryExtractFloor(el);

      Element? authorLink;
      if (floor != null) {
        authorLink = doc.getElementById('postauthor$floor');
      }

      final authorName = authorLink?.text.trim();
      final author = (authorName == null || authorName.isEmpty) ? null : authorName;
      final authorUid = extractUidFromHref(authorLink?.attributes['href'] ?? '');

      posts.add(
        ThreadPost(
          floor: floor,
          author: author,
          authorUid: authorUid,
          contentText: contentText,
        ),
      );
    }

    return ThreadDetail(tid: tid, url: url, fetchedAt: fetchedAt, posts: posts);
  }

  String _extractContentText(Element el) {
    final text = el.text;
    return text.trim();
  }

  int? _tryExtractFloor(Element el) {
    final id = el.id;
    if (id.isEmpty) return null;

    // Common patterns: postcontent0, postcontent_0, etc.
    final m = RegExp(r'(\d+)$').firstMatch(id);
    if (m != null) {
      return int.tryParse(m.group(1) ?? '');
    }
    return null;
  }
}
