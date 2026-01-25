import 'dart:convert';

import 'package:charset/charset.dart';

class DecodeResult {
  const DecodeResult({
    required this.text,
    required this.candidatesTried,
    required this.chosenCharset,
    required this.chosenBy,
    required this.usedAllowMalformed,
  });

  final String text;
  final List<String> candidatesTried;
  final String? chosenCharset;

  /// Where the chosen charset came from: `content-type`, `html-meta`, `fallback`,
  /// or `utf8-malformed`.
  final String chosenBy;

  /// Whether we had to decode with `allowMalformed: true` to succeed.
  final bool usedAllowMalformed;
}

class DecodeBestEffort {
  static String decode(
    List<int> bytes, {
    String? contentTypeHeader,
    String? htmlTextPreview,
  }) {
    return decodeWithReport(
      bytes,
      contentTypeHeader: contentTypeHeader,
      htmlTextPreview: htmlTextPreview,
    ).text;
  }

  static DecodeResult decodeWithReport(
    List<int> bytes, {
    String? contentTypeHeader,
    String? htmlTextPreview,
  }) {
    final candidates = <String>[];
    final candidateSource = <String, String>{};
    final seen = <String>{};

    void addCandidate(String? name, String source) {
      if (name == null) return;
      final trimmed = name.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (!seen.add(key)) return;
      candidates.add(trimmed);
      candidateSource[trimmed] = source;
    }

    addCandidate(
      _parseCharsetFromContentType(contentTypeHeader),
      'content-type',
    );
    addCandidate(_parseCharsetFromHtmlMeta(htmlTextPreview), 'html-meta');

    // Common NGA fallback list.
    addCandidate('gb18030', 'fallback');
    addCandidate('gbk', 'fallback');
    addCandidate('utf-8', 'fallback');

    for (final name in candidates) {
      final enc = Charset.getByName(name);
      if (enc == null) continue;
      try {
        return DecodeResult(
          text: enc.decode(bytes),
          candidatesTried: List.unmodifiable(candidates),
          chosenCharset: name,
          chosenBy: candidateSource[name] ?? 'fallback',
          usedAllowMalformed: false,
        );
      } catch (_) {
        // Some pages contain mixed/invalid sequences (e.g. emoji in GBK pages).
        // Retry with replacement instead of failing the whole decode.
        try {
          final tolerant = _withAllowMalformed(enc);
          if (identical(tolerant, enc)) {
            throw StateError('Encoding does not support allowMalformed');
          }
          return DecodeResult(
            text: tolerant.decode(bytes),
            candidatesTried: List.unmodifiable(candidates),
            chosenCharset: name,
            chosenBy: candidateSource[name] ?? 'fallback',
            usedAllowMalformed: true,
          );
        } catch (_) {
          // keep trying
        }
      }
    }

    return DecodeResult(
      text: utf8.decode(bytes, allowMalformed: true),
      candidatesTried: List.unmodifiable(candidates),
      chosenCharset: null,
      chosenBy: 'utf8-malformed',
      usedAllowMalformed: true,
    );
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

  static Encoding _withAllowMalformed(Encoding enc) {
    // Only a few codecs expose "allowMalformed" in their constructors.
    // For others, we can't reliably enable replacement-mode.
    if (enc is Utf8Codec) return const Utf8Codec(allowMalformed: true);
    if (enc is GbkCodec) return const GbkCodec(allowMalformed: true);
    return enc;
  }
}
