import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../src/auth/nga_cookie_store.dart';

class LoginWebViewSheet extends StatefulWidget {
  const LoginWebViewSheet({super.key});

  @override
  State<LoginWebViewSheet> createState() => _LoginWebViewSheetState();
}

class _LoginWebViewSheetState extends State<LoginWebViewSheet> {
  static final Uri _loginUri = Uri.parse(
    'https://bbs.nga.cn/nuke.php?__lib=login&__act=account&login',
  );

  final _cookieManager = WebviewCookieManager();

  late final WebViewController _controller;

  bool _loading = true;
  String? _currentUrl;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _loading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _loading = false;
              _currentUrl = url;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _error = '${error.errorType}: ${error.description}';
              _loading = false;
            });
          },
        ),
      )
      ..loadRequest(_loginUri);

    if (Platform.isAndroid) {
      // Helps with some login flows that rely on window.open.
      // Not strictly required, but harmless for MVP.
      final androidController = _controller.platform;
      if (androidController is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
      }
    }
  }

  Future<void> _captureCookieAndClose() async {
    setState(() => _error = null);

    try {
      final cookies = await _cookieManager.getCookies(_loginUri.toString());
      final cookieHeaderValue = cookies
          .map((c) => '${c.name}=${c.value}')
          .where((kv) => kv.trim().isNotEmpty)
          .join('; ');

      if (cookieHeaderValue.trim().isEmpty) {
        setState(() {
          _error = 'No cookies found yet. Please finish login first.';
        });
        return;
      }

      if (kDebugMode) {
        debugPrint('=== [NGA] WebView cookie captured (full) ===');
        debugPrint(cookieHeaderValue);
        debugPrint(
          '=== [NGA] WebView cookie captured len=${cookieHeaderValue.length} ===',
        );
      }

      NgaCookieStore.setCookie(cookieHeaderValue);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _reload() async {
    setState(() => _error = null);
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return SafeArea(
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SizedBox(
          height: MediaQuery.of(context).size.height - top,
          child: Column(
            children: [
              _buildTopBar(context),
              if (_error != null) _buildErrorBanner(context),
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_loading)
                      const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
          Expanded(
            child: Text(
              _currentUrl ?? _loginUri.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          IconButton(
            tooltip: 'Reload',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
          FilledButton.tonal(
            onPressed: _captureCookieAndClose,
            child: const Text('Use Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade50,
      child: Text(
        _error!,
        style: TextStyle(color: Colors.red.shade800),
      ),
    );
  }

}
