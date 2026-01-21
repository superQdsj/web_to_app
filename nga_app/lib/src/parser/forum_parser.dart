import 'package:html/parser.dart' as html_parser;

import '../model/thread_item.dart';
import '../util/url_utils.dart';

class ForumParser {
  List<ThreadItem> parseForumThreadList(String htmlText) {
    final doc = html_parser.parse(htmlText);

    final rows = doc.querySelectorAll('#topicrows tr.topicrow');
    final items = <ThreadItem>[];

    for (final row in rows) {
      final topicLink = row.querySelector('a.topic');
      if (topicLink == null) continue;

      final href = topicLink.attributes['href'];
      if (href == null || href.trim().isEmpty) continue;

      final tid = extractTidFromReadHref(href);
      if (tid == null) continue;

      final title = topicLink.text.trim();

      final repliesText = row.querySelector('a.replies')?.text;
      final replies = tryParseInt(repliesText);

      final authorLink = row.querySelector('a.author');
      final author = authorLink?.text.trim();
      final authorUid = extractUidFromHref(
        authorLink?.attributes['href'] ?? '',
      );

      final postTs = tryParseInt(row.querySelector('span.postdate')?.text);
      final lastReplyer = row.querySelector('span.replyer')?.text.trim();

      final url = resolveNgaUrl(href).toString();

      items.add(
        ThreadItem(
          tid: tid,
          url: url,
          title: title,
          replies: replies,
          author: author,
          authorUid: authorUid,
          postTs: postTs,
          lastReplyer: lastReplyer,
        ),
      );
    }

    return items;
  }
}
