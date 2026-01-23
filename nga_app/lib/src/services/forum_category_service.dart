import 'dart:convert';
import 'package:flutter/foundation.dart' show compute, debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../model/forum_category.dart';

// Top-level function for Isolate parsing
List<ForumCategory> _parseCategories(String jsonString) {
  final json = jsonDecode(jsonString) as Map<String, dynamic>;
  return (json['categories'] as List<dynamic>)
      .map((e) => ForumCategory.fromJson(e as Map<String, dynamic>))
      .toList();
}

class ForumCategoryService {
  static List<ForumCategory>? _cachedCategories;

  /// 加载所有板块分类
  static Future<List<ForumCategory>> loadCategories() async {
    if (_cachedCategories != null) {
      if (kDebugMode) {
        debugPrint(
          '[ForumCategoryService] Returning cached categories (${_cachedCategories!.length} items)',
        );
      }
      return _cachedCategories!;
    }

    try {
      if (kDebugMode) {
        debugPrint('[ForumCategoryService] Loading categories from assets...');
      }

      final jsonString = await rootBundle.loadString(
        'assets/data/forum_categories_merged.json',
      );

      if (kDebugMode) {
        debugPrint(
          '[ForumCategoryService] JSON loaded, length: ${jsonString.length} chars',
        );
      }

      // Parse in background isolate to avoid blocking UI
      final categories = await compute(_parseCategories, jsonString);

      if (kDebugMode) {
        debugPrint(
          '[ForumCategoryService] Successfully parsed ${categories.length} categories',
        );
        for (final cat in categories) {
          debugPrint(
            '[ForumCategoryService]   - ${cat.name}: ${cat.subcategories.length} subcategories',
          );
        }
      }

      _cachedCategories = categories;
      return categories;
    } catch (e, stackTrace) {
      debugPrint('[ForumCategoryService] ERROR loading categories: $e');
      debugPrint('[ForumCategoryService] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 获取图标（根据字符串名称）
  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'gamepad':
        return Icons.gamepad_rounded;
      case 'videogame_asset':
        return Icons.videogame_asset_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
}
