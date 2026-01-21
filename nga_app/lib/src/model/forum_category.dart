import 'package:flutter/foundation.dart' show debugPrint;

/// 板块信息
class ForumBoard {
  final int fid;
  final String name;
  final String? info;
  final int? stid;

  const ForumBoard({
    required this.fid,
    required this.name,
    this.info,
    this.stid,
  });

  factory ForumBoard.fromJson(Map<String, dynamic> json) {
    try {
      final board = ForumBoard(
        fid: _parseRequiredInt(json['fid']),
        name: _parseRequiredString(json['name']),
        info: _parseNullableString(json['info']),
        stid: _parseNullableInt(json['stid']),
      );
      return board;
    } catch (e, stackTrace) {
      debugPrint('[ForumBoard.fromJson] ERROR parsing board: $e');
      debugPrint('[ForumBoard.fromJson] JSON data: $json');
      debugPrint('[ForumBoard.fromJson] StackTrace: $stackTrace');
      rethrow;
    }
  }
}

/// 子分类
class ForumSubcategory {
  final String name;
  final List<ForumBoard> boards;

  const ForumSubcategory({required this.name, required this.boards});

  factory ForumSubcategory.fromJson(Map<String, dynamic> json) {
    try {
      final subcategory = ForumSubcategory(
        name: _parseRequiredString(json['name']),
        boards: (json['boards'] as List<dynamic>)
            .map((e) => ForumBoard.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return subcategory;
    } catch (e, stackTrace) {
      debugPrint('[ForumSubcategory.fromJson] ERROR parsing subcategory: $e');
      debugPrint('[ForumSubcategory.fromJson] JSON data: $json');
      debugPrint('[ForumSubcategory.fromJson] StackTrace: $stackTrace');
      rethrow;
    }
  }
}

/// 分类
class ForumCategory {
  final String id;
  final String name;
  final String icon;
  final List<ForumSubcategory> subcategories;

  const ForumCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.subcategories,
  });

  factory ForumCategory.fromJson(Map<String, dynamic> json) {
    try {
      final category = ForumCategory(
        id: _parseRequiredString(json['id']),
        name: _parseRequiredString(json['name']),
        icon: _parseRequiredString(json['icon']),
        subcategories: (json['subcategories'] as List<dynamic>)
            .map((e) => ForumSubcategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return category;
    } catch (e, stackTrace) {
      debugPrint('[ForumCategory.fromJson] ERROR parsing category: $e');
      debugPrint('[ForumCategory.fromJson] JSON data: $json');
      debugPrint('[ForumCategory.fromJson] StackTrace: $stackTrace');
      rethrow;
    }
  }
}

/// 解析必需的整数值，支持 int、num、String 类型
int _parseRequiredInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  debugPrint(
    '[_parseRequiredInt] Invalid int value: $value (type: ${value.runtimeType})',
  );
  throw FormatException(
    'Invalid int value: $value (type: ${value.runtimeType})',
  );
}

/// 解析可选的整数值
int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  debugPrint(
    '[_parseNullableInt] Unexpected type for nullable int: $value (type: ${value.runtimeType})',
  );
  return null;
}

/// 解析必需的字符串值，支持任意类型转换为字符串
String _parseRequiredString(dynamic value) {
  if (value == null) {
    debugPrint('[_parseRequiredString] Received null for required string');
    throw const FormatException('Required string value is null');
  }
  if (value is String) {
    return value;
  }
  // 将其他类型（如 int）转换为字符串
  return value.toString();
}

/// 解析可选的字符串值
String? _parseNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  // 将其他类型（如 int）转换为字符串
  return value.toString();
}
