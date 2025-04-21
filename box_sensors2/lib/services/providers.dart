// lib/services/providers.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:box_sensors2/services/bluetooth_manager.dart';
import 'package:box_sensors2/state/timer_state.dart';
import 'package:box_sensors2/Themes/theme_provider.dart';
import 'package:box_sensors2/services/database_helper.dart';

/// A single, app‑wide BluetoothManager that starts exactly one scan on creation.
final bluetoothManagerProvider =
    ChangeNotifierProvider<BluetoothManager>((ref) {
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

final timerStateProvider =
    ChangeNotifierProvider<TimerState>((ref) => TimerState());

final themeProviderProvider =
    ChangeNotifierProvider<ThemeProvider>((ref) => ThemeProvider());

final databaseHelperProvider =
    Provider<DatabaseHelper>((ref) => DatabaseHelper());











// // lib/services/providers.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors2/services/bluetooth_manager.dart';
// import 'package:box_sensors2/state/timer_state.dart';
// import 'package:box_sensors2/Themes/theme_provider.dart';
// import 'package:box_sensors2/services/database_helper.dart';

// final bluetoothManagerProvider =
//     ChangeNotifierProvider<BluetoothManager>((ref) => BluetoothManager());

// final timerStateProvider =
//     ChangeNotifierProvider<TimerState>((ref) => TimerState());

// final themeProviderProvider =
//     ChangeNotifierProvider<ThemeProvider>((ref) => ThemeProvider());

// final databaseHelperProvider =
//     Provider<DatabaseHelper>((ref) => DatabaseHelper());
