import 'dart:convert';

import 'package:charset/charset.dart';

class DecodeBestEffort {
  static String decode(
    List<int> bytes, {
    String? contentTypeHeader,
    String? htmlTextPreview,
  }) {
    final candidates = <String>[];

    final headerCharset = _parseCharsetFromContentType(contentTypeHeader);
    if (headerCharset != null && headerCharset.isNotEmpty) {
      candidates.add(headerCharset);
    }

    final metaCharset = _parseCharsetFromHtmlMeta(htmlTextPreview);
    if (metaCharset != null && metaCharset.isNotEmpty) {
      candidates.add(metaCharset);
    }

    // Common NGA fallback list.
    candidates.addAll(['gb18030', 'gbk', 'utf-8']);

    for (final name in candidates) {
      final enc = Charset.getByName(name);
      if (enc == null) continue;
      try {
        return enc.decode(bytes);
      } catch (_) {
        // keep trying
      }
    }

    return utf8.decode(bytes, allowMalformed: true);
  }

  static String? _parseCharsetFromContentType(String? contentType) {
    if (contentType == null) return null;
    final m = RegExp(
      r'charset\s*=\s*([^;\s]+)',
      caseSensitive: false,
    ).firstMatch(contentType);
    return m?.group(1);
  }

  static String? _parseCharsetFromHtmlMeta(String? htmlPreview) {
    if (htmlPreview == null || htmlPreview.isEmpty) return null;

    // Handles: <meta http-equiv='Content-Type' content='text/html; charset=GBK'>
    final m = RegExp(
      r'charset\s*=\s*([A-Za-z0-9_\-]+)',
      caseSensitive: false,
    ).firstMatch(htmlPreview);
    return m?.group(1);
  }
}
