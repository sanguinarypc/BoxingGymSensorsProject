import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class BlePermissions {
  /// Ζητά τα σωστά permissions για BLE.
  /// 1) Προσπαθεί Android 12+ (SCAN/CONNECT) χωρίς location
  /// 2) Αν αποτύχει, κάνει fallback σε location (Android ≤ 11)
  static Future<bool> ensure() async {
    if (!Platform.isAndroid) return true;

    // --- Προσπάθεια #1: Android 12+ μονοπάτι (χωρίς location) ---
    final modernStatuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      // Αν κάνεις και advertising, ξεκλείδωσε το παρακάτω:
      // Permission.bluetoothAdvertise,
    ].request();

    final scanOk = modernStatuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectOk = modernStatuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final modernOk = scanOk && connectOk;
    if (modernOk) return true;

    // --- Προσπάθεια #2: Fallback για Android 11 και κάτω (ή αν αρνήθηκε ο χρήστης) ---
    final legacyStatuses = await [
      Permission.locationWhenInUse,
      // Αν χρειαζόσουν background scans: Permission.locationAlways,
    ].request();

    final legacyOk = legacyStatuses.values.every((s) => s.isGranted);

    // Αν ο χρήστης έδωσε SCAN/CONNECT μερικώς και μετά έδωσε και location,
    // θεωρούμε ότι είμαστε ΟΚ εφόσον η σάρωση μπορεί να δουλέψει.
    return modernOk || legacyOk;
  }
}
