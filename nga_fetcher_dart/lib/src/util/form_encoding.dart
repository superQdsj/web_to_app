import 'dart:convert';

import 'package:charset/charset.dart';

List<int> formUrlEncodeBytes(
  Map<String, String> fields, {
  String charsetName = 'gb18030',
}) {
  final encoder = Charset.getByName(charsetName) ?? gbk;
  final buffer = StringBuffer();
  var first = true;

  for (final entry in fields.entries) {
    if (!first) buffer.write('&');
    first = false;
    buffer.write(_encodeComponent(entry.key, encoder));
    buffer.write('=');
    buffer.write(_encodeComponent(entry.value, encoder));
  }

  return ascii.encode(buffer.toString());
}

String _encodeComponent(String value, Encoding encoder) {
  final bytes = encoder.encode(value);
  final buffer = StringBuffer();

  for (final b in bytes) {
    if (b == 0x20) {
      buffer.write('+');
      continue;
    }

    if (_isUnreserved(b)) {
      buffer.writeCharCode(b);
    } else {
      buffer.write('%');
      buffer.write(_hexUpper(b >> 4));
      buffer.write(_hexUpper(b & 0x0f));
    }
  }

  return buffer.toString();
}

bool _isUnreserved(int b) {
  return (b >= 0x30 && b <= 0x39) ||
      (b >= 0x41 && b <= 0x5a) ||
      (b >= 0x61 && b <= 0x7a) ||
      b == 0x2d ||
      b == 0x5f ||
      b == 0x2e ||
      b == 0x2a;
}

String _hexUpper(int nibble) {
  const digits = '0123456789ABCDEF';
  return digits[nibble & 0x0f];
}
