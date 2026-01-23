import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'src/services/forum_category_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget pre-load to warm cache before drawer opens
  ForumCategoryService.loadCategories();
  runApp(const NgaApp());
}

class NgaApp extends StatelessWidget {
  const NgaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NGA Forum',
      theme: NgaTheme.light,
      darkTheme: NgaTheme.dark,
      themeMode: ThemeMode.system, // 跟随系统设置
      home: const SplashScreen(),
    );
  }
}
