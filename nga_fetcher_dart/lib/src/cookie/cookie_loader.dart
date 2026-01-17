import 'dart:io';

import 'package:dotenv/dotenv.dart';

import 'cookie_parser.dart';

/// 统一的 Cookie 加载器，支持多种来源
/// 优先级: 环境变量 > .env 文件
class CookieLoader {
  /// 环境变量名
  static const envKey = 'NGA_COOKIE';

  /// 加载 cookie，按优先级尝试多个来源
  ///
  /// [envFilePath] - .env 文件路径，默认为项目根目录的 .env
  static String load({
    String? envFilePath,
  }) {
    // 1. 优先从系统环境变量读取
    final envValue = Platform.environment[envKey];
    if (envValue != null && envValue.trim().isNotEmpty) {
      return CookieParser.parseCookieHeaderValue(envValue);
    }

    // 2. 尝试从 .env 文件读取
    final dotEnvPath = envFilePath ?? _findEnvFile();
    if (dotEnvPath != null && File(dotEnvPath).existsSync()) {
      final env = DotEnv(includePlatformEnvironment: false)..load([dotEnvPath]);
      final dotEnvValue = env[envKey];
      if (dotEnvValue != null && dotEnvValue.trim().isNotEmpty) {
        return CookieParser.parseCookieHeaderValue(dotEnvValue);
      }
    }

    return '';
  }

  /// 查找 .env 文件，从当前目录向上搜索
  static String? _findEnvFile() {
    var dir = Directory.current;
    for (var i = 0; i < 5; i++) {
      final envFile = File('${dir.path}/.env');
      if (envFile.existsSync()) {
        return envFile.path;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }
}
