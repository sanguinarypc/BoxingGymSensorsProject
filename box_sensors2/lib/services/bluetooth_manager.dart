// Code -7
// File: bluetooth_manager.dart last modified on 2025-10-04
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:box_sensors2/state/timer_state.dart';
import 'package:box_sensors2/services/database_helper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class BluetoothManager with ChangeNotifier {
  /// Buffer the raw maps for each notification + history row
  final List<Map<String, dynamic>> _rawMsgs = [];

  TimerState? _timerState;

  Timer? _notifyDebounce; // ← debounce for ALL UI updates
  int? _currentRoundId;
  int? _currentMatchId;
  bool _isDiscoveringServices = false;
  bool _disposed = false; // For safety checks.
  bool _shouldAutoReconnect = false; // To disable auto reconnect
  /// When true, we’ve already stopped scanning early.
  bool _didStopScan = false;

  // Stream controllers.
  final StreamController<List<DataRow>> _messageStreamController =
      StreamController<List<DataRow>>.broadcast();
  final StreamController<String?> _disconnectionStreamController =
      StreamController<String?>.broadcast();

  /// In BluetoothManager:
  final _rawController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get rawMessageStream =>
      _rawController.stream;

  // Bluetooth properties.
  BluetoothCharacteristic? writableCharacteristic;
  Map<Guid, String> readValues = {};
  Set<String> uniqueMessages = {};
  List<DataRow> rows = [];

  // Device connection maps.
  Map<String, bool> connectedDevices = {
    'BlueBoxer': false,
    'RedBoxer': false,
    'BoxerServer': false,
  };
  Map<String, BluetoothDevice?> connectedBluetoothDevices = {
    'BlueBoxer': null,
    'RedBoxer': null,
    'BoxerServer': null,
  };

  // ValueNotifiers for connection states.
  final Map<String, ValueNotifier<bool>> _deviceConnectionNotifiers = {
    'BlueBoxer': ValueNotifier<bool>(false),
    'RedBoxer': ValueNotifier<bool>(false),
    'BoxerServer': ValueNotifier<bool>(false),
  };

  // Overall connected devices count.
  final ValueNotifier<int> _connectedDevicesCount = ValueNotifier<int>(0);

  // Notification subscriptions.
  final Map<String, StreamSubscription<List<int>>> _notificationSubscriptions =
      {};

  // Scan state and results.
  List<String> availableDevices = [];
  bool isScanning = false;
  Map<String, int> rssiValues = {}; // For current RSSI values.

  // Database helper.
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Getters.
  int? get currentRoundId => _currentRoundId;
  int? get currentMatchId => _currentMatchId;
  Stream<List<DataRow>> get messageStream => _messageStreamController.stream;
  Stream<String?> get disconnectionStream =>
      _disconnectionStreamController.stream;
  bool get isConnectedDevice1 => connectedDevices['BlueBoxer'] ?? false;
  bool get isConnectedDevice2 => connectedDevices['RedBoxer'] ?? false;
  bool get isConnectedDevice3 => connectedDevices['BoxerServer'] ?? false;
  Map<String, ValueNotifier<bool>> get deviceConnectionNotifiers =>
      _deviceConnectionNotifiers;
  ValueNotifier<int> get connectedDevicesCount => _connectedDevicesCount;

  // Regular expressions.
  static final RegExp _deviceRegex = RegExp(r'Device:\s*(\S+)');
  static final RegExp _punchCountRegex = RegExp(r'Punch Count:\s*([\d:]+)');
  static final RegExp _timestampRegex = RegExp(r'Timestamp:\s*([\d:]+)');
  static final RegExp _sensorValueRegex = RegExp(r'Sensor millivolts:\s*(\d+)');

  String? _extractValue(String message, RegExp regex) {
    final match = regex.firstMatch(message);
    return match?.group(1);
  }

  String _extractDevice(String message) =>
      _extractValue(message, _deviceRegex) ?? "UnknownDevice";
  String? _extractPunchCount(String message) =>
      _extractValue(message, _punchCountRegex);
  String? _extractTimestamp(String message) =>
      _extractValue(message, _timestampRegex);
  String? _extractSensorValue(String message) =>
      _extractValue(message, _sensorValueRegex);

  /// Clears the internal table data. In bluetooth_manager.dart
  void clearTable() {
    // 1) clear the DataRow list and push an empty list
    rows.clear();
    if (!_messageStreamController.isClosed) {
      _messageStreamController.add([]);
    }

    // ── NEW: also clear the raw‐map stream ──
    _rawMsgs.clear();
    if (!_rawController.isClosed) {
      _rawController.sink.add(<Map<String, dynamic>>[]);
    }

    _safeNotifyListeners();
  }

  /// Returns a unique key for a device.
  String getDeviceKey(BluetoothDevice device) {
    final platformName = device.platformName.trim();
    if (platformName.isEmpty || platformName.toLowerCase() == 'unknown') {
      return device.remoteId.toString();
    }
    return platformName;
  }

  String getDeviceKey1(BluetoothDevice device) {
    final trimmedName = device.platformName.trim();
    // If the device's name is one of our target names, use it.
    if (trimmedName.isNotEmpty &&
        (trimmedName == 'BlueBoxer' ||
            trimmedName == 'RedBoxer' ||
            trimmedName == 'BoxerServer')) {
      return trimmedName;
    }
    // Otherwise, if name is empty, return remoteId, or else return the trimmed name.
    return trimmedName.isEmpty ? device.remoteId.toString() : trimmedName;
  }

  /// Sets the TimerState.
  void setTimerState(TimerState timerState) {
    debugPrint('setTimerState(...) called with timerState=$timerState');
    _timerState = timerState;
  }

  /// Sets current round ID.
  void setCurrentRoundId(int roundId) {
    _currentRoundId = roundId;
    _safeNotifyListeners();
  }

  /// Sets current match ID.
  void setCurrentMatchId(int? matchId) {
    _currentMatchId = matchId;
    _safeNotifyListeners();
  }

  /// Controls auto reconnect.
  void setAutoReconnect(bool value) {
    _shouldAutoReconnect = value;
  }

  /// Updates the overall connected devices count.
  void _updateConnectedDevicesCount() {
    int count = connectedDevices.values.where((c) => c).length;
    _connectedDevicesCount.value = count;
  }

  bool isDeviceConnected(String deviceName) =>
      connectedDevices[deviceName] ?? false;

  /// Safely notifies listeners.
  void _safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  /// Schedule one rebuild 300 ms after the last call.
  void _scheduleUIUpdate() {
    _notifyDebounce?.cancel();
    _notifyDebounce = Timer(const Duration(milliseconds: 300), () {
      _notifyDebounce = null;
      _safeNotifyListeners();
    });
  }

  Future<void> startScan({
    Duration? timeout,
    String filterKeyword = 'Boxer',
  }) async {
    if (isScanning) {
      debugPrint("Scan already in progress");
      return;
    }
    isScanning = true;
    availableDevices.clear();
    rssiValues.clear();
    _safeNotifyListeners(); // initial UI update

    try {
      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first;

      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final device = r.device;
          final displayName =
              device.platformName.trim().isNotEmpty
                  ? device.platformName.trim()
                  : device.remoteId.toString();

          if (filterKeyword.isNotEmpty &&
              !displayName.toLowerCase().contains(
                filterKeyword.toLowerCase(),
              )) {
            continue;
          }
          if (!availableDevices.contains(displayName)) {
            availableDevices.add(displayName);
            debugPrint(
              "Discovered device: $displayName added to availableDevices",
            );
          }
          rssiValues[displayName] = r.rssi;
        }
        // Debounced UI update instead of immediate notifyListeners()
        _scheduleUIUpdate(); // final UI update
      });

      FlutterBluePlus.cancelWhenScanComplete(subscription);

      await FlutterBluePlus.startScan(
        timeout: timeout ?? const Duration(seconds: 4),
        androidScanMode: AndroidScanMode.lowLatency,
        androidUsesFineLocation: true,
      );
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      debugPrint("Scan finished");
    } catch (e) {
      debugPrint("Error scanning for devices: $e");
      Sentry.captureException(e);
    } finally {
      isScanning = false;
      _safeNotifyListeners(); // final UI update
    }
  }

  /// Mimics a scanForDevices call.
  Future<void> scanForDevices() async {
    await startScan(timeout: const Duration(seconds: 4));
  }

  /// Calculate distance from RSSI using log-distance path loss model.
  double calculateDistance(int rssi, {int txPower = -59, double n = 2.0}) {
    return pow(10, ((txPower - rssi) / (10 * n))).toDouble();
  }

  /// Update the RSSI for connected devices.
  Future<void> updateRSSIForConnectedDevices() async {
    // Create a set of device names from connected devices that are not null.
    final deviceNames =
        connectedBluetoothDevices.entries
            .where((entry) => entry.value != null)
            .map((entry) => entry.key)
            .toSet();

    for (final deviceName in deviceNames) {
      final connectedDevice = connectedBluetoothDevices[deviceName];
      if (connectedDevice != null) {
        try {
          final rssi = await connectedDevice.readRssi();
          rssiValues[deviceName] = rssi;
          debugPrint("Updated RSSI for $deviceName: $rssi");
        } catch (e) {
          debugPrint("Error reading RSSI for $deviceName: $e");
          Sentry.captureException(e);
        }
      }
    }
    _scheduleUIUpdate(); // final UI update
  }

  /// Disconnect all devices.
  Future<void> disconnectAllDevices() async {
    for (final deviceName in connectedBluetoothDevices.keys) {
      if (connectedBluetoothDevices[deviceName] != null) {
        await handleDisconnectDevice(deviceName);
      }
    }
    _safeNotifyListeners();
  }

  /// Disconnect a device and cancel its notification subscriptions.
  Future<void> handleDisconnectDevice(String deviceName) async {
    final BluetoothDevice? device = connectedBluetoothDevices[deviceName];
    if (device != null) {
      setAutoReconnect(false);
      try {
        await device.disconnect();
        await device.connectionState.firstWhere(
          (state) => state == BluetoothConnectionState.disconnected,
          orElse: () => BluetoothConnectionState.disconnected,
        );
      } catch (e, stackTrace) {
        debugPrint("Error disconnecting $deviceName: $e");
        Sentry.captureException(e, stackTrace: stackTrace);
      }
      // Clear the connection and update states.
      connectedBluetoothDevices[deviceName] = null;
      connectedDevices[deviceName] = false;
      _deviceConnectionNotifiers[deviceName]?.value = false;

      // *** NEW: Cancel any notification subscriptions for this device. ***
      final keysToRemove =
          _notificationSubscriptions.keys
              .where((key) => key.startsWith(deviceName))
              .toList();
      for (final key in keysToRemove) {
        await _notificationSubscriptions[key]?.cancel();
        _notificationSubscriptions.remove(key);
        debugPrint("Cancelled notification subscription for $key.");
      }
      _safeNotifyListeners();
    }
  }

  /// Connect to a device by name using scan results.
  Future<void> connectToDeviceByName(String deviceName) async {
    // 1️⃣ Tell the world we’re scanning
    isScanning = true;
    _safeNotifyListeners();

    try {
      // 2️⃣ Wait for the adapter to be powered on
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first;
      debugPrint("Starting single-device scan for $deviceName (3s)…");

      // 3️⃣ Listen for scan results
      final scanSubscription = FlutterBluePlus.scanResults.listen((
        results,
      ) async {
        for (var result in results) {
          if (result.device.platformName.trim() == deviceName) {
            debugPrint("Found $deviceName; connecting…");
            try {
              await connectToDevice(result.device);
              _deviceConnectionNotifiers[deviceName]?.value = true;
              _safeNotifyListeners();
              debugPrint("Connected to $deviceName successfully.");
            } catch (e, st) {
              debugPrint("Failed to connect to $deviceName: $e");
              Sentry.captureException(e, stackTrace: st);
            }
            debugPrint("Stopping scan for $deviceName early.");
            await FlutterBluePlus.stopScan();
            break;
          }
        }
      }, onError: (err) => debugPrint("Scan error (single device): $err"));
      FlutterBluePlus.cancelWhenScanComplete(scanSubscription);

      // 4️⃣ Kick off the scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 3),
        androidScanMode: AndroidScanMode.lowLatency,
        androidUsesFineLocation: true,
      );
      // 5️⃣ Wait for scan to finish
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      debugPrint("Single-device scan for $deviceName ended.");
    } finally {
      // 6️⃣ Always clear the scanning flag, even if we errored
      isScanning = false;
      _safeNotifyListeners();
    }
  }

  Future<void> connectAllBoxerDevices() async {
    isScanning = true;
    _safeNotifyListeners();

    _didStopScan = false; // ← reset at the top
    const targetDevices = {'BlueBoxer', 'RedBoxer', 'BoxerServer'};

    // wait for adapter on…
    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first;

    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName.trim();
        if (!targetDevices.contains(name) || isDeviceConnected(name)) continue;

        debugPrint("Queued connect attempt for $name");
        _connectAndMaybeStop(r.device, name, targetDevices);
      }
    });
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    await FlutterBluePlus.isScanning.where((v) => v == false).first;
    debugPrint("Multi‑device scan ended or timed out.");

    // final summary…
    final notConnected = targetDevices.where((n) => !isDeviceConnected(n));
    debugPrint(
      notConnected.isNotEmpty
          ? "Some devices not connected: $notConnected"
          : "All devices connected successfully!",
    );
    isScanning = false;
    _safeNotifyListeners();
  }

  /// Helper that actually does the async connect + stopScan guard
  Future<void> _connectAndMaybeStop(
    BluetoothDevice device,
    String name,
    Set<String> targetDevices,
  ) async {
    debugPrint("Attempting to connect to $name…");
    try {
      await connectToDevice(device);
      debugPrint(
        isDeviceConnected(name)
            ? "Connected to $name successfully."
            : "Connection attempt for $name did not succeed.",
      );

      final allConnected = targetDevices.every(isDeviceConnected);
      if (allConnected && !_didStopScan) {
        _didStopScan = true; // ← flip your class‐level flag
        debugPrint("All targets connected → stopping scan early.");
        await FlutterBluePlus.stopScan();
      }
    } catch (e, st) {
      debugPrint("Failed to connect to $name: $e");
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Connect to a device.
  Future<void> connectToDevice(BluetoothDevice device) async {
    _shouldAutoReconnect = true; // allow auto‑reconnect for this new connection
    final deviceKey = getDeviceKey(device);

    // *** MODIFIED CHECK: Verify actual connection state ***
    if (connectedBluetoothDevices[deviceKey] != null) {
      bool reallyConnected = await _isReallyConnected(
        connectedBluetoothDevices[deviceKey]!,
      );
      if (reallyConnected) {
        debugPrint("Device $deviceKey is already connected.");
        return;
      } else {
        // Clear stale reference
        connectedBluetoothDevices[deviceKey] = null;
      }
    }

    try {
      await device.connect(timeout: const Duration(seconds: 5));
      connectedBluetoothDevices[deviceKey] = device;
      _updateDeviceConnectionStatus(deviceKey, true);
      _safeNotifyListeners();
      await Future.delayed(const Duration(seconds: 1));

      // Listen for disconnection events.
      late final StreamSubscription<BluetoothConnectionState>
      disconnectionSubscription;
      disconnectionSubscription = device.connectionState.listen((
        connectionState,
      ) {
        if (connectionState == BluetoothConnectionState.disconnected) {
          // --- NEW: Clean up notification subs on unexpected disconnect ---
          final toRemove =
              _notificationSubscriptions.keys
                  .where((k) => k.startsWith(deviceKey))
                  .toList();
          for (final charKey in toRemove) {
            _notificationSubscriptions[charKey]?.cancel();
            _notificationSubscriptions.remove(charKey);
            debugPrint(
              "Cancelled notification subscription for $charKey on disconnect.",
            );
          }

          _updateDeviceConnectionStatus(deviceKey, false);
          connectedBluetoothDevices[deviceKey] = null;
          _disconnectionStreamController.add(deviceKey);
          disconnectionSubscription.cancel();
          _safeNotifyListeners();
          Future.delayed(const Duration(seconds: 1), () {
            // it wss 3 sec testing 1 second
            if (WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed &&
                !_disposed &&
                _shouldAutoReconnect) {
              debugPrint("Attempting to reconnect to $deviceKey...");
              connectToDevice(device).catchError((e, stackTrace) {
                debugPrint("Reconnection to $deviceKey failed: $e");
                Sentry.captureException(e, stackTrace: stackTrace);
              });
            }
          });
        }
      });

      if (Platform.isAndroid) {
        try {
          int newMtu = await device.requestMtu(247);
          debugPrint('Requested MTU = 247, actually set to: $newMtu');
        } catch (mtuError, stackTrace) {
          debugPrint('Error requesting MTU: \$mtuError');
          Sentry.captureException(mtuError, stackTrace: stackTrace);
        }
      }
      await discoverServices();
    } catch (e, stackTrace) {
      debugPrint("Error connecting to device: \$e");
      _updateDeviceConnectionStatus(deviceKey, false);
      _safeNotifyListeners();
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Get a color based on the RSSI value.
  Color getRSSIColor(int rssi) {
    if (rssi >= -30) return Colors.blue;
    if (rssi >= -55) return Colors.green;
    if (rssi >= -67) return Colors.lightGreen;
    if (rssi >= -80) return Colors.yellow;
    if (rssi >= -90) return Colors.orange;
    return Colors.red;
  }

  /// Helper method to check if a device is really connected.
  Future<bool> _isReallyConnected(BluetoothDevice device) async {
    try {
      final state = await device.connectionState.first;
      return state == BluetoothConnectionState.connected;
    } catch (e) {
      return false;
    }
  }

  void _updateDeviceConnectionStatus(String deviceName, bool status) {
    if (!connectedDevices.containsKey(deviceName)) {
      debugPrint("Warning: $deviceName is not registered in connectedDevices.");
      return;
    }
    if (connectedDevices[deviceName] != status) {
      connectedDevices[deviceName] = status;
      debugPrint('$deviceName connection status updated to: $status');
      _deviceConnectionNotifiers[deviceName]?.value = status;
      _updateConnectedDevicesCount();
      _safeNotifyListeners();
    }
  }

  /// Discover services on all connected devices.
  Future<void> discoverServices() async {
    if (_isDiscoveringServices) {
      debugPrint("⏳ Service discovery already in progress, skipping new call.");
      return;
    }
    _isDiscoveringServices = true;
    debugPrint("🔄 discoverServices() called");
    try {
      List<Future<void>> discoveryFutures =
          connectedBluetoothDevices.entries.map((entry) async {
            final deviceName = entry.key;
            final BluetoothDevice? connectedDevice = entry.value;
            if (connectedDevice == null) {
              debugPrint("⚠️ Device $deviceName is null. Skipping.");
              return;
            }
            debugPrint("🔍 Discovering services for device: $deviceName");
            try {
              List<BluetoothService> servicesList =
                  await connectedDevice.discoverServices();
              debugPrint(
                "📡 Discovered ${servicesList.length} services for $deviceName",
              );
              for (var service in servicesList) {
                for (var characteristic in service.characteristics) {
                  if (characteristic.properties.notify) {
                    String charKey = '$deviceName-${characteristic.uuid}';
                    if (_notificationSubscriptions.containsKey(charKey)) {
                      debugPrint(
                        "⚠️ Listener already exists for $charKey, skipping.",
                      );
                      continue;
                    }
                    debugPrint(
                      "✅ Subscribing to characteristic ${characteristic.uuid} for $deviceName.",
                    );
                    await characteristic.setNotifyValue(true);
                    await Future.delayed(Duration(milliseconds: 400));
                    var subscription = characteristic.lastValueStream.listen(
                      (value) => _handleNotification(value, deviceName),
                      onError: (error, stackTrace) {
                        debugPrint(
                          "❌ Error in notification stream for $deviceName: $error",
                        );
                        debugPrint(stackTrace.toString());
                        Sentry.captureException(error, stackTrace: stackTrace);
                      },
                    );
                    _notificationSubscriptions[charKey] = subscription;
                    debugPrint(
                      "👂 Active Listeners Count: ${_notificationSubscriptions.length}",
                    );
                  }
                }
              }
            } catch (e, stackTrace) {
              debugPrint("❌ Error discovering services for $deviceName: $e");
              Sentry.captureException(e, stackTrace: stackTrace);
            }
          }).toList();
      await Future.wait(discoveryFutures);
    } finally {
      _isDiscoveringServices = false;
    }
  }

  /// Process incoming notifications.
  void _handleNotification(List<int> value, String deviceName) async {
    if (_disposed) return;
    try {
      final decodedMessage = utf8.decode(value);
      debugPrint("📩 Received notification from $deviceName: $decodedMessage");
      try {
        final dynamic parsed = json.decode(decodedMessage);
        if (parsed is Map<String, dynamic> &&
            parsed["RoundState"] == "Completed") {
          _timerState?.endMatch();
        }
      } catch (jsonError) {
        // Ignore JSON parsing errors.
      }
      final punchCount = _extractPunchCount(decodedMessage);
      final timestamp = _extractTimestamp(decodedMessage);
      String extractedDevice = _extractDevice(decodedMessage);
      final deviceStr =
          (extractedDevice == "UnknownDevice") ? deviceName : extractedDevice;
      final sensorValue = _extractSensorValue(decodedMessage);
      if (punchCount != null && timestamp != null && sensorValue != null) {
        String oppositeDevice =
            (deviceStr == "BlueBoxer") ? "RedBoxer" : "BlueBoxer";
        final newRow = DataRow(
          cells: [
            DataCell(Center(child: Text(deviceStr))),
            DataCell(Center(child: Text(oppositeDevice))),
            DataCell(Center(child: Text(punchCount.toString()))),
            DataCell(Center(child: Text(timestamp))),
            DataCell(Center(child: Text(sensorValue))),
          ],
        );
        rows.add(newRow);
        _messageStreamController.add(List.from(rows));
        _scheduleUIUpdate(); // ← debounce rapid‐fire notifications

        final msgMap = {
          'device': deviceStr,
          'punchBy': oppositeDevice,
          'punchCount': punchCount.toString(),
          'timestamp': timestamp,
          'sensorValue': sensorValue,
        };
        _rawMsgs.add(msgMap);
        _rawController.sink.add(List.from(_rawMsgs));

        final localRoundId = _currentRoundId;
        final localMatchId = _currentMatchId;
        if (localMatchId == null) {
          _sendDataAndInsertToDatabase(
            deviceStr,
            oppositeDevice,
            punchCount,
            timestamp,
            sensorValue,
            0,
            null,
          );
        } else {
          _sendDataAndInsertToDatabase(
            deviceStr,
            oppositeDevice,
            punchCount,
            timestamp,
            sensorValue,
            localRoundId ?? 0,
            localMatchId,
          );
        }
      }
    } catch (e, stackTrace) {
      if (!_disposed) {
        debugPrint("❌ 🔴 Error processing notification from $deviceName: $e");
        debugPrint(stackTrace.toString());
        Sentry.captureException(e, stackTrace: stackTrace);
      }
    }
  }

  /// Insert training data into the database.
  Future<void> _insertTrainingDataToDatabase(
    String deviceStr,
    String oppositeDevice,
    String punchCount,
    String timestamp,
    String sensorValue,
  ) async {
    try {
      await dbHelper.insertTrainingData(
        deviceStr,
        oppositeDevice,
        punchCount,
        timestamp,
        sensorValue,
      );
    } catch (e, stackTrace) {
      debugPrint("❌ 💾 🔴 Error inserting training data into DB: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Send data and insert into the database concurrently.
  void _sendDataAndInsertToDatabase(
    String deviceStr,
    String oppositeDevice,
    String punchCount,
    String timestamp,
    String sensorValue,
    int roundId,
    int? matchId,
  ) {
    if (matchId != null) {
      Future.wait([
        _sendDataToBoxerServer(
          deviceStr,
          oppositeDevice,
          punchCount,
          timestamp,
          sensorValue,
        ),
        _insertDataToDatabase(
          deviceStr,
          oppositeDevice,
          punchCount,
          timestamp,
          sensorValue,
          roundId,
          matchId,
        ),
      ]);
    } else {
      Future.wait([
        _sendDataToBoxerServer(
          deviceStr,
          oppositeDevice,
          punchCount,
          timestamp,
          sensorValue,
        ),
        _insertTrainingDataToDatabase(
          deviceStr,
          oppositeDevice,
          punchCount,
          timestamp,
          sensorValue,
        ),
      ]);
    }
  }

  /// Insert data into the database for StartMatch mode.
  Future<void> _insertDataToDatabase(
    String deviceStr,
    String oppositeDevice,
    String punchCount,
    String timestamp,
    String sensorValue,
    int roundId,
    int matchId,
  ) async {
    try {
      await dbHelper.insertMessage(
        deviceStr,
        oppositeDevice,
        punchCount,
        timestamp,
        sensorValue,
        roundId,
        matchId,
      );
    } catch (e, stackTrace) {
      debugPrint("❌ 💾 🔴 Error inserting message into DB: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Bulk‑load a bunch of historical rows from the 'messages' table.
  ///
  /// Internally converts each DB row into a DataRow, pushes it
  /// to the stream, and *debounces* the UI rebuilds to at most
  /// one every 300 ms.
  Future<void> loadHistory({int? matchId}) async {
    _rawMsgs.clear();
    // 1) Read the raw message maps from SQLite.
    //    If you want *all* messages, call fetchMessages();
    //    if only for a match, call fetchMessagesByMatchId(matchId).
    final List<Map<String, dynamic>> history =
        matchId == null
            ? await dbHelper.fetchMessages()
            : await dbHelper.fetchMessagesByMatchId(matchId);

    // 2) For each DB row, build a DataRow and push it.
    for (final msg in history) {
      final row = DataRow(
        cells: [
          DataCell(Center(child: Text(msg['device'] ?? ''))),
          DataCell(Center(child: Text(msg['punchBy'] ?? ''))),
          DataCell(Center(child: Text(msg['punchCount'] ?? ''))),
          DataCell(Center(child: Text(msg['timestamp'] ?? ''))),
          DataCell(Center(child: Text(msg['sensorValue'] ?? ''))),
        ],
      );

      // Add to your internal list and stream
      rows.add(row);
      _messageStreamController.add(List.from(rows));

      // **NEW**: record raw msg and emit
      _rawMsgs.add(msg);
      _rawController.sink.add(List.from(_rawMsgs));

      // ← instead of notifyListeners(), debounce via your existing helper
      _scheduleUIUpdate();
    }

    // 3) One final immediate build so UI definitely ends up up‑to‑date.
    _safeNotifyListeners();
  }

  /// Helper function to send data to BoxerServer.
  Future<void> _sendDataToBoxerServer(
    String deviceStr,
    String oppositeDevice,
    String punchCount,
    String timestamp,
    String sensorValue,
  ) async {
    if (!isDeviceConnected("BoxerServer")) {
      debugPrint(
        "❌ 🔴 BoxerServer not connected. Skipping sendDataToBoxerServer.",
      );
      return;
    }
    try {
      await sendDataToBoxerServer(
        deviceStr: deviceStr,
        oppositeDevice: oppositeDevice,
        punchCount: punchCount,
        timestamp: timestamp,
        sensorValue: sensorValue,
      );
    } catch (e, stackTrace) {
      debugPrint("➡️ ❌ 🔴 Error sending data to BoxerServer: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  Future<void> sendMessageToConnectedDevice(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty || trimmedMessage == "[]") {
      debugPrint("Refusing to send empty/bracket message.");
      return;
    }
    if (writableCharacteristic != null) {
      try {
        final dataToSend = utf8.encode(trimmedMessage);
        await writableCharacteristic!.write(dataToSend, withoutResponse: false);
        debugPrint("Message sent via cached characteristic: $trimmedMessage");
        return;
      } catch (e, stackTrace) {
        debugPrint("Error sending message via cached characteristic: $e");
        Sentry.captureException(e, stackTrace: stackTrace);
        debugPrint("Falling back to service discovery.");
      }
    } else {
      debugPrint(
        "No cached writable characteristic found. Falling back to service discovery.",
      );
    }
    BluetoothDevice? fallbackDevice;
    String fallbackDeviceName = "";
    for (final entry in connectedBluetoothDevices.entries) {
      if (entry.value != null) {
        fallbackDevice = entry.value;
        fallbackDeviceName = entry.key;
        break;
      }
    }
    if (fallbackDevice == null) {
      debugPrint("No connected devices available for fallback.");
      return;
    }
    try {
      await _sendMessageToDevice(
        fallbackDevice,
        fallbackDeviceName,
        trimmedMessage,
      );
    } catch (e, stackTrace) {
      debugPrint("Error sending message via service discovery: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  Future<void> _sendMessageToDevice(
    BluetoothDevice device,
    String deviceName,
    String message,
  ) async {
    try {
      final services = await device.discoverServices();
      final List<Future<void>> writeFutures = [];
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            debugPrint(
              "Discovered writable characteristic ${characteristic.uuid} on $deviceName",
            );
            writeFutures.add(
              characteristic
                  .write(utf8.encode(message), withoutResponse: false)
                  .then(
                    (_) => debugPrint(
                      "Message sent to $deviceName via ${characteristic.uuid}: $message",
                    ),
                  )
                  .catchError((error, stackTrace) {
                    debugPrint(
                      "Error sending message via ${characteristic.uuid} on $deviceName: $error",
                    );
                    Sentry.captureException(error, stackTrace: stackTrace);
                  }),
            );
          }
        }
      }
      if (writeFutures.isEmpty) {
        debugPrint(
          "No writable characteristics found on $deviceName to send message.",
        );
      } else {
        await Future.wait(writeFutures);
      }
    } catch (e, stackTrace) {
      debugPrint("Error in _sendMessageToDevice for $deviceName: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  Future<void> sendMessageToAllConnectedDevices(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty || trimmedMessage == "[]") {
      debugPrint("Refusing to send empty/bracket message.");
      return;
    }
    List<Future<void>> sendFutures = [];
    for (var entry in connectedBluetoothDevices.entries) {
      final deviceName = entry.key;
      final BluetoothDevice? device = entry.value;
      if (device != null) {
        sendFutures.add(
          _sendMessageToDevice(device, deviceName, trimmedMessage).catchError((
            e,
            stackTrace,
          ) {
            debugPrint("Error sending message to $deviceName: $e");
            Sentry.captureException(e, stackTrace: stackTrace);
          }),
        );
      } else {
        debugPrint("Device $deviceName is not connected.");
      }
    }
    if (sendFutures.isEmpty) {
      debugPrint("No connected devices available to send the message.");
      return;
    }
    await Future.wait(sendFutures);
  }

  Future<void> sendDataToBoxerServer({
    required String deviceStr,
    required String oppositeDevice,
    required String punchCount,
    required String timestamp,
    required String sensorValue,
  }) async {
    final dataMap = {
      "deviceStr": deviceStr,
      "oppositeDevice": oppositeDevice,
      "punchCount": punchCount,
      "timestamp": timestamp,
      "sensorValue": sensorValue,
    };
    final dataMessage = jsonEncode(dataMap);
    debugPrint("Sending data to BoxerServer (JSON): $dataMessage");

    final boxerServerDevice = connectedBluetoothDevices["BoxerServer"];
    if (boxerServerDevice == null) {
      debugPrint("🚀 ❌ BoxerServer is not connected. Cannot send data.");
      return;
    }
    try {
      await _sendMessageToDevice(boxerServerDevice, "BoxerServer", dataMessage);
      debugPrint("📤 ➡️ Data sent to BoxerServer successfully.");
    } catch (e, stackTrace) {
      debugPrint("❌ Error sending data to BoxerServer: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _notifyDebounce?.cancel();
    try {
      _messageStreamController.close();
      _disconnectionStreamController.close();
      _notificationSubscriptions.forEach((_, subscription) {
        subscription.cancel();
      });
      _notificationSubscriptions.clear();
    } catch (e, stackTrace) {
      debugPrint("Error during BluetoothManager dispose: $e");
      Sentry.captureException(e, stackTrace: stackTrace);
    }
    _deviceConnectionNotifiers.forEach((_, notifier) => notifier.dispose());
    _connectedDevicesCount.dispose();
    _disposed = true;
    super.dispose();
  }
}
