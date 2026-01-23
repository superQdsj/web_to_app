import 'package:flutter/material.dart';

import '../src/auth/nga_cookie_store.dart';
import '../src/auth/nga_user_store.dart';
import 'home_screen.dart';

/// Splash screen that displays loading indicator while auth state loads.
///
/// This prevents UI flash and ensures auth state loads before main UI renders.
/// Once auth is ready, automatically navigates to HomeScreen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadAuthAndNavigate();
  }

  Future<void> _loadAuthAndNavigate() async {
    // Load both auth stores in parallel
    await Future.wait([
      NgaCookieStore.loadFromStorage(),
      NgaUserStore.loadFromStorage(),
    ]);

    if (!mounted) return;

    // Navigate to HomeScreen, replacing the splash screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // NGA Logo
            Image.network(
              'https://img.ngacn.cc/base/common/logo.png',
              height: 48,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.forum_rounded, size: 48),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
