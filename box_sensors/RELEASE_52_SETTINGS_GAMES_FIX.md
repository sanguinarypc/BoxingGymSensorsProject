# Settings/Games repair after Play build 52

## Confirmed cause

The supplied Play AAB at `build/app/outputs/bundle/release/app-release.aab`
was preserved as `artifacts/settings-games-fix/play-release-52.aab` before
rebuilding. Its SHA-256 is
`ECBBFC8A6D66E155645AB6541D0F809DEEE141E180DD0868C70FE8344BD268F5`.

Its Dart library contains the old `dev.flutter.pigeon.path_provider_android`
channel and `path_provider_android/messages.g.dart`. Its native DEX contains
`JniFlutterPlugin` but no corresponding path-provider Pigeon channel. This is
a mixed Dart/native plugin build. The exact reason the previous build reused
stale Dart output cannot be established from the binary alone.

Google bundletool 1.18.3 converted that original AAB to an APK, which reproduced
both reported failures on an Android API 35 emulator:

- Games: `PlatformException(channel-error, Unable to establish connection on
  channel: "dev.flutter.pigeon.path_provider_android.PathProviderApi.getApplicationDocumentsPath"...)`.
- Settings: `Failed to load settings.` and initial field defaults instead of
  saved database settings.

Both screens open `messages.db` through `getApplicationDocumentsDirectory()`.
Failure happens before SQLite reads. The empty-games message remains in the
existing screen code; it was unreachable because loading failed.

## Final repair

- Explicitly pin `path_provider_android: 2.3.1`, the latest published Android
  implementation at the time of this repair. It uses JNI and fixes the release
  `PathUtils` class-loading issue present in 2.3.0.
- Run `flutter clean`, `flutter pub get`, then rebuild release APK/AAB so that
  Dart, generated registration and native dependencies agree.
- Keep `messages.db` in the same Android documents directory (`app_flutter`),
  with the same database schema/version and screen behavior.
- Add `scripts/verify_path_provider_release.ps1` to check the final artifact
  for stale Pigeon code and missing native JNI registration. The script rejects
  the original Play AAB and passes the repaired APK/AAB on all three ABI libraries.

No changes to Settings, Games, DatabaseHelper, MainActivity or BLE application
logic remain from this repair. The Sentry 10 migration is documented separately
in `SENTRY_MIGRATION.md`.

## Runtime verification

Verified on the API 35 emulator with R8 enabled:

1. Save sensitivity `850` and insert eight sample games in a working release.
2. Install the original Play 52 AAB-derived APK as an update; reproduce both errors.
3. Install the clean JNI 2.3.1 release as an update without clearing data.
   Sensitivity `850` and all eight game names load unchanged.
4. After that preservation check, reset only the synthetic emulator test data.
   Install an APK generated from the repaired AAB. Settings load database
   defaults (including rounds `3`), and Games show the original empty message.

UI dumps and screenshots are in `artifacts/settings-games-fix/` (ignored by Git).
The Flutter analyzer reports no issues in `lib`/`test`; all seven existing tests pass.
Physical devices and the Play-distributed update still require rollout verification.
The final AAB was rebuilt as versionName `1.0.53`, versionCode `53`, with the
same repaired source and passed the artifact guard on all three ABIs. It has
not been uploaded to Play. These verification builds do not pass a Sentry DSN;
use the project's existing Sentry build configuration when enabling telemetry.

## Build the next Play candidate

```powershell
flutter clean
flutter pub get
flutter build appbundle --release --no-pub --build-name=1.0.53 --build-number=53
./scripts/verify_path_provider_release.ps1 -ArtifactPath build/app/outputs/bundle/release/app-release.aab
```

Build 53 uses command-line version overrides; `pubspec.yaml`'s base version is
unchanged. Verify the actual final package after every dependency change.
Do not reuse Play's already published versionCode 52 for a new upload.

Source: https://pub.dev/packages/path_provider_android/changelog
