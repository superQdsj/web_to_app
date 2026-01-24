import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class NgaUserInfo {
  const NgaUserInfo({
    required this.uid,
    required this.username,
    this.avatarUrl,
  });

  final int uid;
  final String username;
  final String? avatarUrl;

  /// Parse from login success JSON (from NGA login page console.log).
  static NgaUserInfo? tryFromLoginSuccessJson(dynamic json) {
    if (json is! Map) {
      _log(
        'tryFromLoginSuccessJson: json is not a Map, got ${json.runtimeType}',
      );
      return null;
    }

    final uid = json['uid'];
    final username = json['username'];
    if (uid is! num || username is! String || username.trim().isEmpty) {
      _log('tryFromLoginSuccessJson: invalid uid=$uid or username=$username');
      return null;
    }

    final avatar = json['avatar'];
    final userInfo = NgaUserInfo(
      uid: uid.toInt(),
      username: username,
      avatarUrl: avatar is String && avatar.trim().isNotEmpty ? avatar : null,
    );
    _log('tryFromLoginSuccessJson: parsed userInfo=$userInfo');
    return userInfo;
  }

  /// Parse from storage JSON.
  static NgaUserInfo? tryFromStorageJson(Map<String, dynamic> json) {
    try {
      final uid = json['uid'];
      final username = json['username'];
      if (uid is! int || username is! String || username.isEmpty) {
        _log('tryFromStorageJson: invalid data uid=$uid username=$username');
        return null;
      }
      final avatarUrl = json['avatarUrl'] as String?;
      return NgaUserInfo(uid: uid, username: username, avatarUrl: avatarUrl);
    } catch (e) {
      _log('tryFromStorageJson: parse error $e');
      return null;
    }
  }

  /// Convert to JSON for storage.
  Map<String, dynamic> toStorageJson() {
    return {
      'uid': uid,
      'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  @override
  String toString() =>
      'NgaUserInfo(uid: $uid, username: $username, avatarUrl: ${avatarUrl != null ? "(has avatar)" : "null"})';
}

void _log(String message) {
  if (kDebugMode) {
    debugPrint('[NGA][UserStore] $message');
  }
}

class NgaUserStore {
  NgaUserStore._();

  static const String _storageKey = 'nga_user_info';

  static final ValueNotifier<NgaUserInfo?> user = ValueNotifier<NgaUserInfo?>(
    null,
  );

  static bool get hasUser => user.value != null;

  /// Set user and optionally save to storage.
  static Future<void> setUser(
    NgaUserInfo? newUser, {
    bool persist = true,
  }) async {
    final oldUser = user.value;
    user.value = newUser;

    _log('setUser: ${oldUser?.uid} -> ${newUser?.uid} (persist=$persist)');

    if (persist) {
      if (newUser != null) {
        await saveToStorage();
      } else {
        await clearStorage();
      }
    }
  }

  /// Clear user and storage.
  static Future<void> clear() async {
    _log('clear: clearing user');
    await setUser(null, persist: true);
  }

  /// Load user info from persistent storage.
  static Future<void> loadFromStorage() async {
    _log('loadFromStorage: starting...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        _log('loadFromStorage: no saved user info found');
        return;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final userInfo = NgaUserInfo.tryFromStorageJson(json);

      if (userInfo != null) {
        user.value = userInfo;
        _log(
          'loadFromStorage: loaded user ${userInfo.username} (uid=${userInfo.uid})',
        );
      } else {
        _log('loadFromStorage: failed to parse saved user info');
      }
    } catch (e) {
      _log('loadFromStorage: error $e');
    }
  }

  /// Save current user info to persistent storage.
  static Future<void> saveToStorage() async {
    final currentUser = user.value;
    if (currentUser == null) {
      _log('saveToStorage: no user to save');
      return;
    }

    _log('saveToStorage: saving user ${currentUser.username}');
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(currentUser.toStorageJson());
      await prefs.setString(_storageKey, jsonString);
      _log('saveToStorage: success');
    } catch (e) {
      _log('saveToStorage: error $e');
    }
  }

  /// Clear user info from persistent storage.
  static Future<void> clearStorage() async {
    _log('clearStorage: clearing...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _log('clearStorage: success');
    } catch (e) {
      _log('clearStorage: error $e');
    }
  }
}
