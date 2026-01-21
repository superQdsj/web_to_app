import 'dart:convert';
import '../src/nga_fetcher.dart';

/// Repository for fetching NGA forum data.
///
/// Reuses [NgaHttpClient], [DecodeBestEffort], [ForumParser], and [ThreadParser]
/// from the local nga_fetcher module.
class NgaRepository {
  NgaRepository({required String cookie, NgaHttpClient? client})
    : _cookie = cookie,
      _client = client ?? NgaHttpClient();

  static const String _baseUrl = 'https://bbs.nga.cn';

  final String _cookie;
  final NgaHttpClient _client;

  /// Fetches the thread list for a given forum (by fid).
  ///
  /// Returns a list of [ThreadItem] parsed from the forum page.
  Future<List<ThreadItem>> fetchForumThreads(int fid, {int page = 1}) async {
    final url = Uri.parse('$_baseUrl/thread.php').replace(
      queryParameters: <String, String>{
        'fid': fid.toString(),
        if (page > 1) 'page': page.toString(),
      },
    );

    final resp = await _client.getBytes(
      url,
      cookieHeaderValue: _cookie,
      timeout: const Duration(seconds: 30),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch forum: HTTP ${resp.statusCode}');
    }

    final htmlText = _decodeResponse(resp);
    final items = ForumParser().parseForumThreadList(htmlText);
    return items;
  }

  /// Fetches the thread detail for a given thread (by tid).
  ///
  /// Returns a [ThreadDetail] parsed from the given page of posts.
  Future<ThreadDetail> fetchThread(int tid, {int page = 1}) async {
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

    final htmlText = _decodeResponse(resp);
    final fetchedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final detail = ThreadParser().parseThreadPage(
      htmlText,
      tid: tid,
      url: url.toString(),
      fetchedAt: fetchedAt,
    );

    return detail;
  }

  /// Decodes the HTTP response body using best-effort encoding detection.
  String _decodeResponse(NgaHttpResponse resp) {
    // Use latin1 for preview (safe for detecting charset in meta tags)
    final preview = latin1.decode(resp.bodyBytes.take(4096).toList());

    return DecodeBestEffort.decode(
      resp.bodyBytes,
      contentTypeHeader: resp.headers['content-type'],
      htmlTextPreview: preview,
    );
  }

  /// Closes the underlying HTTP client.
  void close() {
    _client.close();
  }
}
