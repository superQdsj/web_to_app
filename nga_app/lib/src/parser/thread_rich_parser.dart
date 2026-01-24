import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../model/thread_detail.dart';
import '../model/thread_rich_detail.dart';
import 'thread_rich_content_parser.dart';
import 'thread_rich_quote_resolver.dart';

class ThreadRichParser {
  ThreadRichDetail parseThreadPage(
    String htmlText, {
    required int tid,
    required String url,
    required int fetchedAt,
  }) {
    final userInfoMap = _extractUserInfo(htmlText);
    final groupsMap =
        userInfoMap['__GROUPS'] as Map<String, dynamic>? ??
        _extractGroups(htmlText);

    final doc = html_parser.parse(htmlText);
    final postRows = doc.querySelectorAll('table.forumbox.postbox');
    final posts = <ThreadRichPost>[];
    final contentParser = ThreadRichContentParser();

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

      final authorUidStr =
          authorEl?.attributes['href']?.split('uid=').last ?? '';
      final authorUid = int.tryParse(authorUidStr);

      final rawContent = contentEl?.innerHtml.trim() ?? '';
      if (rawContent.isEmpty && authorUid == null) continue;

      final deviceType = _extractDeviceType(htmlText, floor);
      final postDate = row.querySelector('[id^=postdate]')?.text.trim();

      ThreadPostAuthor? author;
      if (authorUid != null && userInfoMap.containsKey(authorUid.toString())) {
        final userData =
            userInfoMap[authorUid.toString()] as Map<String, dynamic>;
        author = _mapToThreadPostAuthor(userData, groupsMap);
      }

      final contentBlocks = rawContent.isNotEmpty
          ? contentParser.parse(rawContent)
          : const <ThreadContentBlock>[];
      posts.add(
        ThreadRichPost(
          pid: pid,
          floor: floor,
          author: author,
          authorUid: authorUid,
          contentBlocks: contentBlocks,
          rawContent: rawContent,
          deviceType: deviceType,
          postDate: postDate,
        ),
      );
    }

    final filledPosts = ThreadRichQuoteResolver.resolve(posts);
    return ThreadRichDetail(
      tid: tid,
      url: url,
      fetchedAt: fetchedAt,
      posts: filledPosts,
      rawHtmlText: htmlText,
    );
  }

  Map<String, dynamic> _extractUserInfo(String html) {
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
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> _extractGroups(String html) {
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
    final floorPattern = RegExp(
      "commonui\\.postArg\\.proc\\(\\s*$floorIndex,.*?('[^']+')\\s*,\\s*'',\\s*null,\\s*0\\s*\\)",
      dotAll: true,
    );
    final match = floorPattern.firstMatch(html);
    if (match != null) {
      final call = match.group(0)!;
      final parts = call.split(',');
      if (parts.length > 20) {
        final devicePart = parts[parts.length - 4].trim().replaceAll("'", '');
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
    var cleaned = jsContent.replaceAll('\t', r'\t');
    cleaned = cleaned.replaceAll(RegExp(r',\s*([\]}])'), r'$1');
    return cleaned;
  }

  int? _tryExtractFloor(Element el) {
    final id = el.id;
    if (id.isEmpty) return null;
    final match = RegExp(r'(\d+)$').firstMatch(id);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  int? _extractPidFromPostRow(Element row) {
    final idMatch = RegExp(r'pid(\d+)');
    final hrefMatch = RegExp(r'pid=(\d+)');
    final hashMatch = RegExp(r'#pid(\d+)');

    final rowId = row.id;
    if (rowId.isNotEmpty) {
      final match = idMatch.firstMatch(rowId);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    final rowName = row.attributes['name'];
    if (rowName != null) {
      final match = idMatch.firstMatch(rowName);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    for (final el in row.querySelectorAll('[id], [name]')) {
      final candidateId = el.id;
      if (candidateId.isNotEmpty) {
        final match = idMatch.firstMatch(candidateId);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
      }
      final candidateName = el.attributes['name'];
      if (candidateName != null) {
        final match = idMatch.firstMatch(candidateName);
        if (match != null) {
          return int.tryParse(match.group(1)!);
        }
      }
    }

    for (final link in row.querySelectorAll('a')) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) {
        continue;
      }
      final match = hrefMatch.firstMatch(href);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
      final match2 = hashMatch.firstMatch(href);
      if (match2 != null) {
        return int.tryParse(match2.group(1)!);
      }
    }
    return null;
  }
}
