import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class NgaHttpResponse {
  NgaHttpResponse({
    required this.url,
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  final Uri url;
  final int statusCode;
  final Map<String, String> headers;
  final List<int> bodyBytes;
}

class NgaHttpClient {
  NgaHttpClient({http.Client? client}) : _client = client ?? IOClient();

  final http.Client _client;

  static const String defaultUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36';

  Future<NgaHttpResponse> getBytes(
    Uri url, {
    required String cookieHeaderValue,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final headers = <String, String>{
      HttpHeaders.userAgentHeader: defaultUserAgent,
      HttpHeaders.acceptHeader:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      HttpHeaders.acceptLanguageHeader: 'zh-CN,zh;q=0.9,en;q=0.8',
      if (cookieHeaderValue.trim().isNotEmpty)
        HttpHeaders.cookieHeader: cookieHeaderValue.trim(),
    };

    final response = await _client
        .get(url, headers: headers)
        .timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('timeout fetching $url');
          },
        );

    return NgaHttpResponse(
      url: url,
      statusCode: response.statusCode,
      headers: response.headers,
      bodyBytes: response.bodyBytes,
    );
  }

  Future<NgaHttpResponse> postBytes(
    Uri url, {
    required String cookieHeaderValue,
    required List<int> bodyBytes,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final mergedHeaders = <String, String>{
      HttpHeaders.userAgentHeader: defaultUserAgent,
      HttpHeaders.acceptHeader:
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      HttpHeaders.acceptLanguageHeader: 'zh-CN,zh;q=0.9,en;q=0.8',
      if (cookieHeaderValue.trim().isNotEmpty)
        HttpHeaders.cookieHeader: cookieHeaderValue.trim(),
      if (headers != null) ...headers,
    };

    final response = await _client
        .post(url, headers: mergedHeaders, body: bodyBytes)
        .timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('timeout posting $url');
          },
        );

    return NgaHttpResponse(
      url: url,
      statusCode: response.statusCode,
      headers: response.headers,
      bodyBytes: response.bodyBytes,
    );
  }

  void close() {
    _client.close();
  }
}
