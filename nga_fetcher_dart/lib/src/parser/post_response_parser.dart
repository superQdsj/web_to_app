import 'dart:convert';

class PostResponse {
  PostResponse({
    required this.code,
    required this.status,
    required this.message,
    required this.detailHtml,
    required this.redirectUrl,
  });

  final int? code;
  final int? status;
  final String? message;
  final String? detailHtml;
  final String? redirectUrl;

  bool get isSuccess => (status ?? 0) == 200 && (code ?? 0) == 0;
}

PostResponse parsePostResponse(String htmlText) {
  const marker = 'window.script_muti_get_var_store';
  final idx = htmlText.indexOf(marker);
  if (idx < 0) {
    throw const FormatException('missing script_muti_get_var_store');
  }

  final braceStart = htmlText.indexOf('{', idx);
  if (braceStart < 0) {
    throw const FormatException('missing json payload');
  }

  final payload = _extractJsonObject(htmlText, braceStart);
  final decoded = jsonDecode(payload);
  if (decoded is! Map) {
    throw const FormatException('unexpected payload');
  }

  final data = decoded['data'];
  if (data is! Map) {
    throw const FormatException('missing data');
  }

  // Step=2 responses usually include data.__MESSAGE.
  final message = data['__MESSAGE'];
  if (message is Map) {
    return PostResponse(
      code: _tryParseInt(message['0']),
      message: _tryParseString(message['1']),
      detailHtml: _tryParseString(message['2']),
      status: _tryParseInt(message['3']),
      redirectUrl: _tryParseString(message['6']),
    );
  }

  // Step=1 (preflight) successful responses often omit __MESSAGE.
  // When there's an error, NGA usually includes decoded.error and/or data.__MESSAGE.
  final error = decoded['error'];
  if (error is Map) {
    final messageText = _tryParseString(error['0']) ?? _tryParseString(error['1']);
    final detail = _tryParseString(error['1']);
    if (messageText != null && messageText.isNotEmpty) {
      return PostResponse(
        code: null,
        status: 403,
        message: messageText,
        detailHtml: detail,
        redirectUrl: null,
      );
    }
  }

  return PostResponse(
    code: 0,
    status: 200,
    message: null,
    detailHtml: null,
    redirectUrl: null,
  );
}

String _extractJsonObject(String text, int start) {
  var depth = 0;
  var inString = false;
  var escape = false;

  for (var i = start; i < text.length; i += 1) {
    final ch = text.codeUnitAt(i);

    if (inString) {
      if (escape) {
        escape = false;
      } else if (ch == 0x5c) {
        escape = true;
      } else if (ch == 0x22) {
        inString = false;
      }
      continue;
    }

    if (ch == 0x22) {
      inString = true;
      continue;
    }

    if (ch == 0x7b) {
      depth += 1;
      continue;
    }

    if (ch == 0x7d) {
      depth -= 1;
      if (depth == 0) {
        return text.substring(start, i + 1);
      }
    }
  }

  throw const FormatException('unterminated json payload');
}

int? _tryParseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _tryParseString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
