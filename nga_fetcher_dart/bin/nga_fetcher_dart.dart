import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:nga_fetcher_dart/nga_fetcher_dart.dart';

const _baseUrl = 'https://bbs.nga.cn';

Future<int> main(List<String> arguments) async {
  final parser = ArgParser();

  parser.addCommand('export-forum')
    ..addOption('fid', defaultsTo: '7')
    ..addOption('cookie-file', defaultsTo: 'nga_cookie.txt')
    ..addOption('out-dir', help: 'Output dir', defaultsTo: 'out/nga_fid7_dart')
    ..addFlag('save-html', defaultsTo: true)
    ..addOption('timeout', defaultsTo: '30');

  parser.addCommand('parse-forum-file')
    ..addOption('in', help: 'Input HTML file path', mandatory: true)
    ..addOption('out-dir', help: 'Output dir', defaultsTo: 'out/nga_forum_offline')
    ..addFlag('save-html', defaultsTo: false);

  parser.addCommand('export-thread')
    ..addOption('tid', help: 'Thread ID', mandatory: true)
    ..addOption('cookie-file', defaultsTo: 'nga_cookie.txt')
    ..addOption('out-dir', help: 'Output dir')
    ..addFlag('save-html', defaultsTo: true)
    ..addOption('timeout', defaultsTo: '30');

  parser.addCommand('reply')
    ..addOption('tid', help: 'Thread ID', mandatory: true)
    ..addOption('fid', help: 'Forum ID', mandatory: true)
    ..addOption('content', help: 'Reply content', mandatory: true)
    ..addOption('cookie-file', defaultsTo: 'nga_cookie.txt')
    ..addOption('timeout', defaultsTo: '30');

  if (arguments.isEmpty || arguments.first == '-h' || arguments.first == '--help') {
    _printUsage(parser);
    return 0;
  }

  final result = parser.parse(arguments);
  final command = result.command;
  if (command == null) {
    _printUsage(parser);
    return 2;
  }

  switch (command.name) {
    case 'export-forum':
      return await _cmdExportForum(command);
    case 'parse-forum-file':
      return await _cmdParseForumFile(command);
    case 'export-thread':
      return await _cmdExportThread(command);
    case 'reply':
      return await _cmdReply(command);
    default:
      _printUsage(parser);
      return 2;
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage:');
  stdout.writeln('  fvm dart run nga_fetcher_dart export-forum [--fid 7]');
  stdout.writeln('  fvm dart run nga_fetcher_dart export-thread --tid <tid>');
  stdout.writeln('  fvm dart run nga_fetcher_dart parse-forum-file --in <file>');
  stdout.writeln(
      '  fvm dart run nga_fetcher_dart reply --tid <tid> --fid <fid> --content <text>');
  stdout.writeln('');
  stdout.writeln('Commands:');
  stdout.writeln(parser.usage);
}

Future<int> _cmdExportForum(ArgResults args) async {
  final fid = int.tryParse(args.option('fid') ?? '7') ?? 7;
  final cookieFile = args.option('cookie-file') ?? 'mvp_nga_fetcher/nga_cookie.txt';
  final outDir = args.option('out-dir') ?? 'out/nga_fid${fid}_dart';
  final saveHtml = args.flag('save-html');
  final timeoutSec = int.tryParse(args.option('timeout') ?? '30') ?? 30;

  final cookieValue = CookieFileParser.loadCookieHeaderValue(cookieFile);
  if (cookieValue.isEmpty) {
    stderr.writeln('ERROR: cookie is empty. Check $cookieFile');
    return 2;
  }

  final url = Uri.parse('$_baseUrl/thread.php?fid=$fid');

  final client = NgaHttpClient();
  try {
    final resp = await client.getBytes(
      url,
      cookieHeaderValue: cookieValue,
      timeout: Duration(seconds: timeoutSec),
    );

    final fetchedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final preview = latin1.decode(resp.bodyBytes.take(4096).toList());
    final htmlText = DecodeBestEffort.decode(
      resp.bodyBytes,
      contentTypeHeader: _headerValue(resp.headers, 'content-type'),
      htmlTextPreview: preview,
    );

    final threads = ForumParser().parseForumThreadList(htmlText);

    final out = Directory(outDir);
    out.createSync(recursive: true);

    final meta = {
      'url': url.toString(),
      'status': resp.statusCode,
      'fetched_at': fetchedAt,
      'thread_count': threads.length,
    };

    _writeJson(File('${out.path}/meta.json'), meta);
    _writeJson(
      File('${out.path}/threads.json'),
      threads.map((t) => t.toJson()).toList(),
    );

    if (saveHtml) {
      File('${out.path}/forum.html').writeAsBytesSync(resp.bodyBytes);
    }

    stdout.writeln('Wrote ${out.path}/threads.json');
    return 0;
  } finally {
    await client.close();
  }
}

Future<int> _cmdParseForumFile(ArgResults args) async {
  final inPath = args.option('in')!;
  final outDir = args.option('out-dir') ?? 'out/nga_forum_offline';
  final saveHtml = args.flag('save-html');

  final bytes = File(inPath).readAsBytesSync();
  final preview = latin1.decode(bytes.take(4096).toList());
  final htmlText = DecodeBestEffort.decode(
    bytes,
    contentTypeHeader: null,
    htmlTextPreview: preview,
  );

  final threads = ForumParser().parseForumThreadList(htmlText);

  final out = Directory(outDir);
  out.createSync(recursive: true);

  final meta = {
    'url': 'file:$inPath',
    'status': 200,
    'fetched_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'thread_count': threads.length,
  };

  _writeJson(File('${out.path}/meta.json'), meta);
  _writeJson(
    File('${out.path}/threads.json'),
    threads.map((t) => t.toJson()).toList(),
  );

  if (saveHtml) {
    File('${out.path}/forum.html').writeAsBytesSync(bytes);
  }

  stdout.writeln('Wrote ${out.path}/threads.json');
  return 0;
}

Future<int> _cmdExportThread(ArgResults args) async {
  final tid = int.parse(args.option('tid')!);
  final cookieFile = args.option('cookie-file') ?? 'mvp_nga_fetcher/nga_cookie.txt';
  final saveHtml = args.flag('save-html');
  final timeoutSec = int.tryParse(args.option('timeout') ?? '30') ?? 30;

  final outDir = args.option('out-dir') ?? 'out/thread_$tid';

  final cookieValue = CookieFileParser.loadCookieHeaderValue(cookieFile);
  if (cookieValue.isEmpty) {
    stderr.writeln('ERROR: cookie is empty. Check $cookieFile');
    return 2;
  }

  final url = Uri.parse('$_baseUrl/read.php?tid=$tid');

  final client = NgaHttpClient();
  try {
    final resp = await client.getBytes(
      url,
      cookieHeaderValue: cookieValue,
      timeout: Duration(seconds: timeoutSec),
    );

    final fetchedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final preview = latin1.decode(resp.bodyBytes.take(4096).toList());
    final htmlText = DecodeBestEffort.decode(
      resp.bodyBytes,
      contentTypeHeader: _headerValue(resp.headers, 'content-type'),
      htmlTextPreview: preview,
    );

    final detail = ThreadParser().parseThreadPage(
      htmlText,
      tid: tid,
      url: url.toString(),
      fetchedAt: fetchedAt,
    );

    final out = Directory(outDir);
    out.createSync(recursive: true);

    _writeJson(File('${out.path}/thread.json'), detail.toJson());
    if (saveHtml) {
      File('${out.path}/thread.html').writeAsBytesSync(resp.bodyBytes);
    }

    stdout.writeln('Wrote ${out.path}/thread.json');
    return 0;
  } finally {
    await client.close();
  }
}

Future<int> _cmdReply(ArgResults args) async {
  final tid = int.parse(args.option('tid')!);
  final fid = int.parse(args.option('fid')!);
  final content = args.option('content') ?? '';
  final cookieFile = args.option('cookie-file') ?? 'mvp_nga_fetcher/nga_cookie.txt';
  final timeoutSec = int.tryParse(args.option('timeout') ?? '30') ?? 30;

  if (content.trim().isEmpty) {
    stderr.writeln('ERROR: content is empty');
    return 2;
  }

  final cookieValue = CookieFileParser.loadCookieHeaderValue(cookieFile);
  if (cookieValue.isEmpty) {
    stderr.writeln('ERROR: cookie is empty. Check $cookieFile');
    return 2;
  }

  final client = NgaHttpClient();
  try {
    final preflightFields = {
      '__output': '3',
      'action': 'reply',
      'fid': '',
      'tid': tid.toString(),
      'pid': '',
      'stid': '',
      'comment': '',
    };

    final preflightBody = formUrlEncodeBytes(preflightFields);
    final preflightResp = await client.postBytes(
      Uri.parse('$_baseUrl/post.php'),
      cookieHeaderValue: cookieValue,
      bodyBytes: preflightBody,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
        'origin': _baseUrl,
        HttpHeaders.refererHeader: '$_baseUrl/read.php?tid=$tid',
      },
      timeout: Duration(seconds: timeoutSec),
    );

    final preflightText = DecodeBestEffort.decode(
      preflightResp.bodyBytes,
      contentTypeHeader: _headerValue(preflightResp.headers, 'content-type'),
      htmlTextPreview: latin1.decode(preflightResp.bodyBytes.take(2048).toList()),
    );

    final preflightResult = _parsePostResult(preflightText, 'preflight');
    if (!preflightResult.isSuccess) {
      _printPostFailure('preflight', preflightResult);
      return 2;
    }

    final postFields = {
      'action': 'reply',
      'fid': fid.toString(),
      'tid': tid.toString(),
      'post_content': content,
      'from_device': 'Nexus 5',
      'from_client': '100',
      'nojump': '1',
      'lite': 'htmljs',
      'step': '2',
    };

    final postBody = formUrlEncodeBytes(postFields);
    final postResp = await client.postBytes(
      Uri.parse('$_baseUrl/post.php'),
      cookieHeaderValue: cookieValue,
      bodyBytes: postBody,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
        'origin': _baseUrl,
        HttpHeaders.refererHeader: '$_baseUrl/read.php?tid=$tid',
      },
      timeout: Duration(seconds: timeoutSec),
    );

    final postText = DecodeBestEffort.decode(
      postResp.bodyBytes,
      contentTypeHeader: _headerValue(postResp.headers, 'content-type'),
      htmlTextPreview: latin1.decode(postResp.bodyBytes.take(2048).toList()),
    );

    final postResult = _parsePostResult(postText, 'submit');
    if (!postResult.isSuccess) {
      _printPostFailure('submit', postResult);
      return 2;
    }

    stdout.writeln(postResult.message ?? '发贴完毕');
    if (postResult.redirectUrl != null) {
      stdout.writeln(postResult.redirectUrl);
    }
    return 0;
  } finally {
    await client.close();
  }
}

String? _headerValue(Map<String, String> headers, String keyLower) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == keyLower) return entry.value;
  }
  return null;
}

PostResponse _parsePostResult(String htmlText, String stage) {
  try {
    return parsePostResponse(htmlText);
  } on FormatException catch (e) {
    stderr.writeln('ERROR: failed to parse $stage response: ${e.message}');
    final end = htmlText.length < 800 ? htmlText.length : 800;
    stderr.writeln(htmlText.substring(0, end));
    return PostResponse(
      code: null,
      status: null,
      message: 'unparseable response',
      detailHtml: null,
      redirectUrl: null,
    );
  }
}

void _printPostFailure(String stage, PostResponse result) {
  final message = result.message ?? 'unknown error';
  stderr.writeln('ERROR: reply $stage failed: $message');
  if (result.detailHtml != null && result.detailHtml!.isNotEmpty) {
    stderr.writeln(result.detailHtml);
  }
}

void _writeJson(File file, Object value) {
  final encoder = const JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(value)}\n');
}
