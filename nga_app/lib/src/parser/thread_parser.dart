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
  ThreadDetail parseHybrid(String htmlText, {required int tid, required String url, required int fetchedAt}) {
    // 1. Extract metadata via Regex
    final userInfoMap = _extractUserInfo(htmlText);
    final groupsMap = userInfoMap['__GROUPS'] as Map<String, dynamic>? ?? _extractGroups(htmlText);

    final doc = html_parser.parse(htmlText);

    // 2. Identify all posts (table.postbox or .postrow)
    final postRows = doc.querySelectorAll('table.forumbox.postbox');
    final posts = <ThreadPost>[];

    for (var i = 0; i < postRows.length; i++) {
      final row = postRows[i];
      final floor = i; // Simplified floor index for now, or extract from DOM

      // Extract UID from author link href
      final authorLink = row.querySelector('#postauthor$i');
      final authorUidStr = authorLink?.attributes['href']?.split('uid=').last ?? '';
      final authorUid = int.tryParse(authorUidStr);

      // Extract content
      final contentEl = row.querySelector('#postcontent$i');
      final contentText = contentEl?.text.trim() ?? '';
      if (contentText.isEmpty && authorUid == null) continue;

      // Extract device and other info from postArg.proc script following the table
      final deviceType = _extractDeviceType(htmlText, i);

      // Map author metadata
      ThreadPostAuthor? author;
      if (authorUid != null && userInfoMap.containsKey(authorUid.toString())) {
        final userData = userInfoMap[authorUid.toString()] as Map<String, dynamic>;
        author = _mapToThreadPostAuthor(userData, groupsMap);
      }

      posts.add(ThreadPost(floor: floor, author: author, authorUid: authorUid, contentText: contentText, deviceType: deviceType));
    }

    return ThreadDetail(tid: tid, url: url, fetchedAt: fetchedAt, posts: posts);
  }

  ThreadDetail _parseLegacy(String htmlText, {required int tid, required String url, required int fetchedAt}) {
    final doc = html_parser.parse(htmlText);
    final preferred = doc.querySelectorAll('.postcontent.ubbcode');
    final candidates = preferred.isNotEmpty ? preferred : doc.querySelectorAll('.postcontent');

    final posts = <ThreadPost>[];
    for (final el in candidates) {
      final contentText = el.text.trim();
      if (contentText.isEmpty) continue;

      final floor = _tryExtractFloor(el);
      Element? authorLink;
      if (floor != null) {
        authorLink = doc.getElementById('postauthor$floor');
      }

      final authorUid = extractUidFromHref(authorLink?.attributes['href'] ?? '');

      posts.add(
        ThreadPost(
          floor: floor,
          author: null, // Legacy parser doesn't have rich author info
          authorUid: authorUid,
          contentText: contentText,
        ),
      );
    }

    return ThreadDetail(tid: tid, url: url, fetchedAt: fetchedAt, posts: posts);
  }

  Map<String, dynamic> _extractUserInfo(String html) {
    // commonui.userInfo.setAll( { ... } )
    // Use the markers if available, otherwise fallback to greedy match within the function call
    final match =
        RegExp(r'commonui\.userInfo\.setAll\(\s*({.*})\s*\)\s*;?\s*//userinfoend', dotAll: true).firstMatch(html) ??
        RegExp(r'commonui\.userInfo\.setAll\(\s*({.*})\s*\)', dotAll: true).firstMatch(html);

    if (match != null) {
      final jsonStr = _cleanJson(match.group(1)!);
      try {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        print('DEBUG: userInfo jsonDecode failed: $e');
      }
    }
    return {};
  }

  Map<String, dynamic> _extractGroups(String html) {
    // "__GROUPS": { ... }
    final match = RegExp(r'"__GROUPS"\s*:\s*({.*?})\s*[,}]', dotAll: true).firstMatch(html);
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

  ThreadPostAuthor _mapToThreadPostAuthor(Map<String, dynamic> data, Map<String, dynamic> groups) {
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
}
