# Sentry 10.0.0 migration

The app pins `sentry_flutter` to 10.0.0. `flutter pub get` also resolves
`sentry` 10.0.0, `jni` 1.0.3 and `jni_util` 1.0.0. `sentry_logging` is not used
and has not been added. The subsequent Settings/Games repair explicitly pins
`path_provider_android` 2.3.1 and uses `jni_flutter` 1.0.3.

## Preserved application behavior

- DSN selection via `--dart-define` and environment selection are unchanged.
- A missing DSN still disables Sentry; the existing initialization fallback remains.
- `sendDefaultPii` remains false, tracing sampling remains 0.1, and both
  automatic Replay sampling rates remain 0.0.
- `traceLifecycle = SentryTraceLifecycle.static` retains the Sentry 9
  transaction lifecycle instead of adopting the new streaming default.
- `captureNativeFailedRequests = true` retains the previous native HTTP error
  capture default (previously inherited from `captureFailedRequests = true`).
- Bluetooth, permissions, match processing, storage, themes and UI logic have
  not been changed by this migration.

Sentry 10 itself changes some telemetry behavior: app-start tracing is now a
standalone root, logs/metrics are always enabled in the SDK, and release-health
reporting changes. The app does not call Sentry logs/metrics APIs or install the
logging integration. These SDK changes are not changes to match/sensor logic.

## Platform requirements

- Sentry requires Flutter >=3.44.0 and Dart >=3.12.0. The project's existing
  stricter constraints and installed Flutter 3.47.7 / Dart 3.13.5 satisfy these.
- Android requires API 26 (Android 8.0). `minSdk` now uses the larger of 26 and
  Flutter's default; Android 7.x devices are no longer supported.
- The shipped Sentry Swift package requires iOS 15 and macOS 12. All existing
  deployment-target declarations and the iOS app framework minimum match these.
- Swift Package Manager is explicitly enabled in the project's `flutter.config`.
  Sentry 10 no longer supports CocoaPods. Flutter can still use CocoaPods for
  other plugins that require it.

## Validation and remaining device checks

The seven existing Flutter tests pass both before and after the upgrade.
`flutter analyze --no-pub lib test` reports no issues after the upgrade.
`flutter build apk --debug --no-pub` successfully builds the Android APK with
the Sentry 10 native plugin and JNI 1.0.3.

On a Mac, run `flutter pub get`, then `flutter build ios --no-codesign` and
`flutter build macos`. Flutter automatically migrates the Xcode projects to
SwiftPM during the first Apple build. Commit the resulting Xcode project/scheme
changes after verifying those builds. Apple builds cannot be verified on Windows.

Before distribution, exercise sensor connection/reconnection, match recording,
saved data and themes on a physical Android device. With a test-project DSN
provided via `--dart-define=SENTRY_DSN=...`, verify receipt of a controlled test
exception in Sentry. Compile/tests alone do not verify native crash reporting
or delivery to the Sentry service.

## References

- https://pub.dev/packages/sentry_flutter/versions/10.0.0
- https://pub.dev/packages/sentry_logging/changelog
- https://docs.sentry.io/platforms/dart/guides/flutter/migration/v9-to-v10/
- https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers
- Sentry 10's `darwin/sentry_flutter/Package.swift` in the resolved pub cache.
