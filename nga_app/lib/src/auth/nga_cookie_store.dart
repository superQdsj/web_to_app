import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NgaCookieStore {
  NgaCookieStore._();

  static final ValueNotifier<String> cookie =
      ValueNotifier<String>('');

  static const String _storageKey = 'nga_cookies';

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

  /// Load cookies from persistent storage.
  static Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCookie = prefs.getString(_storageKey) ?? '';
      if (savedCookie.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '=== [NGA] NgaCookieStore.loadFromStorage: '
            '${summarizeCookieHeader(savedCookie)} ===',
          );
        }
        cookie.value = savedCookie;
      }
    } catch (e) {
      debugPrint('=== [NGA] NgaCookieStore.loadFromStorage failed: $e ===');
    }
  }

  /// Save current cookies to persistent storage.
  static Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, cookie.value);
      if (kDebugMode) {
        debugPrint('=== [NGA] NgaCookieStore.saveToStorage success ===');
      }
    } catch (e) {
      debugPrint('=== [NGA] NgaCookieStore.saveToStorage failed: $e ===');
    }
  }

  /// Clear cookies from persistent storage.
  static Future<void> clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      if (kDebugMode) {
        debugPrint('=== [NGA] NgaCookieStore.clearStorage success ===');
      }
    } catch (e) {
      debugPrint('=== [NGA] NgaCookieStore.clearStorage failed: $e ===');
    }
  }
}
