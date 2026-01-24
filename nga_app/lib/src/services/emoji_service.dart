import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

class EmojiService {
  static Map<String, String>? _emojiByCode;
  static Future<void>? _loading;

  static bool get isLoaded => _emojiByCode != null;

  static Future<void> ensureLoaded() {
    if (_emojiByCode != null) {
      return Future.value();
    }
    return _loading ??= _load();
  }

  static String? resolve(String code) {
    final map = _emojiByCode;
    if (map == null) return null;
    final direct = map[code];
    if (direct != null) return direct;
    final normalized = code.toLowerCase();
    return map[normalized];
  }

  static Future<void> _load() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/emoji_merged.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _emojiByCode = json.map((key, value) {
        final stringValue = value.toString();
        return MapEntry(key, stringValue);
      });
      if (kDebugMode) {
        debugPrint(
          '[EmojiService] Loaded emoji map (${_emojiByCode!.length} items)',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[EmojiService] Failed to load emoji map: $e');
        debugPrint('[EmojiService] StackTrace: $stackTrace');
      }
      rethrow;
    } finally {
      _loading = null;
    }
  }
}
