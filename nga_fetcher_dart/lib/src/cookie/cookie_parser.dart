class CookieParser {
  /// Normalizes and extracts a cookie header value.
  ///
  /// Supported formats:
  /// 1) raw cookie value: "a=1; b=2"
  /// 2) full header line: "Cookie: a=1; b=2"
  /// 3) a copied cURL snippet containing: -b 'a=1; b=2'
  static String parseCookieHeaderValue(String raw) {
    final curlMatch =
        RegExp(r'''-b\s+['"]([^'"]+)['"]''').firstMatch(raw);
    if (curlMatch != null) {
      return _normalizeCookieHeaderValue(curlMatch.group(1) ?? '');
    }

    return _normalizeCookieHeaderValue(raw);
  }

  static String _normalizeCookieHeaderValue(String cookie) {
    var c = cookie.trim();
    if (c.isEmpty) return '';
    if (c.toLowerCase().startsWith('cookie:')) {
      c = c.split(':').skip(1).join(':').trim();
    }
    // Collapse whitespace.
    return c.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).join(' ');
  }
}
