// lib/services/providers.dart
import 'dart:async'; // για unawaited
import 'dart:io';
import 'package:box_sensors/services/riverpod_imports.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:box_sensors/services/bluetooth_manager.dart';
import 'package:box_sensors/state/timer_state.dart';
import 'package:box_sensors/Themes/theme_provider.dart';
import 'package:box_sensors/services/database_helper.dart';

/// A single, app-wide BluetoothManager that starts exactly one scan on creation.
final bluetoothManagerProvider = ChangeNotifierProvider<BluetoothManager>((ref) {
  final manager = BluetoothManager();

  // Ensure Bluetooth is enabled on Android.
  if (Platform.isAndroid) {
    FlutterBluePlus.turnOn();
  }

  // Kick off the singleton background scan (idempotent inside your manager).
  unawaited(manager.startScan(
    timeout: const Duration(seconds: 4),
    filterKeyword: 'Boxer',
  ));

  // Clean up when provider is disposed (hot-restart/tests/app teardown).
  ref.onDispose(() async {
    try {
      // Μην καλείς manager.stopScan() αν δεν υπάρχει.
      // Σταμάτα το scan απευθείας από το plugin:
      await FlutterBluePlus.stopScan();
    } catch (_) {
      // swallow
    }
    manager.dispose();
  });

  return manager;
});

final timerStateProvider = ChangeNotifierProvider<TimerState>(
  (ref) => TimerState(),
);

final themeProviderProvider = ChangeNotifierProvider<ThemeProvider>(
  (ref) => ThemeProvider(),
);

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  final helper = DatabaseHelper();

  // when the provider and the app is torn down, close the DB
  ref.onDispose(() {
    helper.close();
  });
  return helper;
});

// right below your databaseHelperProvider:
/// Holds the current list of matches; can be invalidated to re-fetch.
final matchesFutureProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.read(databaseHelperProvider);
  return db.fetchMatches();
});
