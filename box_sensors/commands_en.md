# Package upgrade & release commands – Box Sensors

Run all commands from the project root (`C:\BoxingGymSensorsProject\box_sensors`) in PowerShell.

---

## 1. Check the environment (optional)

```powershell
flutter doctor -v
```
Checks that the Flutter SDK, Android SDK/toolchain, Java and connected devices are set up correctly. Run it when something won't build or after upgrading Flutter.

---

## 2. Check for newer package versions

```powershell
flutter pub outdated
```
Shows, for each package, the current version (**Current**), the version it can move to without editing `pubspec.yaml` (**Upgradable**) and the newest version available (**Latest**). It changes nothing; it only reports.

---

## 3. Upgrade packages (pick ONE of the two)

### 3a. Upgrade the lock file only

```powershell
flutter pub upgrade
```
Upgrades packages to the newest versions allowed by the `^` constraints in `pubspec.yaml`. It changes **only** `pubspec.lock`; the numbers in `pubspec.yaml` stay the same.

### 3b. Upgrade and update the YAML (recommended)

```powershell
flutter pub upgrade --tighten
```
Does everything 3a does **and** writes the new versions into `pubspec.yaml` (e.g. `^10.3.0` → `^10.5.0`), so the YAML shows the versions actually in use. Comments are kept.

> Neither command performs a major upgrade (e.g. 13.x → 14.x). That is done by hand or with `flutter pub upgrade --major-versions`, and it may break code.

---

## 4. Review what changed

```powershell
git diff pubspec.yaml
```
Shows line by line what changed in `pubspec.yaml`. Confirm that only version numbers changed.

```powershell
flutter pub deps --style=compact
```
(Optional) Shows which package pulls in which. Useful for finding out why a package won't upgrade.

---

## 5. Static analysis

```powershell
flutter analyze
```
Analyzes the code for errors, warnings and deprecated APIs the new versions may have introduced. It should report `No issues found!` before you continue.

---

## 6. Tests

```powershell
flutter test
```
Runs the tests in the `test/` folder. Fix any failure before building.

---

## 7. Clean and re-fetch packages

```powershell
flutter clean
flutter pub get
```
- `flutter clean`: deletes the `build/` and `.dart_tool/` folders so Gradle does not keep stale native pieces (e.g. from `sentry`, `file_picker`).
- `flutter pub get`: re-downloads packages exactly as listed in `pubspec.lock` (it upgrades nothing).

---

## 8. Bump the app version (if releasing)

In `pubspec.yaml`, edit the line by hand:

```yaml
version: 1.0.54+54   →   version: 1.0.55+55
```
The first part (`1.0.55`) is the `versionName` users see. The second part (`+55`) is the `versionCode`, which must increase with every Google Play upload.

---

## 9. Test on the phone

```powershell
flutter run --release
```
Builds and installs the app in release mode on the connected device. Test:
- connecting to the BLE sensors,
- picking a file (`file_picker`),
- that errors reach Sentry.

---

## 10. Release build

```powershell
.\full_release_build.ps1
```
Your own script for a full release build (preferred).

or directly:

```powershell
flutter build appbundle --release
```
Builds the `.aab` for Google Play, in `build\app\outputs\bundle\release\`.

---

## 11. Commit

```powershell
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): upgrade sentry_flutter, file_picker, flutter_dotenv, material_ui"
```
- `git add`: stages the two files for the next commit.
- `git commit`: saves the changes to git history with a descriptive message. Adjust the message to the packages that were upgraded (and mention `version` if you changed it in step 8).

---

## Quick sequence (copy-paste)

```powershell
flutter pub outdated
flutter pub upgrade --tighten
git diff pubspec.yaml
flutter analyze
flutter test
flutter clean
flutter pub get
flutter run --release
.\full_release_build.ps1
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): upgrade dependencies"
```
