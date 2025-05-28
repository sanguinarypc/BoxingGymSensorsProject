// lib/services/providers.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:box_sensors/services/bluetooth_manager.dart';
import 'package:box_sensors/state/timer_state.dart';
import 'package:box_sensors/Themes/theme_provider.dart';
import 'package:box_sensors/services/database_helper.dart';

/// A single, app‑wide BluetoothManager that starts exactly one scan on creation.
final bluetoothManagerProvider = ChangeNotifierProvider<BluetoothManager>((
  ref,
) {
  final manager = BluetoothManager();

  // Ensure Bluetooth is enabled on Android.
  if (Platform.isAndroid) {
    FlutterBluePlus.turnOn();
  }

  // Kick off the singleton background scan.
  manager.startScan(
    timeout: const Duration(seconds: 4),
    filterKeyword: 'Boxer',
  );

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
