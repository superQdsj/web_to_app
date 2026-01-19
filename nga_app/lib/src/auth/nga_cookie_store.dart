import 'package:flutter/foundation.dart';

class NgaCookieStore {
  NgaCookieStore._();

  static final ValueNotifier<String> cookie =
      ValueNotifier<String>('');

  static bool get hasCookie => cookie.value.trim().isNotEmpty;

  static String summarizeCookieHeader(String cookieHeader) {
    final trimmed = cookieHeader.trim();
    if (trimmed.isEmpty) return '(empty)';

    final parts = trimmed.split(';');
    final summaries = <String>[];
    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;
      final eq = part.indexOf('=');
      if (eq <= 0) {
        summaries.add(part);
        continue;
      }
      final name = part.substring(0, eq).trim();
      final value = part.substring(eq + 1);
      summaries.add('$name(len=${value.length})');
    }
    return summaries.join(', ');
  }

  static void setCookie(String newCookie) {
    final trimmed = newCookie.trim();

    if (kDebugMode) {
      debugPrint('=== [NGA] NgaCookieStore.setCookie len=${trimmed.length} ===');
      debugPrint('=== [NGA] NgaCookieStore.setCookie cookies: '
          '${summarizeCookieHeader(trimmed)} ===');
    }

    cookie.value = trimmed;
  }
}
