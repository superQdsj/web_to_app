# Technology Stack

**Analysis Date:** 2026-01-23

## Languages

**Primary:**
- Dart 3.10.7+ - Used for all application code (Flutter framework)

**Secondary:**
- YAML - Used for configuration (pubspec.yaml, analysis_options.yaml)

## Runtime

**Environment:**
- Flutter SDK (managed via FVM - Flutter Version Management)
- Platform targets: iOS (webview_flutter_android for Android compatibility)

**Package Manager:**
- Dart Pub (via `flutter pub get`)
- Lockfile: `pubspec.lock` (committed to version control)

## Frameworks

**Core:**
- Flutter 3.24+ - Mobile UI framework
- Material Design 3 - UI components and design system

**Testing:**
- flutter_test - Built-in Flutter testing framework
- WidgetTester API - For widget testing

**Build/Dev:**
- flutter_lints 6.0.0 - Code linting rules
- dart format - Code formatting

## Key Dependencies

**HTTP & Networking:**
- http 1.6.0 - HTTP client for API requests
- webview_flutter 4.13.1 - WebView for login flow
- webview_flutter_android 4.7.0 - Android-specific WebView implementation
- webview_flutter_platform_interface 2.13.0 - WebView abstraction layer

**Data & Parsing:**
- html 0.15.6 - HTML parsing for forum content
- charset 2.0.1 - Character encoding detection (GB18030, GBK, UTF-8)

**Storage:**
- shared_preferences 2.5.4 - Persistent key-value storage for cookies and user info

**UI Icons:**
- cupertino_icons 1.0.8 - iOS-style icons

## Configuration

**Environment:**
- No .env file - No external environment variable configuration detected
- Configuration hardcoded in source files

**Build:**
- `pubspec.yaml` - Flutter project configuration
- `analysis_options.yaml` - Dart analyzer configuration (extends flutter.yaml)

**Code Style:**
- flutter_lints recommended rules enabled
- Single quotes preferred but not enforced
- print statements allowed (avoid_print disabled)

## Platform Requirements

**Development:**
- Flutter SDK (version managed via FVM)
- Dart SDK ^3.10.7
- Android Studio / VS Code (recommended IDEs)

**Production:**
- iOS 11.0+ (minimum deployment target)
- Android API 21+ (implicit via Flutter)
- WebView support on target platforms

---

*Stack analysis: 2026-01-23*
