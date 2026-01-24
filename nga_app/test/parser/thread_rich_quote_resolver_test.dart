import 'package:flutter_test/flutter_test.dart';
import 'package:nga_app/src/model/thread_rich_detail.dart';
import 'package:nga_app/src/parser/thread_rich_content_parser.dart';
import 'package:nga_app/src/parser/thread_rich_quote_resolver.dart';

void main() {
  test('resolve() should fill reply quote blocks across pages', () {
    const quotedPid = 855709967;
    const replyPid = 855734773;

    // This is the referenced post (on an earlier page). It contains a reply
    // header and some text.
    const quotedRaw =
        "[b]Reply to [pid=855709696,46057007,1]Reply[/pid] Post by [uid=63774238]素衣染白裳[/uid] (2026-01-24 15:30)[/b]<br/><br/>"
        "？？？以前wa不也是每个导入么？除非你是连了10个同职业同专精";

    // This is the later post that references the quotedPid but is parsed on a
    // different page, so the quote body starts empty.
    const replyRaw =
        "[b]Reply to [pid=855709967,46057007,1]Reply[/pid] Post by [uid=43257161]黑铁武僧真香[/uid] (2026-01-24 15:33)[/b]<br/>"
        "WA是不是可以不换角色导入所有，回答我";

    final contentParser = ThreadRichContentParser();
    final quotedPost = ThreadRichPost(
      pid: quotedPid,
      floor: 5,
      author: null,
      authorUid: null,
      contentBlocks: contentParser.parse(quotedRaw),
      rawContent: quotedRaw,
    );
    final replyPost = ThreadRichPost(
      pid: replyPid,
      floor: 48,
      author: null,
      authorUid: null,
      contentBlocks: contentParser.parse(replyRaw),
      rawContent: replyRaw,
    );

    final unresolved = ThreadRichQuoteResolver.resolve([replyPost]);
    final unresolvedQuote =
        unresolved.first.contentBlocks.first as ThreadQuoteBlock;
    expect(unresolvedQuote.header?.pid, quotedPid);
    expect(unresolvedQuote.blocks, isEmpty);

    final resolved = ThreadRichQuoteResolver.resolve([quotedPost, replyPost]);
    final resolvedReply = resolved.last;
    final resolvedQuote = resolvedReply.contentBlocks.first as ThreadQuoteBlock;

    expect(resolvedQuote.blocks, isNotEmpty);
    final firstPara = resolvedQuote.blocks
        .whereType<ThreadParagraphBlock>()
        .first;
    final text = firstPara.spans
        .whereType<ThreadTextNode>()
        .map((e) => e.text)
        .join();
    expect(text, contains('以前wa不也是每个导入么'));

    final replyText = (resolvedReply.contentBlocks.last as ThreadParagraphBlock)
        .spans
        .whereType<ThreadTextNode>()
        .map((e) => e.text)
        .join();
    expect(replyText, contains('WA是不是可以不换角色导入所有'));
  });

  test('resolve() should replace broken quote content with source post', () {
    const quotedPid = 855709724;
    const quotingPid = 855716805;

    const quotedRaw =
        '使用方法：<br/>'
        '1.下载Cooldown Manager Centered(技能监控美化)和SenseiClassResourceBar(个人资源条美化)两个插件<br/><br/>'
        '2.[url]https://www.luxthos.com/interface-addon-profiles/ [/url] '
        '复制Edit Mode己的分辨率的导入到编辑模式，然后分别复制Cooldown Manager Centered和SenseiClassResourceBar两个字符串导入到对应插件<br/><br/>'
        '3.[url]https://www.luxthos.com/cooldown-manager-profiles-world-of-warcraft-midnight/[/url] '
        '找到你自己的职业，复制导入到高级冷却设置里。';

    // Simulates NGA quoting bug: the 3rd url tag is truncated and unbalanced.
    const quotingRaw =
        '[quote][pid=855709724,46057007,1]Reply[/pid] '
        '[b]Post by [uid=38895291]无敌帅气的我[/uid] (2026-01-24 15:30):[/b]<br/><br/>'
        '使用方法：<br/>'
        '1.下载Cooldown Manager Centered(技能监控美化)和SenseiClassResourceBar(个人资源条美化)两个插件<br/><br/>'
        '2.[url]https://www.luxthos.com/interface-addon-profiles/ [/url] '
        '复制Edit Mode己的分辨率的导入到编辑模式，然后分别复制Cooldown Manager Centered和SenseiClassResourceBar两个字符串导入到对应插件<br/><br/>'
        '3.[url]https[/quote]<br/><br/>'
        '这么麻烦吗？算鸟算鸟....';

    final contentParser = ThreadRichContentParser();
    final quotedPost = ThreadRichPost(
      pid: quotedPid,
      floor: 2,
      author: null,
      authorUid: null,
      contentBlocks: contentParser.parse(quotedRaw),
      rawContent: quotedRaw,
    );
    final quotingPost = ThreadRichPost(
      pid: quotingPid,
      floor: 29,
      author: null,
      authorUid: null,
      contentBlocks: contentParser.parse(quotingRaw),
      rawContent: quotingRaw,
    );

    final resolved = ThreadRichQuoteResolver.resolve([quotedPost, quotingPost]);
    final resolvedQuotingPost = resolved.last;
    final quote = resolvedQuotingPost.contentBlocks.first as ThreadQuoteBlock;

    final quoteText = (quote.blocks.whereType<ThreadParagraphBlock>())
        .expand((b) => b.spans)
        .whereType<ThreadTextNode>()
        .map((e) => e.text)
        .join();
    expect(quoteText, contains('cooldown-manager-profiles-world-of-warcraft'));
  });
}
