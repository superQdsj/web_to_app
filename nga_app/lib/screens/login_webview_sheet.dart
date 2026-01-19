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
  bool _detectedLoginCookie = false;
  bool _autoCaptured = false;

  static const Duration _autoCaptureDelay = Duration(milliseconds: 300);

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[NGA][LoginWebView] $message');
  }

  /// NGA 登录关键 Cookie：
  /// - `ngaPassportUid`: 用户 UID
  /// - `ngaPassportCid`: 登录 Token（通常是 `HttpOnly`，JS 读不到）
  ///
  /// 这里用“是否存在上述字段”来判断 WebView 侧是否已完成登录。
  bool _looksLikeLoginCookie(Iterable<Cookie> cookies) {
    final names = cookies.map((c) => c.name).toSet();
    return names.contains('ngaPassportUid') || names.contains('ngaPassportCid');
  }

  String _cookieHeaderFromCookies(Iterable<Cookie> cookies) {
    return cookies
        .map((c) => '${c.name}=${c.value}')
        .where((kv) => kv.trim().isNotEmpty)
        .join('; ');
  }

  /// 将 WebView Cookie 同步到 App（`NgaCookieStore`），并关闭登录页。
  ///
  /// 说明：
  /// - App 内部的 HTTP 请求使用的是 `NgaCookieStore.cookie`，它和 WebView 的 Cookie
  ///   是两套存储；所以即使 WebView 已登录，App 也必须“主动抓取并写入”才能生效。
  Future<void> _applyCookieAndClose({
    required String reason,
    required Iterable<Cookie> cookies,
  }) async {
    if (_autoCaptured) return;

    final cookieHeaderValue = _cookieHeaderFromCookies(cookies);
    if (cookieHeaderValue.trim().isEmpty) return;

    _autoCaptured = true;
    _log('applyCookieAndClose($reason) len=${cookieHeaderValue.length}');
    NgaCookieStore.setCookie(cookieHeaderValue);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<List<Cookie>> _getLoginCookies() async {
    // 注意：这里用 `_loginUri`（bbs.nga.cn）读取 Cookie 是刻意的：
    // 登录流程可能会对多个域名发异步请求来“设置 Cookie”，但最终我们要的登录 Cookie
    // 是挂在 `.nga.cn` 的，这里用主站 URL 读取最稳定。
    return _cookieManager.getCookies(_loginUri.toString());
  }

  /// 仅用于 UI/诊断：探测一次 Cookie 并更新顶部 `Cookie ready` 标识。
  Future<void> _probeCookieReady({required String reason}) async {
    if (!mounted) return;
    try {
      final cookies = await _getLoginCookies();
      final ready = _looksLikeLoginCookie(cookies);
      if (ready && mounted && !_detectedLoginCookie) {
        setState(() => _detectedLoginCookie = true);
      }
      if (kDebugMode) {
        _log(
          'probe($reason) count=${cookies.length} ready=$ready '
          'names=${cookies.map((c) => c.name).toList()}',
        );
      }
    } catch (e) {
      _log('probe($reason) failed: $e');
    }
  }

  /// 尝试自动捕获 Cookie：
  /// - 为什么要延迟：登录成功后，Cookie 往往是通过异步请求写入，立刻读取可能还没落盘；
  /// - 为什么用信号触发：很多登录流程不会产生主页面跳转/刷新，仅靠 `onPageFinished`
  ///   判断会漏掉“Cookie 已写入”的时机。
  Future<void> _tryAutoCapture({
    required String reason,
    Duration delay = _autoCaptureDelay,
  }) async {
    if (!mounted || _autoCaptured) return;

    try {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      final cookies = await _getLoginCookies();
      if (!_looksLikeLoginCookie(cookies)) return;
      await _applyCookieAndClose(reason: reason, cookies: cookies);
    } catch (e) {
      _log('tryAutoCapture($reason) failed: $e');
    }
  }

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
            _probeCookieReady(reason: 'pageFinished');
          },
          onNavigationRequest: (request) {
            // 关键点：NGA 登录常见实现是触发一个“设置 Cookie”的异步请求（iframe/xhr），
            // 此时主页面 URL 可能不变；所以需要在这里抓住信号后主动探测 Cookie。
            if (request.url.contains('login_set_cookie_quick')) {
              _tryAutoCapture(reason: 'loginSetCookieQuick');
            }
            return NavigationDecision.navigate;
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

    // 如果 WebView 里已经存在登录 Cookie（比如上次登录残留），自动关闭并复用。
    _tryAutoCapture(reason: 'init');
  }

  Future<void> _captureCookieAndClose() async {
    setState(() => _error = null);

    try {
      final cookies = await _getLoginCookies();
      if (cookies.isEmpty) {
        setState(() {
          _error = 'No cookies found yet. Please finish login first.';
        });
        return;
      }

      await _applyCookieAndClose(reason: 'manualCapture', cookies: cookies);
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
          if (_detectedLoginCookie)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Cookie ready',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
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
