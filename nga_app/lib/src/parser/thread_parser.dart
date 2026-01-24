import 'dart:convert';
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
    // Attempt hybrid parsing first
    try {
      return parseHybrid(htmlText, tid: tid, url: url, fetchedAt: fetchedAt);
    } catch (e) {
      // Fallback to legacy DOM parser if hybrid fails (basic content only)
      return _parseLegacy(htmlText, tid: tid, url: url, fetchedAt: fetchedAt);
    }
  }

  /// New hybrid parser using Regex + JSON + DOM
  ThreadDetail parseHybrid(
    String htmlText, {
    required int tid,
    required String url,
    required int fetchedAt,
  }) {
    // 1. Extract metadata via Regex
    final userInfoMap = _extractUserInfo(htmlText);

    final groupsMap =
        userInfoMap['__GROUPS'] as Map<String, dynamic>? ??
        _extractGroups(htmlText);

    final doc = html_parser.parse(htmlText);

    // 2. Identify all posts (table.postbox or .postrow)
    final postRows = doc.querySelectorAll('table.forumbox.postbox');
    final posts = <ThreadPost>[];

    for (var i = 0; i < postRows.length; i++) {
      final row = postRows[i];
      final authorEl = row.querySelector('[id^=postauthor]');
      final contentEl =
          row.querySelector('[id^=postcontent]') ??
          row.querySelector('.postcontent.ubbcode') ??
          row.querySelector('.postcontent');
      final floor =
          (contentEl != null ? _tryExtractFloor(contentEl) : null) ??
          (authorEl != null ? _tryExtractFloor(authorEl) : null) ??
          i;
      final pid = _extractPidFromPostRow(row);

      // Extract UID from author link href
      final authorUidStr =
          authorEl?.attributes['href']?.split('uid=').last ?? '';
      final authorUid = int.tryParse(authorUidStr);

      // Extract content
      final contentText = contentEl?.text.trim() ?? '';
      if (contentText.isEmpty && authorUid == null) continue;

      // Extract device and other info from postArg.proc script following the table
      final deviceType = _extractDeviceType(htmlText, floor);

      // Map author metadata
      ThreadPostAuthor? author;
      if (authorUid != null && userInfoMap.containsKey(authorUid.toString())) {
        final userData =
            userInfoMap[authorUid.toString()] as Map<String, dynamic>;
        author = _mapToThreadPostAuthor(userData, groupsMap);
      }

      // Extract post date (reply time)
      final postDateEl = row.querySelector('[id^=postdate]');
      final postDate = postDateEl?.text.trim();

      // 解析引用信息
      final quoteResult = parseQuote(contentText);

      posts.add(
        ThreadPost(
          pid: pid,
          floor: floor,
          author: author,
          authorUid: authorUid,
          contentText: contentText,
          deviceType: deviceType,
          postDate: postDate,
          quotedPost: quoteResult.quotedPost,
          replyContent: quoteResult.replyContent,
        ),
      );
    }

    return ThreadDetail(tid: tid, url: url, fetchedAt: fetchedAt, posts: posts);
  }

  ThreadDetail _parseLegacy(
    String htmlText, {
    required int tid,
    required String url,
    required int fetchedAt,
  }) {
    final doc = html_parser.parse(htmlText);
    final preferred = doc.querySelectorAll('.postcontent.ubbcode');
    final candidates = preferred.isNotEmpty
        ? preferred
        : doc.querySelectorAll('.postcontent');

    final posts = <ThreadPost>[];
    for (final el in candidates) {
      final contentText = el.text.trim();
      if (contentText.isEmpty) continue;

      final floor = _tryExtractFloor(el);
      final table = _findClosestTable(el);
      final pid = table != null ? _extractPidFromPostRow(table) : null;
      Element? authorLink;
      if (floor != null) {
        authorLink = doc.getElementById('postauthor$floor');
      }

      final authorUid = extractUidFromHref(
        authorLink?.attributes['href'] ?? '',
      );

      // In legacy parser, try to find postdate
      final postDate = table?.querySelector('[id^=postdate]')?.text.trim();

      // 解析引用信息
      final quoteResult = parseQuote(contentText);

      posts.add(
        ThreadPost(
          pid: pid,
          floor: floor,
          author: null, // Legacy parser doesn't have rich author info
          authorUid: authorUid,
          contentText: contentText,
          postDate: postDate,
          quotedPost: quoteResult.quotedPost,
          replyContent: quoteResult.replyContent,
        ),
      );
    }

    return ThreadDetail(tid: tid, url: url, fetchedAt: fetchedAt, posts: posts);
  }

  Map<String, dynamic> _extractUserInfo(String html) {
    // commonui.userInfo.setAll( { ... } )
    // Use the markers if available, otherwise fallback to greedy match within the function call
    final match =
        RegExp(
          r'commonui\.userInfo\.setAll\(\s*({.*})\s*\)\s*;?\s*//userinfoend',
          dotAll: true,
        ).firstMatch(html) ??
        RegExp(
          r'commonui\.userInfo\.setAll\(\s*({.*})\s*\)',
          dotAll: true,
        ).firstMatch(html);

    if (match != null) {
      final jsonStr = _cleanJson(match.group(1)!);
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        // Ignore parsing errors and fall back to empty user info.
      }
    }
    return {};
  }

  Map<String, dynamic> _extractGroups(String html) {
    // "__GROUPS": { ... }
    final match = RegExp(
      r'"__GROUPS"\s*:\s*({.*?})\s*[,}]',
      dotAll: true,
    ).firstMatch(html);
    if (match != null) {
      final jsonStr = _cleanJson(match.group(1)!);
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {};
  }

  String? _extractDeviceType(String html, int floorIndex) {
    // commonui.postArg.proc( floorIndex, ..., 'deviceType', ...)
    // Look for the specific call for this floor
    // pattern: commonui.postArg.proc( floorIndex, ... , 'DEVICE_STR', ... )
    // This is complex because the arguments are many. Let's try to find the script block after the table.
    final floorPattern = RegExp(
      'commonui\\.postArg\\.proc\\(\\s*$floorIndex,.*?(\'[^\']+\')\\s*,\\s*\'\',\\s*null,\\s*0\\s*\\)',
      dotAll: true,
    );
    final match = floorPattern.firstMatch(html);
    if (match != null) {
      // The device string is often the 4th to last argument
      // Let's use a simpler approach: extract the whole call and split
      final call = match.group(0)!;
      final parts = call.split(',');
      if (parts.length > 20) {
        final devicePart = parts[parts.length - 4].trim().replaceAll("'", "");
        return devicePart.isNotEmpty ? devicePart : null;
      }
    }
    return null;
  }

  ThreadPostAuthor _mapToThreadPostAuthor(
    Map<String, dynamic> data,
    Map<String, dynamic> groups,
  ) {
    final memberId = data['memberid']?.toString();
    final groupData = groups[memberId] as Map<String, dynamic>?;
    final groupName = groupData?['0'] as String?;

    WowCharacter? wowChar;
    final remarkMap = data['remark'] as Map<String, dynamic>?;
    if (remarkMap != null && remarkMap.isNotEmpty) {
      // extract the first WOW character if available
      final firstKey = remarkMap.keys.first;
      final charStr = remarkMap[firstKey]?['4'] as String?;
      if (charStr != null) {
        wowChar = _parseWowCharacter(charStr);
      }
    }

    return ThreadPostAuthor(
      uid: data['uid'] as int,
      username: data['username'] as String,
      regdate: data['regdate'] as int,
      postnum: data['postnum'] as int,
      rvrc: (data['rvrc'] as num?)?.toDouble() ?? 0.0,
      money: data['money'] as int? ?? 0,
      avatar: data['avatar'] as String?,
      medal: data['medal']?.toString(),
      reputation: data['reputation']?.toString(),
      honor: data['honor']?.toString(),
      signature: data['signature'] as String?,
      nickname: data['nickname'] as String? ?? groupName,
      wowCharacter: wowChar,
    );
  }

  WowCharacter? _parseWowCharacter(String remarkStr) {
    // Tabs separated string: sv	wow_mainline	rl	Realm	re	realm-slug	ch	Name	rc	Race	cl	Class	fa	Faction	tl	Title	av	AchivPoints	it	ItemLevel	mh	...	gd	Gender	ci	ClassId
    final parts = remarkStr.split('\t');
    final map = <String, String>{};
    for (var i = 0; i + 1 < parts.length; i += 2) {
      map[parts[i].trim()] = parts[i + 1].trim();
    }
    if (map.isEmpty) return null;

    return WowCharacter(
      name: map['ch'] ?? 'Unknown',
      realm: map['rl'] ?? 'Unknown',
      race: map['rc'] ?? 'Unknown',
      characterClass: map['cl'] ?? 'Unknown',
      faction: map['fa'] ?? 'Unknown',
      level: 0,
      itemLevel: int.tryParse(map['it'] ?? '0') ?? 0,
      achievementPoints: int.tryParse(map['av'] ?? '0') ?? 0,
      gender: map['gd'] ?? 'Unknown',
      classId: map['ci'] ?? '',
    );
  }

  String _cleanJson(String jsContent) {
    // Escape literal tabs and newlines within strings for valid JSON
    var cleaned = jsContent.replaceAll('\t', r'\t');
    // Remove trailing commas in objects/arrays
    cleaned = cleaned.replaceAll(RegExp(r',\s*([\]}])'), r'$1');
    return cleaned;
  }

  int? _tryExtractFloor(Element el) {
    final id = el.id;
    if (id.isEmpty) return null;
    final m = RegExp(r'(\d+)$').firstMatch(id);
    if (m != null) {
      return int.tryParse(m.group(1) ?? '');
    }
    return null;
  }

  int? _extractPidFromPostRow(Element row) {
    final idMatch = RegExp(r'pid(\d+)');
    final hrefMatch = RegExp(r'pid=(\d+)');
    final hashMatch = RegExp(r'#pid(\d+)');

    final rowId = row.id;
    if (rowId.isNotEmpty) {
      final m = idMatch.firstMatch(rowId);
      if (m != null) {
        return int.tryParse(m.group(1)!);
      }
    }

    final rowName = row.attributes['name'];
    if (rowName != null) {
      final m = idMatch.firstMatch(rowName);
      if (m != null) {
        return int.tryParse(m.group(1)!);
      }
    }

    for (final el in row.querySelectorAll('[id], [name]')) {
      final candidateId = el.id;
      if (candidateId.isNotEmpty) {
        final m = idMatch.firstMatch(candidateId);
        if (m != null) {
          return int.tryParse(m.group(1)!);
        }
      }
      final candidateName = el.attributes['name'];
      if (candidateName != null) {
        final m = idMatch.firstMatch(candidateName);
        if (m != null) {
          return int.tryParse(m.group(1)!);
        }
      }
    }

    for (final link in row.querySelectorAll('a')) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) {
        continue;
      }
      final m = hrefMatch.firstMatch(href);
      if (m != null) {
        return int.tryParse(m.group(1)!);
      }
      final m2 = hashMatch.firstMatch(href);
      if (m2 != null) {
        return int.tryParse(m2.group(1)!);
      }
    }
    return null;
  }

  Element? _findClosestTable(Element start) {
    Element? current = start;
    while (current != null) {
      if (current.localName == 'table') {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  /// 后处理：对于格式2的引用（quotedText为空），根据PID从已解析的帖子中查找原文
  ///
  /// 格式2 ([b]Reply to...[/b]) 不包含被引用的文本，需要从同页面的帖子中查找
  static List<ThreadPost> fillQuotedTextFromPosts(List<ThreadPost> posts) {
    // 构建 PID -> 帖子内容 的映射
    final pidToContent = <int, String>{};
    for (final post in posts) {
      if (post.pid != null) {
        // 使用 replyContent（如果有）或 contentText，去掉引用部分
        final content = post.replyContent ?? post.contentText;
        pidToContent[post.pid!] = content;
      }
    }

    // 遍历帖子，填充空的 quotedText
    return posts.map((post) {
      final quoted = post.quotedPost;
      // 如果有引用但 quotedText 为空，尝试从 PID 映射中查找
      if (quoted != null &&
          quoted.quotedText.isEmpty &&
          quoted.pid != null &&
          pidToContent.containsKey(quoted.pid)) {
        final originalContent = pidToContent[quoted.pid]!;
        return ThreadPost(
          pid: post.pid,
          floor: post.floor,
          author: post.author,
          authorUid: post.authorUid,
          contentText: post.contentText,
          deviceType: post.deviceType,
          postDate: post.postDate,
          quotedPost: QuotedPost(
            pid: quoted.pid,
            tid: quoted.tid,
            authorUid: quoted.authorUid,
            authorName: quoted.authorName,
            postTime: quoted.postTime,
            quotedText: originalContent,
          ),
          replyContent: post.replyContent,
        );
      }
      return post;
    }).toList();
  }

  /// 解析帖子内容中的引用信息
  ///
  /// 支持格式：
  /// 1. [quote][pid=xxx,tid,page]Reply[/pid] [b]Post by [uid=xxx]Username[/uid] (time):[/b]引用内容[/quote]回复内容
  /// 2. [quote][tid=xxx]Topic[/tid] [b]Post by [uid=xxx]Username[/uid] (time):[/b]引用内容[/quote]回复内容
  /// 3. [b]Reply to [pid=xxx,tid,page]Reply[/pid] Post by [uid=xxx]Username[/uid] (time)[/b]回复内容
  /// 4. [b]Reply to [pid=xxx,tid,page]Reply[/pid] Post by [uid=xxx]Username[/uid] (time)回复内容[/b]
  static ({QuotedPost? quotedPost, String? replyContent}) parseQuote(
    String contentText,
  ) {
    final trimmedText = contentText.trimLeft();
    // 格式1: [quote]...[/quote] 完整引用块
    final quotePattern = RegExp(
      r'\[quote\]'
      r'\[pid=(\d+),(\d+),(\d+)\]Reply\[/pid\]\s*'
      r'\[b\]Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\):\[/b\]'
      r'(.*?)'
      r'\[/quote\]'
      r'(.*)',
      dotAll: true,
    );

    var match = quotePattern.firstMatch(trimmedText);
    if (match != null) {
      final pid = int.tryParse(match.group(1) ?? '');
      final tid = int.tryParse(match.group(2) ?? '');
      final authorUid = int.tryParse(match.group(4) ?? '');
      final authorName = match.group(5)?.trim();
      final postTime = match.group(6)?.trim();
      final quotedText = match.group(7)?.trim() ?? '';
      final replyContent = match.group(8)?.trim() ?? '';

      return (
        quotedPost: QuotedPost(
          pid: pid,
          tid: tid,
          authorUid: authorUid,
          authorName: authorName,
          postTime: postTime,
          quotedText: quotedText,
        ),
        replyContent: replyContent.isNotEmpty ? replyContent : null,
      );
    }

    // 格式2: [quote][tid=xxx]Topic[/tid] ...
    final quoteTopicPattern = RegExp(
      r'\[quote\]'
      r'\[tid=(\d+)\]Topic\[/tid\]\s*'
      r'\[b\]Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\):\[/b\]'
      r'(.*?)'
      r'\[/quote\]'
      r'(.*)',
      dotAll: true,
    );

    match = quoteTopicPattern.firstMatch(trimmedText);
    if (match != null) {
      final tid = int.tryParse(match.group(1) ?? '');
      final authorUid = int.tryParse(match.group(2) ?? '');
      final authorName = match.group(3)?.trim();
      final postTime = match.group(4)?.trim();
      final quotedText = match.group(5)?.trim() ?? '';
      final replyContent = match.group(6)?.trim() ?? '';

      return (
        quotedPost: QuotedPost(
          pid: null,
          tid: tid,
          authorUid: authorUid,
          authorName: authorName,
          postTime: postTime,
          quotedText: quotedText,
        ),
        replyContent: replyContent.isNotEmpty ? replyContent : null,
      );
    }

    // 格式3/4: [b]Reply to ...[/b] 简短引用格式
    final replyToPattern = RegExp(
      r'^\[b\]Reply to \[pid=(\d+),(\d+),(\d+)\]Reply\[/pid\]\s*'
      r'Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\)',
      dotAll: true,
    );

    match = replyToPattern.firstMatch(trimmedText);
    if (match != null) {
      final pid = int.tryParse(match.group(1) ?? '');
      final tid = int.tryParse(match.group(2) ?? '');
      final authorUid = int.tryParse(match.group(4) ?? '');
      final authorName = match.group(5)?.trim();
      final postTime = match.group(6)?.trim();

      var replyContent = trimmedText.substring(match.end).trim();
      replyContent = replyContent.replaceFirst(RegExp(r'^\s*\[/b\]\s*'), '');
      replyContent = replyContent.replaceFirst(RegExp(r'\s*\[/b\]\s*$'), '');

      return (
        quotedPost: QuotedPost(
          pid: pid,
          tid: tid,
          authorUid: authorUid,
          authorName: authorName,
          postTime: postTime,
          quotedText: '', // Reply to 格式没有引用内容
        ),
        replyContent: replyContent.isNotEmpty ? replyContent : null,
      );
    }

    // 没有引用
    return (quotedPost: null, replyContent: null);
  }
}
