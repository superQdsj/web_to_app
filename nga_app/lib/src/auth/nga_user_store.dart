import 'package:flutter/foundation.dart';

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

  static NgaUserInfo? tryFromLoginSuccessJson(dynamic json) {
    if (json is! Map) return null;

    final uid = json['uid'];
    final username = json['username'];
    if (uid is! num || username is! String || username.trim().isEmpty) {
      return null;
    }

    final avatar = json['avatar'];
    return NgaUserInfo(
      uid: uid.toInt(),
      username: username,
      avatarUrl: avatar is String && avatar.trim().isNotEmpty ? avatar : null,
    );
  }
}

class NgaUserStore {
  NgaUserStore._();

  static final ValueNotifier<NgaUserInfo?> user =
      ValueNotifier<NgaUserInfo?>(null);

  static bool get hasUser => user.value != null;

  static void setUser(NgaUserInfo? newUser) {
    user.value = newUser;
  }

  static void clear() => setUser(null);
}
