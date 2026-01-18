import 'package:flutter/foundation.dart';

class NgaCookieStore {
  NgaCookieStore._();

  static final ValueNotifier<String> cookie =
      ValueNotifier<String>('');

  static bool get hasCookie => cookie.value.trim().isNotEmpty;

  static void setCookie(String newCookie) {
    final trimmed = newCookie.trim();

    if (kDebugMode) {
      debugPrint('=== [NGA] NgaCookieStore.setCookie (full) ===');
      debugPrint(trimmed);
      debugPrint('=== [NGA] NgaCookieStore.setCookie len=${trimmed.length} ===');
    }

    cookie.value = trimmed;
  }
}
