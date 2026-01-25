import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../src/codec/decode_best_effort.dart';
import '../src/http/nga_http_client.dart';
import '../src/parser/full_parse.dart';

/// Repository for fetching NGA thread data using DOM-based parsing.
///
/// Uses [NgaThreadDomParser] to parse raw HTML into [ThreadData].
/// Parsing is performed in an isolate to avoid blocking the UI.
class NgaThreadDomRepository {
  NgaThreadDomRepository({required String cookie, NgaHttpClient? client})
    : _cookie = cookie,
      _client = client ?? NgaHttpClient();

  static const String _baseUrl = 'https://bbs.nga.cn';
  static const bool _dumpEnabled =
      bool.fromEnvironment('NGA_DUMP_DOM_HTML', defaultValue: false);
  static const int _dumpTid =
      int.fromEnvironment('NGA_DUMP_TID', defaultValue: 0);
  static const int _dumpPage =
      int.fromEnvironment('NGA_DUMP_PAGE', defaultValue: 0);

  final String _cookie;
  final NgaHttpClient _client;

  /// Cache of posts by pid for cross-page quote backfilling.
  final Map<int, ThreadPost> _postByPidCache = {};

  /// Fetches thread data for a given thread (by tid).
  ///
  /// Returns a [ThreadData] parsed from the given page of posts.
  /// Uses isolate-based parsing to avoid UI blocking.
  Future<ThreadData> fetchThread(int tid, {int page = 1}) async {
    final sw = Stopwatch()..start();
    final url = Uri.parse('$_baseUrl/read.php').replace(
      queryParameters: <String, String>{
        'tid': tid.toString(),
        if (page > 1) 'page': page.toString(),
      },
    );

    final resp = await _client.getBytes(
      url,
      cookieHeaderValue: _cookie,
      timeout: const Duration(seconds: 30),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch thread: HTTP ${resp.statusCode}');
    }

    if (kDebugMode) {
      debugPrint(
        '=== [NGA] DOM thread response tid=$tid page=$page '
        'bytes=${resp.bodyBytes.length} content-type=${resp.headers['content-type'] ?? ''} ===',
      );
    }

    final decodeResult = _decodeResponseWithReport(resp);
    final htmlText = decodeResult.text;
    if (kDebugMode) {
      debugPrint(
        '=== [NGA] DOM thread decode tid=$tid page=$page '
        'chosen=${decodeResult.chosenCharset ?? 'unknown'} by=${decodeResult.chosenBy} '
        'allowMalformed=${decodeResult.usedAllowMalformed} '
        'candidates=${decodeResult.candidatesTried.join(',')} '
        'htmlLen=${htmlText.length} elapsed=${sw.elapsedMilliseconds}ms ===',
      );
    }
    await _maybeDumpHtml(tid, page, resp, decodeResult);

    // Parse in isolate to avoid blocking UI.
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = await compute(_parseThreadInIsolate, htmlText);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '=== [NGA] DOM thread parse FAILED tid=$tid page=$page '
          'htmlLen=${htmlText.length} elapsed=${sw.elapsedMilliseconds}ms ===',
        );
        debugPrint(e.toString());
        debugPrint(st.toString());
      }
      rethrow;
    }
    final threadData = _threadDataFromJson(jsonMap);
    if (kDebugMode) {
      debugPrint(
        '=== [NGA] DOM thread parsed tid=$tid page=$page '
        'titleLen=${threadData.topicTitle.length} posts=${threadData.posts.length} '
        'elapsed=${sw.elapsedMilliseconds}ms ===',
      );
    }

    // Cache posts for cross-page quote backfilling.
    for (final post in threadData.posts) {
      _postByPidCache[post.pid] = post;
    }

    // Backfill quotes for posts with missing quote content.
    final backfilledPosts = _backfillQuotes(threadData.posts);

    return ThreadData(
      topicTitle: threadData.topicTitle,
      posts: backfilledPosts,
    );
  }

  /// Backfills quote content for posts that reference other posts.
  List<ThreadPost> _backfillQuotes(List<ThreadPost> posts) {
    final result = <ThreadPost>[];

    for (final post in posts) {
      final quote = post.quote;
      if (quote == null ||
          quote.quotedPid == null ||
          quote.content.isNotEmpty) {
        result.add(post);
        continue;
      }

      final referenced = _postByPidCache[quote.quotedPid];
      if (referenced == null) {
        result.add(post);
        continue;
      }

      result.add(
        ThreadPost(
          pid: post.pid,
          floor: post.floor,
          isTopicPost: post.isTopicPost,
          author: post.author,
          content: post.content,
          replyTime: post.replyTime,
          likeCount: post.likeCount,
          deviceType: post.deviceType,
          editedTime: post.editedTime,
          quote: PostQuote(
            quotedUser: quote.quotedUser,
            quotedTime: quote.quotedTime,
            content: referenced.content,
            quotedPid: quote.quotedPid,
          ),
        ),
      );
    }

    return result;
  }

  /// Clears the post cache.
  void clearCache() {
    _postByPidCache.clear();
  }

  /// Decodes the HTTP response body using best-effort encoding detection.
  DecodeResult _decodeResponseWithReport(NgaHttpResponse resp) {
    final preview = latin1.decode(resp.bodyBytes.take(4096).toList());
    return DecodeBestEffort.decodeWithReport(
      resp.bodyBytes,
      contentTypeHeader: resp.headers['content-type'],
      htmlTextPreview: preview,
    );
  }

  Future<void> _maybeDumpHtml(
    int tid,
    int page,
    NgaHttpResponse resp,
    DecodeResult decoded,
  ) async {
    if (!kDebugMode || !_dumpEnabled) return;
    if (_dumpTid != 0 && tid != _dumpTid) return;
    if (_dumpPage != 0 && page != _dumpPage) return;

    try {
      final dir = Directory('private/nga_debug');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final ts = DateTime.now().millisecondsSinceEpoch;
      final base = 'thread_${tid}_p${page}_$ts';
      final rawPath = '${dir.path}/$base.raw.bin';
      final htmlPath = '${dir.path}/$base.decoded.html';
      final metaPath = '${dir.path}/$base.meta.txt';

      await File(rawPath).writeAsBytes(resp.bodyBytes, flush: true);
      await File(htmlPath).writeAsString(decoded.text, flush: true);
      await File(metaPath).writeAsString(
        [
          'tid=$tid page=$page',
          'status=${resp.statusCode}',
          "content-type=${resp.headers['content-type'] ?? ''}",
          'decode.chosenCharset=${decoded.chosenCharset ?? 'unknown'}',
          'decode.chosenBy=${decoded.chosenBy}',
          'decode.usedAllowMalformed=${decoded.usedAllowMalformed}',
          'decode.candidates=${decoded.candidatesTried.join(',')}',
          'bytes=${resp.bodyBytes.length}',
          'htmlLen=${decoded.text.length}',
        ].join('\n'),
        flush: true,
      );

      debugPrint('=== [NGA] Dumped DOM thread HTML to $htmlPath ===');
      debugPrint('=== [NGA] Dumped DOM thread RAW to $rawPath ===');
      debugPrint('=== [NGA] Dumped DOM thread META to $metaPath ===');
    } catch (e) {
      // Best-effort only; avoid breaking thread loading.
      debugPrint('=== [NGA] Dump DOM thread HTML failed: $e ===');
    }
  }

  /// Closes the underlying HTTP client.
  void close() {
    _client.close();
  }
}

/// Top-level function for isolate parsing.
/// Returns JSON map that can be transferred across isolates.
Map<String, dynamic> _parseThreadInIsolate(String rawHtml) {
  final parser = NgaThreadDomParser();
  return parser.parse(rawHtml).toJson();
}

/// Converts JSON map back to ThreadData.
ThreadData _threadDataFromJson(Map<String, dynamic> json) {
  final postsJson = json['posts'] as List<dynamic>;
  final posts = postsJson.map((p) => _threadPostFromJson(p as Map<String, dynamic>)).toList();
  return ThreadData(
    topicTitle: json['topic_title'] as String? ?? '',
    posts: posts,
  );
}

ThreadPost _threadPostFromJson(Map<String, dynamic> json) {
  final authorJson = json['author'] as Map<String, dynamic>?;
  final quoteJson = json['quote'] as Map<String, dynamic>?;

  return ThreadPost(
    pid: json['pid'] as int,
    floor: json['floor'] as int,
    isTopicPost: json['is_topic_post'] as bool? ?? false,
    author: authorJson != null
        ? PostAuthor(
            nickname: authorJson['nickname'] as String? ?? '',
            uid: authorJson['uid'] as int? ?? 0,
            level: authorJson['level'] as String? ?? '',
            registrationDate: authorJson['registration_date'] as String? ?? '',
          )
        : const PostAuthor(nickname: '', uid: 0, level: '', registrationDate: ''),
    content: json['content'] as String? ?? '',
    replyTime: json['reply_time'] as String? ?? '',
    likeCount: json['like_count'] as int? ?? 0,
    deviceType: json['device_type'] as String? ?? '',
    editedTime: json['edited_time'] as String?,
    quote: quoteJson != null
        ? PostQuote(
            quotedUser: quoteJson['quoted_user'] as String? ?? '',
            quotedTime: quoteJson['quoted_time'] as String? ?? '',
            content: quoteJson['content'] as String? ?? '',
            quotedPid: quoteJson['quoted_pid'] as int?,
          )
        : null,
  );
}
