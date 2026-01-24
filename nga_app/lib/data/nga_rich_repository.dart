import 'dart:convert';

import '../src/codec/decode_best_effort.dart';
import '../src/http/nga_http_client.dart';
import '../src/model/thread_rich_detail.dart';
import '../src/parser/thread_rich_parser.dart';

class NgaRichRepository {
  NgaRichRepository({required String cookie, NgaHttpClient? client})
    : _cookie = cookie,
      _client = client ?? NgaHttpClient();

  static const String _baseUrl = 'https://bbs.nga.cn';

  final String _cookie;
  final NgaHttpClient _client;

  Future<ThreadRichDetail> fetchThread(int tid, {int page = 1}) async {
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
    return ThreadRichParser().parseThreadPage(
      htmlText,
      tid: tid,
      url: url.toString(),
      fetchedAt: fetchedAt,
    );
  }

  String _decodeResponse(NgaHttpResponse resp) {
    final preview = latin1.decode(resp.bodyBytes.take(4096).toList());
    return DecodeBestEffort.decode(
      resp.bodyBytes,
      contentTypeHeader: resp.headers['content-type'],
      htmlTextPreview: preview,
    );
  }

  void close() {
    _client.close();
  }
}
