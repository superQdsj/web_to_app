import 'package:flutter/material.dart';

import '../src/auth/nga_cookie_store.dart';
import '../src/auth/nga_user_store.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NgaCookieStore.loadFromStorage();
  await NgaUserStore.loadFromStorage();
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
      home: const HomeScreen(),
    );
  }
}
