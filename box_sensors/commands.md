# Εντολές αναβάθμισης πακέτων & release – Box Sensors

Όλες οι εντολές τρέχουν από το root του project (`C:\BoxingGymSensorsProject\box_sensors`) σε PowerShell.

---

## 1. Έλεγχος περιβάλλοντος (προαιρετικό)

```powershell
flutter doctor -v
```
Ελέγχει ότι το Flutter SDK, το Android SDK/toolchain, η Java και οι συσκευές είναι σωστά εγκατεστημένα. Τρέξ' το αν κάτι δεν χτίζει ή μετά από αναβάθμιση του Flutter.

---

## 2. Έλεγχος για νεότερες εκδόσεις πακέτων

```powershell
flutter pub outdated
```
Δείχνει για κάθε πακέτο την τρέχουσα έκδοση (**Current**), αυτή που μπορεί να πάρει χωρίς αλλαγή στο `pubspec.yaml` (**Upgradable**) και την πιο πρόσφατη που υπάρχει (**Latest**). Δεν αλλάζει τίποτα, απλώς ενημερώνει.

---

## 3. Αναβάθμιση πακέτων (διάλεξε ΜΙΑ από τις δύο)

### 3α. Αναβάθμιση μόνο του lock

```powershell
flutter pub upgrade
```
Αναβαθμίζει τα πακέτα στις νεότερες εκδόσεις που επιτρέπουν τα όρια (`^`) του `pubspec.yaml`. Αλλάζει **μόνο** το `pubspec.lock`. Οι αριθμοί στο `pubspec.yaml` μένουν ίδιοι.

### 3β. Αναβάθμιση και ενημέρωση του YAML (προτεινόμενο)

```powershell
flutter pub upgrade --tighten
```
Κάνει ό,τι και το 3α και **επιπλέον** γράφει τις νέες εκδόσεις στο `pubspec.yaml` (π.χ. `^10.3.0` → `^10.5.0`). Έτσι το YAML δείχνει τις εκδόσεις που χρησιμοποιούνται πραγματικά. Τα σχόλια μένουν.

> Κανένα από τα δύο **δεν** κάνει major αναβάθμιση (π.χ. 13.x → 14.x). Αυτή γίνεται χειροκίνητα ή με `flutter pub upgrade --major-versions` και μπορεί να σπάσει κώδικα.

---

## 4. Έλεγχος του τι άλλαξε

```powershell
git diff pubspec.yaml
```
Δείχνει γραμμή-γραμμή τι άλλαξε στο `pubspec.yaml`. Επιβεβαίωσε ότι άλλαξαν μόνο οι αριθμοί εκδόσεων.

```powershell
flutter pub deps --style=compact
```
(Προαιρετικό) Δείχνει ποιο πακέτο φέρνει ποιο. Χρήσιμο για να καταλάβεις γιατί ένα πακέτο δεν αναβαθμίζεται.

---

## 5. Έλεγχος κώδικα

```powershell
flutter analyze
```
Στατικός έλεγχος του κώδικα. Βρίσκει σφάλματα, warnings και deprecated APIs που μπορεί να έφεραν οι νέες εκδόσεις. Πρέπει να βγάλει `No issues found!` πριν προχωρήσεις.

---

## 6. Tests

```powershell
flutter test
```
Τρέχει τα tests του φακέλου `test/`. Αν κάποιο αποτύχει, φτιάξ' το πριν το build.

---

## 7. Καθάρισμα και ξανά κατέβασμα πακέτων

```powershell
flutter clean
flutter pub get
```
- `flutter clean`: σβήνει τους φακέλους `build/` και `.dart_tool/`, ώστε το Gradle να μην κρατάει παλιά native κομμάτια (π.χ. από `sentry`, `file_picker`).
- `flutter pub get`: ξανακατεβάζει τα πακέτα ακριβώς όπως γράφει το `pubspec.lock` (δεν αναβαθμίζει τίποτα).

---

## 8. Αλλαγή έκδοσης εφαρμογής (αν θα βγει νέο release)

Στο `pubspec.yaml` άλλαξε με το χέρι τη γραμμή:

```yaml
version: 1.0.54+54   →   version: 1.0.55+55
```
Το πρώτο κομμάτι (`1.0.55`) είναι το `versionName` που βλέπει ο χρήστης. Το δεύτερο (`+55`) είναι το `versionCode` και πρέπει να μεγαλώνει σε κάθε ανέβασμα στο Google Play.

---

## 9. Δοκιμή στο κινητό

```powershell
flutter run --release
```
Χτίζει και εγκαθιστά την εφαρμογή σε release mode στη συνδεδεμένη συσκευή. Δοκίμασε:
- σύνδεση με τους αισθητήρες BLE,
- επιλογή αρχείου (`file_picker`),
- ότι τα σφάλματα φτάνουν στο Sentry.

---

## 10. Release build

```powershell
.\full_release_build.ps1
```
Το δικό σου script για πλήρες release build (προτιμότερο).

ή απευθείας:

```powershell
flutter build appbundle --release
```
Φτιάχνει το `.aab` για το Google Play, στο `build\app\outputs\bundle\release\`.

---

## 11. Commit

```powershell
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): upgrade sentry_flutter, file_picker, flutter_dotenv, material_ui"
```
- `git add`: βάζει τα δύο αρχεία στο επόμενο commit.
- `git commit`: αποθηκεύει τις αλλαγές στο ιστορικό του git με περιγραφικό μήνυμα. Άλλαξε το μήνυμα ανάλογα με τα πακέτα που αναβαθμίστηκαν (και πρόσθεσε `version` αν άλλαξε στο βήμα 8).

---

## Σύντομη σειρά (copy-paste)

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
