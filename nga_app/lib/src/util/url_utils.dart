int? tryParseInt(String? s) {
  if (s == null) return null;
  final trimmed = s.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}

Uri resolveNgaUrl(String href, {String base = 'https://bbs.nga.cn'}) {
  final trimmed = href.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Uri.parse(trimmed);
  }

  if (!trimmed.startsWith('/')) {
    return Uri.parse(base).resolve('/$trimmed');
  }
  return Uri.parse(base).resolve(trimmed);
}

int? extractTidFromReadHref(String href) {
  final uri = Uri.tryParse(resolveNgaUrl(href).toString());
  if (uri == null) return null;
  final tid = uri.queryParameters['tid'];
  return int.tryParse(tid ?? '');
}

int? extractUidFromHref(String href) {
  final uri = Uri.tryParse(resolveNgaUrl(href).toString());
  if (uri == null) return null;
  final uid = uri.queryParameters['uid'];
  return int.tryParse(uid ?? '');
}
