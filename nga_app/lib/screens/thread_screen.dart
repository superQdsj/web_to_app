import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/nga_fetcher.dart';

import '../data/nga_repository.dart';
import '../src/auth/nga_cookie_store.dart';

part 'thread/thread_body.dart';
part 'thread/thread_palette.dart';
part 'thread/thread_post_widgets.dart';
part 'thread/thread_reply_composer.dart';
part 'thread/thread_reply_widgets.dart';
part 'thread/thread_user_avatar.dart';

/// Thread detail screen.
///
/// Displays the posts (first page) of a thread.
class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    required this.tid,
    this.title,
  });

  final int tid;
  final String? title;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  ThreadDetail? _detail;
  bool _loading = true;
  String? _error;

  late NgaRepository _repository;

  String get _cookie => NgaCookieStore.cookie.value;

  @override
  void initState() {
    super.initState();
    _repository = NgaRepository(cookie: _cookie);
    NgaCookieStore.cookie.addListener(_onCookieChanged);
    _fetchThread();
  }

  void _onCookieChanged() {
    _repository.close();
    _repository = NgaRepository(cookie: _cookie);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    NgaCookieStore.cookie.removeListener(_onCookieChanged);
    _repository.close();
    super.dispose();
  }

  Future<void> _fetchThread() async {
    if (!NgaCookieStore.hasCookie) {
      setState(() {
        _error = 'Cookie not configured.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    if (kDebugMode) {
      debugPrint('=== [NGA] Fetch thread cookie len=${_cookie.length} ===');
      debugPrint(
        '=== [NGA] Fetch thread cookie cookies: '
        '${NgaCookieStore.summarizeCookieHeader(_cookie)} ===',
      );
    }

    try {
      final detail = await _repository.fetchThread(widget.tid);

      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ThreadPalette.backgroundLight,
      appBar: AppBar(
        backgroundColor: _ThreadPalette.backgroundLight,
        surfaceTintColor: _ThreadPalette.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: const Border(
          bottom: BorderSide(color: _ThreadPalette.borderLight),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new),
          color: _ThreadPalette.textPrimary,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(
          widget.title ?? 'Post Details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ThreadPalette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            color: _ThreadPalette.textPrimary,
            tooltip: 'More',
          ),
        ],
      ),
      body: _ThreadBody(
        loading: _loading,
        error: _error,
        detail: _detail,
        onRefresh: _fetchThread,
      ),
      bottomNavigationBar: const _ReplyComposer(),
    );
  }
}
