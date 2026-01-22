# Technology Stack

**Analysis Date:** 2026-01-23

## Languages

**Primary:**
- Dart 3.10+ - All application code (screens, services, models, utilities)

## Runtime

**Framework:**
- Flutter 3.x (via FVM) - Cross-platform mobile framework
- Platform targets: iOS, Android

**Package Manager:**
- pub (Dart package manager)
- Lockfile: `pubspec.lock`

## Core Dependencies

**Flutter Framework:**
- `flutter sdk: flutter` - Core Flutter framework
- `cupertino_icons: ^1.0.8` - iOS-style icons

**HTTP & Networking:**
- `http: ^1.6.0` - HTTP client for API requests
- `html: ^0.15.6` - HTML parsing (used for forum content parsing)

**WebView & Cookies:**
- `webview_flutter: ^4.13.1` - WebView widget for login flow
- `webview_flutter_android: ^4.7.0` - Android WebView implementation
- `webview_flutter_platform_interface: ^2.13.0` - WebView abstraction layer
- `webview_cookie_manager_plus: ^2.0.17` - Cookie management for WebView

**Storage:**
- `shared_preferences: ^2.5.4` - Persistent key-value storage for cookies and user info

**Encoding:**
- `charset: ^2.0.1` - Character set encoding utilities (GBK handling for NGA)

## Dev Dependencies

**Testing:**
- `flutter_test sdk: flutter` - Flutter testing framework
- `flutter_lints: ^6.0.0` - Recommended lint rules

## Configuration

**Linting:**
- `analysis_options.yaml` - Uses `flutter_lints/flutter.yaml`
- Config: `/Users/xialiqun/Desktop/nga_mobile/web_to_app/nga_app/analysis_options.yaml`

**Build Configuration:**
- Android: `android/build.gradle.kts` (Gradle Kotlin DSL)
- iOS: `ios/Podfile` (CocoaPods)

**Flutter SDK Version:**
- Managed via FVM (Flutter Version Management)
- Version specified in `.fvm/flutter_sdk`

## Platform Requirements

**Development:**
- Flutter SDK (via FVM)
- Dart SDK ^3.10.7
- Android Studio / VS Code (recommended)
- CocoaPods (for iOS)
- Gradle (for Android)

**Production:**
- iOS 12.0+ (minimum from Flutter default)
- Android API 21+ (Android 5.0+)

---

*Stack analysis: 2026-01-23*
