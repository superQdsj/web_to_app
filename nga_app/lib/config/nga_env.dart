/// Compile-time environment configuration for NGA app.
///
/// Cookie is injected via `--dart-define-from-file` at build time.
/// Example usage:
///   fvm flutter run --dart-define-from-file=../private/nga_cookie.json
///
/// The JSON file should contain:
///   { "NGA_COOKIE": "ngaPassportUid=...; ngaPassportToken=...; ..." }
class NgaEnv {
  NgaEnv._();

  /// NGA cookie value injected at compile time.
  /// Empty string if not provided.
  static const String cookie = String.fromEnvironment('NGA_COOKIE');

  /// Whether a valid cookie is available.
  static bool get hasCookie => cookie.trim().isNotEmpty;
}
