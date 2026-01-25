import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart' as hp;

// Minimal models matching parse_nga_thread_optimized.dart JSON keys.
class ThreadData {
  const ThreadData({required this.topicTitle, required this.posts});

  final String topicTitle;
  final List<ThreadPost> posts;

  Map<String, dynamic> toJson() => {
        'topic_title': topicTitle,
        'posts': posts.map((p) => p.toJson()).toList(),
      };
}

class ThreadPost {
  const ThreadPost({
    required this.pid,
    required this.floor,
    required this.isTopicPost,
    required this.author,
    required this.content,
    required this.replyTime,
    required this.likeCount,
    required this.deviceType,
    this.quote,
    this.editedTime,
  });

  final int pid;
  final int floor;
  final bool isTopicPost;
  final PostAuthor author;
  final String content;
  final String replyTime;
  final int likeCount;
  final String deviceType;
  final PostQuote? quote;
  final String? editedTime;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'pid': pid,
      'floor': floor,
      'is_topic_post': isTopicPost,
      'author': author.toJson(),
      'content': content,
      'reply_time': replyTime,
      'like_count': likeCount,
      'device_type': deviceType,
    };
    if (quote != null) json['quote'] = quote!.toJson();
    if (editedTime != null) json['edited_time'] = editedTime;
    return json;
  }
}

class PostAuthor {
  const PostAuthor({
    required this.nickname,
    required this.uid,
    required this.level,
    required this.registrationDate,
  });

  final String nickname;
  final int uid;
  final String level;
  final String registrationDate;

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'uid': uid,
        'level': level,
        'registration_date': registrationDate,
      };
}

class PostQuote {
  const PostQuote({
    required this.quotedUser,
    required this.quotedTime,
    required this.content,
    this.quotedPid,
  });

  final String quotedUser;
  final String quotedTime;
  final String content;
  final int? quotedPid;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'quoted_user': quotedUser,
      'quoted_time': quotedTime,
      'content': content,
    };
    if (quotedPid != null) json['quoted_pid'] = quotedPid;
    return json;
  }
}

class PostArgInfo {
  const PostArgInfo({required this.likeCount, required this.deviceStr});

  final int likeCount;
  final String deviceStr;
}

class NgaThreadDomParser {
  static final RegExp _quoteRegex1 = RegExp(
    r'\[quote\].*?\[tid=\d+\]Topic\[/tid\]\s*\[b\]Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\):\[/b\]([\s\S]*?)\[/quote\]',
    caseSensitive: false,
  );
  static final RegExp _quoteRegex2 = RegExp(
    r'\[quote\]\[pid=([0-9]+)[^\]]*\]Reply\[/pid\]\s*\[b\]Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\):\[/b\]([\s\S]*?)\[/quote\]',
    caseSensitive: false,
  );
  static final RegExp _replyToRegex = RegExp(
    r'\[b\]Reply to \[pid=([0-9]+)[^\]]*\]Reply\[/pid\] Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\)\[/b\]',
    caseSensitive: false,
  );
  static final RegExp _replyToTopicRegex = RegExp(
    r'\[b\]Reply to \[tid=([0-9]+)\]Topic\[/tid\] Post by \[uid=(\d+)\]([^\[]+)\[/uid\]\s*\(([^)]+)\)\[/b\]',
    caseSensitive: false,
  );
  static final RegExp _quoteBlockRegex =
      RegExp(r'\[quote\][\s\S]*?\[/quote\]\s*', caseSensitive: false);
  static final RegExp _replyToHeaderRegex = RegExp(
    r'\[b\]Reply to \[pid=[^\]]+\]Reply\[/pid\] Post by \[uid=\d+\][^\[]+\[/uid\]\s*\([^)]+\)\[/b\]',
    caseSensitive: false,
  );
  static final RegExp _replyToTopicHeaderRegex = RegExp(
    r'\[b\]Reply to \[tid=[^\]]+\]Topic\[/tid\] Post by \[uid=\d+\][^\[]+\[/uid\]\s*\([^)]+\)\[/b\]',
    caseSensitive: false,
  );

  static final RegExp _ubbAcRegex = RegExp(r'\[s:ac:[^\]]+\]');
  static final RegExp _ubbPgRegex = RegExp(r'\[s:pg:[^\]]+\]');
  static final RegExp _ubbA2Regex = RegExp(r'\[s:a2:[^\]]+\]');
  static final RegExp _ubbImgRegex = RegExp(r'\[img\][^\[]*\[/img\]');
  static final RegExp _ubbUrlRegex = RegExp(r'\[url[^\]]*\][^\[]*\[/url\]');

  static final RegExp _htmlBrRegex = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final RegExp _htmlTagRegex = RegExp(r'<[^>]+>');
  static final RegExp _multiBlankRegex = RegExp(r'\n\s*\n+');
  static final RegExp _leadingWsRegex = RegExp(r'^\s+', multiLine: true);
  static final RegExp _controlCharsRegex =
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]');

  ThreadData parse(String rawHtml) {
    final doc = hp.parse(rawHtml);

    final topicTitle = doc.getElementById('currentTopicName')?.text.trim() ?? '';
    final userInfo = _extractUserInfo(rawHtml);
    final postArgInfoByFloor = _extractPostArgInfoByFloor(rawHtml);

    final posts = <ThreadPost>[];
    final pidToPostIndex = <int, int>{};

    for (final tr in doc.querySelectorAll('tr[id^="post1strow"]')) {
      final floorMatch = RegExp(r'^post1strow(\d+)$').firstMatch(tr.id);
      final floor = int.tryParse(floorMatch?.group(1) ?? '');
      if (floor == null) continue;

      final pidAnchor =
          tr.querySelector(r'a[id^="pid"][id$="Anchor"]')?.id ?? '';
      final pid = int.tryParse(pidAnchor.replaceAll(RegExp(r'[^0-9]'), ''));
      if (pid == null) continue;

      final uid = _extractUidFromHref(
            tr.querySelector('#postauthor$floor')?.attributes['href'],
          ) ??
          0;

      final authorInfo = userInfo[uid.toString()];
      final author = PostAuthor(
        nickname: authorInfo?['nickname']?.toString() ?? '',
        uid: authorInfo?['uid'] as int? ?? uid,
        level: authorInfo?['level']?.toString() ?? '',
        registrationDate: authorInfo?['registration_date']?.toString() ?? '',
      );

      final contentNode = doc.getElementById('postcontent$floor');
      final rawContent = _innerHtmlToText(contentNode?.innerHtml ?? '');

      final replyTime = doc.getElementById('postdate$floor')?.text.trim() ?? '';
      final editedTime = _extractEditedTime(rawHtml, floor);

      final postArgInfo = postArgInfoByFloor[floor];
      final likeCount = postArgInfo?.likeCount ?? 0;
      final deviceType = _parseDeviceType(postArgInfo?.deviceStr ?? '');

      final quote = _parseQuote(rawContent);
      final cleanContent = _cleanContent(rawContent);

      final post = ThreadPost(
        pid: pid,
        floor: floor,
        isTopicPost: floor == 0,
        author: author,
        content: cleanContent,
        replyTime: replyTime,
        likeCount: likeCount,
        deviceType: deviceType,
        quote: quote,
        editedTime: editedTime,
      );

      pidToPostIndex[pid] = posts.length;
      posts.add(post);
    }

    // Backfill quote.content for Reply-to headers when referenced post is in
    // this page.
    for (var i = 0; i < posts.length; i++) {
      final quote = posts[i].quote;
      final quotedPid = quote?.quotedPid;
      if (quote == null || quotedPid == null) continue;
      if (quote.content.isNotEmpty) continue;

      final referencedIndex = pidToPostIndex[quotedPid];
      if (referencedIndex == null) continue;

      final referenced = posts[referencedIndex];
      final backfilled = referenced.content;
      posts[i] = ThreadPost(
        pid: posts[i].pid,
        floor: posts[i].floor,
        isTopicPost: posts[i].isTopicPost,
        author: posts[i].author,
        content: posts[i].content,
        replyTime: posts[i].replyTime,
        likeCount: posts[i].likeCount,
        deviceType: posts[i].deviceType,
        editedTime: posts[i].editedTime,
        quote: PostQuote(
          quotedUser: quote.quotedUser,
          quotedTime: quote.quotedTime,
          content: backfilled,
          quotedPid: quotedPid,
        ),
      );
    }

    posts.sort((a, b) => a.floor.compareTo(b.floor));
    return ThreadData(topicTitle: topicTitle, posts: posts);
  }

  int? _extractUidFromHref(String? href) {
    if (href == null || href.isEmpty) return null;
    final match = RegExp(r'uid=(\d+)').firstMatch(href);
    return int.tryParse(match?.group(1) ?? '');
  }

  Map<String, Map<String, dynamic>> _extractUserInfo(String html) {
    final userInfo = <String, Map<String, dynamic>>{};

    final startMarker = 'commonui.userInfo.setAll(';
    final startIndex = html.indexOf(startMarker);
    if (startIndex == -1) return userInfo;

    final jsonStart = startIndex + startMarker.length;
    final jsonEnd = _findMatchingParenEnd(html, start: jsonStart);
    if (jsonEnd == null || jsonEnd <= jsonStart) return userInfo;

    var jsonStr = html.substring(jsonStart, jsonEnd);
    jsonStr = jsonStr.replaceAll('\t', ' ');
    jsonStr = jsonStr.replaceAll(_controlCharsRegex, '');

    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      final groups = <String, String>{};
      final groupsData = data['__GROUPS'];
      if (groupsData is Map<String, dynamic>) {
        for (final entry in groupsData.entries) {
          if (entry.value is! Map) continue;
          final groupMap = entry.value as Map<String, dynamic>;
          groups[entry.key] = groupMap['0']?.toString() ?? '';
        }
      }

      for (final entry in data.entries) {
        if (entry.key.startsWith('__')) continue;
        if (entry.value is! Map) continue;

        final userData = entry.value as Map<String, dynamic>;
        final uid = entry.key;
        final memberId = userData['memberid']?.toString() ?? '';
        final userLevel = _formatUserLevel(userData, groups[memberId] ?? '');
        final regDate = _formatRegistrationDate(userData['regdate']);

        userInfo[uid] = {
          'nickname': userData['username'] ?? '',
          'uid': int.tryParse(uid) ?? 0,
          'level': userLevel,
          'registration_date': regDate,
        };
      }
    } catch (_) {
      // Ignore; author info will be partial.
    }

    return userInfo;
  }

  int? _findMatchingParenEnd(String s, {required int start}) {
    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = start; i < s.length; i++) {
      final ch = s[i];

      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (ch == r'\') {
          escaped = true;
          continue;
        }
        if (ch == '"') {
          inString = false;
        }
        continue;
      }

      if (ch == '"') {
        inString = true;
        continue;
      }
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      if (depth == 0 && ch == ')') return i;
    }

    return null;
  }

  String _formatUserLevel(Map<String, dynamic> userData, String groupName) {
    final reputation = userData['reputation']?.toString() ?? '';

    if (reputation.isNotEmpty && reputation != 'null') {
      final parts = reputation.split(',');
      final repMap = <int, int>{};
      for (final part in parts) {
        final kv = part.split('_');
        if (kv.length != 2) continue;
        repMap[int.tryParse(kv[0]) ?? 0] = int.tryParse(kv[1]) ?? 0;
      }

      if (groupName.contains('警告')) return groupName;

      var hasWarning = false;
      var warningLevel = 0;
      final rep16 = repMap[16];
      if (rep16 != null && rep16 < 0) {
        hasWarning = true;
        warningLevel = (rep16.abs() / 300).ceil();
      }

      final repParts = <String>[];
      final rep61 = repMap[61];
      if (rep61 != null) {
        final lv = rep61 >= 0 ? rep61 ~/ 10 : -1;
        repParts.add('声望: $rep61(lv$lv)');
      }
      if (hasWarning) {
        repParts.add('威望: $rep16(警告$warningLevel)');
      }
      if (repParts.isNotEmpty) return repParts.join(' ');
    }

    return groupName;
  }

  String _formatRegistrationDate(dynamic regdate) {
    if (regdate == null) return '';
    final timestamp =
        regdate is int ? regdate : int.tryParse(regdate.toString()) ?? 0;
    if (timestamp == 0) return '';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final year = (date.year % 100).toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<int, PostArgInfo> _extractPostArgInfoByFloor(String html) {
    final result = <int, PostArgInfo>{};
    var offset = 0;

    while (true) {
      final start = html.indexOf('commonui.postArg.proc(', offset);
      if (start == -1) break;
      final argsStart = start + 'commonui.postArg.proc('.length;
      final end = _findMatchingCallParen(html, start: argsStart);
      if (end == null) break;

      final argsStr = html.substring(argsStart, end);
      final args = _splitTopLevelArgs(argsStr);
      offset = end + 1;

      if (args.isEmpty) continue;
      final floor = int.tryParse(_stripQuotes(args.first));
      if (floor == null) continue; // skip comment procs like '__855...'

      final likeCount = _extractLikeCountFromArgs(args);
      final deviceStr = _extractDeviceStrFromArgs(args);
      result[floor] = PostArgInfo(likeCount: likeCount, deviceStr: deviceStr);
    }

    return result;
  }

  int? _findMatchingCallParen(String s, {required int start}) {
    var depth = 0;
    var inSingleQuote = false;
    var escaped = false;

    for (var i = start; i < s.length; i++) {
      final ch = s[i];

      if (inSingleQuote) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (ch == r'\') {
          escaped = true;
          continue;
        }
        if (ch == "'") {
          inSingleQuote = false;
        }
        continue;
      }

      if (ch == "'") {
        inSingleQuote = true;
        continue;
      }
      if (ch == '(') depth++;
      if (ch == ')') {
        if (depth == 0) return i;
        depth--;
      }
    }

    return null;
  }

  List<String> _splitTopLevelArgs(String s) {
    final out = <String>[];
    final buf = StringBuffer();
    var depth = 0;
    var inSingleQuote = false;
    var escaped = false;

    for (var i = 0; i < s.length; i++) {
      final ch = s[i];

      if (inSingleQuote) {
        buf.write(ch);
        if (escaped) {
          escaped = false;
          continue;
        }
        if (ch == r'\') {
          escaped = true;
          continue;
        }
        if (ch == "'") inSingleQuote = false;
        continue;
      }

      if (ch == "'") {
        inSingleQuote = true;
        buf.write(ch);
        continue;
      }

      if (ch == '(') depth++;
      if (ch == ')' && depth > 0) depth--;

      if (ch == ',' && depth == 0) {
        out.add(buf.toString().trim());
        buf.clear();
        continue;
      }

      buf.write(ch);
    }

    final tail = buf.toString().trim();
    if (tail.isNotEmpty) out.add(tail);
    return out;
  }

  String _stripQuotes(String s) {
    final t = s.trim();
    if (t.length >= 2 && t.startsWith("'") && t.endsWith("'")) {
      return t.substring(1, t.length - 1);
    }
    if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
      return t.substring(1, t.length - 1);
    }
    return t;
  }

  int _extractLikeCountFromArgs(List<String> args) {
    for (final arg in args) {
      final v = _stripQuotes(arg);
      final m = RegExp(r'^\d+,\d+,\d+$').firstMatch(v);
      if (m == null) continue;
      final parts = v.split(',');
      if (parts.length != 3) continue;
      return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  String _extractDeviceStrFromArgs(List<String> args) {
    // Prefer the one that contains common device keywords.
    for (final arg in args) {
      final v = _stripQuotes(arg);
      if (v.contains('Android') ||
          v.contains('iOS') ||
          v.toLowerCase().contains('iphone') ||
          v.toLowerCase().contains('ipad')) {
        return v;
      }
    }
    return '';
  }

  String? _extractEditedTime(String html, int floor) {
    final regex = RegExp(
      r"commonui\.loadAlertInfo\('\[E(\d+)\s+\d+\s+\d+\].*?','alertc" +
          floor.toString() +
          r"'\)",
    );
    final match = regex.firstMatch(html);
    if (match == null) return null;
    final timestamp = int.tryParse(match.group(1) ?? '');
    if (timestamp == null) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _parseDeviceType(String deviceStr) {
    if (deviceStr.isEmpty) return '';
    final s = deviceStr.toLowerCase();
    if (s.contains('android')) return 'android';
    if (s.contains('ipad')) return 'ipad';
    if (s.contains('iphone')) return 'iphone';
    if (s.contains('ios')) return 'iphone';
    return '';
  }

  PostQuote? _parseQuote(String content) {
    var match = _quoteRegex1.firstMatch(content);
    if (match != null) {
      return PostQuote(
        quotedUser: match.group(2)?.trim() ?? '',
        quotedTime: match.group(3)?.trim() ?? '',
        content: _cleanHtmlContent(match.group(4) ?? '').trim(),
      );
    }

    match = _quoteRegex2.firstMatch(content);
    if (match != null) {
      return PostQuote(
        quotedUser: match.group(3)?.trim() ?? '',
        quotedTime: match.group(4)?.trim() ?? '',
        content: _cleanHtmlContent(match.group(5) ?? '').trim(),
        quotedPid: int.tryParse(match.group(1) ?? ''),
      );
    }

    match = _replyToRegex.firstMatch(content);
    if (match != null) {
      return PostQuote(
        quotedUser: match.group(3)?.trim() ?? '',
        quotedTime: match.group(4)?.trim() ?? '',
        content: '',
        quotedPid: int.tryParse(match.group(1) ?? ''),
      );
    }

    match = _replyToTopicRegex.firstMatch(content);
    if (match != null) {
      return PostQuote(
        quotedUser: match.group(3)?.trim() ?? '',
        quotedTime: match.group(4)?.trim() ?? '',
        content: '',
      );
    }

    return null;
  }

  String _cleanContent(String content) {
    if (!content.contains('[')) return content.trim();

    content = content.replaceAll(_quoteBlockRegex, '');
    content = content.replaceAll(_replyToHeaderRegex, '');
    content = content.replaceAll(_replyToTopicHeaderRegex, '');

    content = content
        .replaceAll(_ubbAcRegex, '')
        .replaceAll(_ubbPgRegex, '')
        .replaceAll(_ubbA2Regex, '')
        .replaceAll(_ubbImgRegex, '[图片]')
        .replaceAll(_ubbUrlRegex, '[链接]');

    content = content.trim();
    content = content.replaceAll(_leadingWsRegex, '');
    return content.trim();
  }

  String _innerHtmlToText(String innerHtml) {
    var content = innerHtml;
    content = content.replaceAll(_htmlBrRegex, '\n');
    content = content.replaceAll(_htmlTagRegex, '');
    return _cleanHtmlContent(content);
  }

  String _cleanHtmlContent(String content) {
    content = content
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    content = content.replaceAll(_multiBlankRegex, '\n\n');
    return content.trim();
  }
}

void main(List<String> args) async {
  final htmlPath = args.isNotEmpty
      ? args[0]
      : '../tid_46051013_pages_1_7_1769339744793.html';
  final outputPath =
      args.length > 1 ? args[1] : '../outputs/thread_dom_full.json';

  final htmlFile = File(htmlPath);
  if (!await htmlFile.exists()) {
    stderr.writeln('File not found: $htmlPath');
    exitCode = 2;
    return;
  }

  final rawHtml = await htmlFile.readAsString();
  final parser = NgaThreadDomParser();
  final thread = parser.parse(rawHtml);

  final encoder = JsonEncoder.withIndent('  ');
  final jsonOut = encoder.convert(thread.toJson());

  final outFile = File(outputPath);
  await outFile.create(recursive: true);
  await outFile.writeAsString(jsonOut);
  stdout.writeln('Wrote: $outputPath');
}
