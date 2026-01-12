// lib/services/bluetooth_manager.dart
import 'dart:async'; // Required for asynchronous operations like Timers and Streams.
import 'dart:convert'; // Required for encoding and decoding data, e.g., UTF-8 and JSON.
import 'dart:io' show Platform; // Used to check the current operating system platform (e.g., Android, iOS).
import 'dart:math'; // Provides mathematical functions like pow (for power).
import 'package:flutter/material.dart'; // Flutter framework's Material Design widgets and core functionalities.
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Main library for Bluetooth Low Energy (BLE) interactions.
import 'package:box_sensors/state/timer_state.dart'; // Custom class for managing timer states within the application.
import 'package:box_sensors/services/database_helper.dart'; // Custom class for SQLite database operations.
import 'package:sentry_flutter/sentry_flutter.dart'; // Sentry SDK for error reporting and performance monitoring.

void _captureSentryException(Object error, {StackTrace? stackTrace}) {
  if (!Sentry.isEnabled) return;
  Sentry.captureException(error, stackTrace: stackTrace);
}

// Manages all Bluetooth-related operations, including scanning, connecting,
// data transmission, and state management for connected devices.
// It uses ChangeNotifier to notify UI elements of state changes.
class BluetoothManager with ChangeNotifier {
  /// Buffer the raw maps for each notification + history row
  // This list stores raw data messages (as maps) received from BLE devices or loaded from history.
  final List<Map<String, dynamic>> _rawMsgs = [];

  // Reference to the TimerState, used to interact with match and round timing logic.
  TimerState? _timerState;

  // Debounce timer to limit the frequency of UI updates, preventing performance issues from rapid notifications.
  Timer? _notifyDebounce; // ← debounce for ALL UI updates
  // Stores the ID of the currently active round. Null if no round is active.
  int? _currentRoundId;
  // Stores the ID of the currently active match. Null if no match is active.
  int? _currentMatchId;
  // Flag indicating whether a service discovery process is currently underway.
  bool _isDiscoveringServices = false;
  // Flag to check if the BluetoothManager instance has been disposed, to prevent operations on a disposed object.
  bool _disposed = false; // For safety checks.
  // Flag to control whether the manager should automatically attempt to reconnect to a device if it disconnects.
  bool _shouldAutoReconnect = false; // To disable auto reconnect
  /// When true, we’ve already stopped scanning early.
  // Flag indicating that a multi-device scan was stopped prematurely (e.g., all target devices found).
  bool _didStopScan = false;

  // Stream controllers.
  // Broadcast stream controller for lists of DataRow, used to update UI tables with formatted message data.
  final StreamController<List<DataRow>> _messageStreamController =
      StreamController<List<DataRow>>.broadcast();
  // Broadcast stream controller for device disconnection events, emitting the name of the disconnected device.
  final StreamController<String?> _disconnectionStreamController =
      StreamController<String?>.broadcast();

  /// In BluetoothManager:
  // Broadcast stream controller for raw message data (list of maps).
  final _rawController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  // Public stream exposing raw messages.
  Stream<List<Map<String, dynamic>>> get rawMessageStream =>
      _rawController.stream;

  // Bluetooth properties.
  // Holds the specific BluetoothCharacteristic that can be written to for sending data to a connected device.
  BluetoothCharacteristic? writableCharacteristic;
  // Stores values read from device characteristics, keyed by their GUID. (Currently not extensively used).
  Map<Guid, String> readValues = {};
  // A set to store unique message strings, potentially for duplicate filtering. (Currently not extensively used).
  Set<String> uniqueMessages = {};
  // A list of DataRow objects, prepared for display in a UI table, representing received messages.
  List<DataRow> rows = [];

  // Device connection maps.
  // Tracks the connection status (true for connected, false for disconnected) for specific named devices.
  Map<String, bool> connectedDevices = {
    'BlueBoxer': false,
    'RedBoxer': false,
    'BoxerServer': false,
  };
  // Maps device names to their corresponding BluetoothDevice objects when connected. Null if not connected.
  Map<String, BluetoothDevice?> connectedBluetoothDevices = {
    'BlueBoxer': null,
    'RedBoxer': null,
    'BoxerServer': null,
  };

  // ValueNotifiers for connection states.
  // Provides ValueNotifier<bool> for each device, allowing widgets to reactively update based on connection status changes.
  final Map<String, ValueNotifier<bool>> _deviceConnectionNotifiers = {
    'BlueBoxer': ValueNotifier<bool>(false),
    'RedBoxer': ValueNotifier<bool>(false),
    'BoxerServer': ValueNotifier<bool>(false),
  };

  // Overall connected devices count.
  // A ValueNotifier that holds the current count of connected devices.
  final ValueNotifier<int> _connectedDevicesCount = ValueNotifier<int>(0);

  // Notification subscriptions.
  // Stores active StreamSubscription objects for characteristic notifications, keyed by a unique device-characteristic identifier.
  final Map<String, StreamSubscription<List<int>>> _notificationSubscriptions =
      {};

  // Scan state and results.
  // List of discovered Bluetooth device names during a scan.
  List<String> availableDevices = [];
  // Flag indicating if a Bluetooth scan is currently active.
  bool isScanning = false;
  // Maps device names to their last known RSSI (Received Signal Strength Indicator) values.
  Map<String, int> rssiValues = {}; // For current RSSI values.

  // Database helper.
  // Instance of DatabaseHelper to interact with the local SQLite database.
  final DatabaseHelper dbHelper = DatabaseHelper();

  // Getters.
  // Provides read-only access to the current round ID.
  int? get currentRoundId => _currentRoundId;
  // Provides read-only access to the current match ID.
  int? get currentMatchId => _currentMatchId;
  // Provides read-only access to the stream of formatted messages (DataRow list) for UI.
  Stream<List<DataRow>> get messageStream => _messageStreamController.stream;
  // Provides read-only access to the stream of device disconnection events.
  Stream<String?> get disconnectionStream =>
      _disconnectionStreamController.stream;
  // Getter for the connection status of 'BlueBoxer'.
  bool get isConnectedDevice1 => connectedDevices['BlueBoxer'] ?? false;
  // Getter for the connection status of 'RedBoxer'.
  bool get isConnectedDevice2 => connectedDevices['RedBoxer'] ?? false;
  // Getter for the connection status of 'BoxerServer'.
  bool get isConnectedDevice3 => connectedDevices['BoxerServer'] ?? false;
  // Getter for the map of device connection ValueNotifiers.
  Map<String, ValueNotifier<bool>> get deviceConnectionNotifiers =>
      _deviceConnectionNotifiers;
  // Getter for the ValueNotifier representing the count of connected devices.
  ValueNotifier<int> get connectedDevicesCount => _connectedDevicesCount;

  // Regular expressions.
  // Regex to extract device name (e.g., "BlueBoxer") from a message string.
  static final RegExp _deviceRegex = RegExp(r'Device:\s*(\S+)');
  // Regex to extract punch count (e.g., "123" or "1:23") from a message string.
  static final RegExp _punchCountRegex = RegExp(r'Punch Count:\s*([\d:]+)');
  // Regex to extract timestamp (e.g., "10:30:05") from a message string.
  static final RegExp _timestampRegex = RegExp(r'Timestamp:\s*([\d:]+)');
  // Regex to extract sensor value in millivolts (e.g., "500") from a message string.
  static final RegExp _sensorValueRegex = RegExp(r'Sensor millivolts:\s*(\d+)');

  // Generic helper function to extract a value from a string using a provided RegExp.
  // Returns the first captured group if a match is found, otherwise null.
  String? _extractValue(String message, RegExp regex) {
    final match = regex.firstMatch(message);
    return match?.group(1);
  }

  // Extracts the device name from a message string using _deviceRegex. Defaults to "UnknownDevice".
  String _extractDevice(String message) =>
      _extractValue(message, _deviceRegex) ?? "UnknownDevice";
  // Extracts the punch count from a message string using _punchCountRegex.
  String? _extractPunchCount(String message) =>
      _extractValue(message, _punchCountRegex);
  // Extracts the timestamp from a message string using _timestampRegex.
  String? _extractTimestamp(String message) =>
      _extractValue(message, _timestampRegex);
  // Extracts the sensor value from a message string using _sensorValueRegex.
  String? _extractSensorValue(String message) =>
      _extractValue(message, _sensorValueRegex);

  /// Clears the internal table data. In bluetooth_manager.dart
  // Clears all message data from internal lists and streams, effectively resetting the displayed message table.
  void clearTable() {
    // 1) clear the DataRow list and push an empty list
    rows.clear(); // Empties the list of DataRow objects.
    if (!_messageStreamController.isClosed) { // Checks if the stream controller is active.
      _messageStreamController.add([]); // Pushes an empty list to update UI.
    }

    // 2) clear the raw‐map stream 
    _rawMsgs.clear(); // Empties the list of raw message maps.
    if (!_rawController.isClosed) { // Checks if the raw data stream controller is active.
      _rawController.sink.add(<Map<String, dynamic>>[]); // Pushes an empty list to the raw data stream.
    }

    _safeNotifyListeners(); // Notifies listeners of the change.
  }

  /// Returns a unique key for a device.
  // Generates a consistent key for a BluetoothDevice, preferring its platform name
  // but falling back to remoteId if the name is empty or "unknown".
  String getDeviceKey(BluetoothDevice device) {
    final platformName = device.platformName.trim(); // Gets and trims the advertised name.
    if (platformName.isEmpty || platformName.toLowerCase() == 'unknown') { // If name is unreliable.
      return device.remoteId.toString(); // Use the unique remote ID.
    }
    return platformName; // Use the platform name.
  }

  /// Sets the TimerState.
  // Allows injecting a TimerState instance for coordination.
  void setTimerState(TimerState timerState) {
    debugPrint('setTimerState(...) called with timerState=$timerState');
    _timerState = timerState;
  }

  /// Sets current round ID.
  // Updates the manager's record of the current round ID.
  void setCurrentRoundId(int roundId) {
    _currentRoundId = roundId;
    _safeNotifyListeners(); // Notifies UI listeners about the change.
  }

  /// Sets current match ID.
  // Updates the manager's record of the current match ID.
  void setCurrentMatchId(int? matchId) {
    _currentMatchId = matchId;
    _safeNotifyListeners(); // Notifies UI listeners about the change.
  }

  /// Controls auto reconnect.
  // Enables or disables the automatic reconnection feature.
  void setAutoReconnect(bool value) {
    _shouldAutoReconnect = value;
  }

  /// Updates the overall connected devices count.
  // Recalculates and updates the count of currently connected devices.
  void _updateConnectedDevicesCount() {
    int count = connectedDevices.values.where((c) => c).length; // Counts 'true' values in the connection status map.
    _connectedDevicesCount.value = count; // Updates the ValueNotifier.
  }

  // Checks if a device with the given name is currently connected.
  bool isDeviceConnected(String deviceName) =>
      connectedDevices[deviceName] ?? false; // Returns true if connected, false otherwise or if name not found.

  /// Safely notifies listeners.
  // Calls notifyListeners() only if the manager instance has not been disposed.
  void _safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  /// Schedule one rebuild 300 ms after the last call.
  // Implements a debounce mechanism for UI updates to improve performance.
  void _scheduleUIUpdate() {
    _notifyDebounce?.cancel(); // Cancels any existing pending debounce timer.
    _notifyDebounce = Timer(const Duration(milliseconds: 300), () { // Sets a new timer.
      _notifyDebounce = null; // Clears the timer reference.
      _safeNotifyListeners(); // Notifies listeners after the delay.
    });
  }

  // Initiates a Bluetooth scan for nearby BLE devices.
  Future<void> startScan({
    Duration? timeout, // Optional duration for how long the scan should run.
    String filterKeyword = 'Boxer', // Optional keyword to filter devices by name.
  }) async {
    if (isScanning) { // If a scan is already in progress.
      debugPrint("Scan already in progress");
      return; // Do not start a new scan.
    }
    isScanning = true; // Set scanning state to true.
    availableDevices.clear(); // Clear previously found devices.
    rssiValues.clear(); // Clear previous RSSI values.
    _safeNotifyListeners(); // Notify UI about the start of scanning (initial update).

    try {
      // Ensure Bluetooth adapter is turned on before starting scan.
      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first; // Waits for the first 'on' state.

      // Listen to the stream of scan results.
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) { // Process each scan result.
          final device = r.device;
          // Determine device display name (platform name or remote ID if name is empty).
          final displayName =
              device.platformName.trim().isNotEmpty
                  ? device.platformName.trim()
                  : device.remoteId.toString();

          // Apply name filter if a keyword is provided.
          if (filterKeyword.isNotEmpty &&
              !displayName.toLowerCase().contains(
                filterKeyword.toLowerCase(),
              )) {
            continue; // Skip this device if it doesn't match the filter.
          }
          // Add unique devices to the availableDevices list.
          if (!availableDevices.contains(displayName)) {
            availableDevices.add(displayName);
            debugPrint(
                "Discovered device: $displayName added to availableDevices",
            );
          }
          rssiValues[displayName] = r.rssi; // Store the RSSI value for the discovered device.
        }
        // Debounced UI update instead of immediate notifyListeners()
        _scheduleUIUpdate(); // Schedule a UI update to reflect new devices/RSSI values.
      });

      // Automatically cancel the scan result subscription when the scan completes.
      FlutterBluePlus.cancelWhenScanComplete(subscription);

      // Start the BLE scan.
      await FlutterBluePlus.startScan(
        timeout: timeout ?? const Duration(seconds: 4), // Use provided timeout or default to 4 seconds.
        androidScanMode: AndroidScanMode.lowLatency, // Use low latency scan mode on Android for faster discovery.
        androidUsesFineLocation: true, // Indicate that fine location permission is used (required for BLE on Android).
      );
      // Wait until the scan is no longer active.
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      debugPrint("Scan finished");
    } catch (e) { // Catch any errors during the scan process.
      debugPrint("Error scanning for devices: $e");
      _captureSentryException(e); // Report error to Sentry.
    } finally { // This block executes regardless of errors.
      isScanning = false; // Ensure scanning state is reset.
      _safeNotifyListeners(); // Notify UI about the end of scanning (final update).
    }
  }

  /// Mimics a scanForDevices call.
  // A convenience method to start a scan with a default 4-second timeout.
  Future<void> scanForDevices() async {
    await startScan(timeout: const Duration(seconds: 4));
  }

  /// Calculate distance from RSSI using log-distance path loss model.
  // Estimates the distance to a BLE device based on its RSSI.
  // txPower: The transmitter power level at 1 meter (calibrated value).
  // n: The path loss exponent (environment dependent, 2.0 for free space).
  double calculateDistance(int rssi, {int txPower = -59, double n = 2.0}) {
    return pow(10, ((txPower - rssi) / (10 * n))).toDouble();
  }

  /// Update the RSSI for connected devices.
  // Periodically reads and updates the RSSI values for all currently connected devices.
  Future<void> updateRSSIForConnectedDevices() async {
    // Create a set of device names from connected devices that are not null.
    final deviceNames =
        connectedBluetoothDevices.entries
            .where((entry) => entry.value != null) // Filter for non-null (connected) devices.
            .map((entry) => entry.key) // Get the device names.
            .toSet(); // Convert to a Set to avoid duplicates and for efficient lookup.

    for (final deviceName in deviceNames) { // Iterate over the names of connected devices.
      final connectedDevice = connectedBluetoothDevices[deviceName];
      if (connectedDevice != null) { // If the device object exists.
        try {
          final rssi = await connectedDevice.readRssi(); // Read the current RSSI from the device.
          rssiValues[deviceName] = rssi; // Update the stored RSSI value.
          debugPrint("Updated RSSI for $deviceName: $rssi");
        } catch (e) { // Handle errors during RSSI read.
          debugPrint("Error reading RSSI for $deviceName: $e");
          _captureSentryException(e); // Report error to Sentry.
        }
      }
    }
    _scheduleUIUpdate(); // Schedule a UI update to reflect new RSSI values.
  }

  /// Disconnect all devices.
  // Iterates through all known devices and disconnects them if they are currently connected.
  Future<void> disconnectAllDevices() async {
    for (final deviceName in connectedBluetoothDevices.keys) { // Iterate over all potential device names.
      if (connectedBluetoothDevices[deviceName] != null) { // If the device is mapped (implies connected or was recently).
        await handleDisconnectDevice(deviceName); // Call the specific disconnect handler.
      }
    }
    _safeNotifyListeners(); // Notify UI after attempting all disconnections.
  }

  /// Disconnect a device and cancel its notification subscriptions.
  // Handles the disconnection logic for a single specified device.
  Future<void> handleDisconnectDevice(String deviceName) async {
    final BluetoothDevice? device = connectedBluetoothDevices[deviceName]; // Get the BluetoothDevice object.
    if (device != null) { // Proceed if the device is known.
      setAutoReconnect(false); // Temporarily disable auto-reconnect for this intentional disconnect.
      try {
        await device.disconnect(); // Send disconnect command.
        // Wait for the connection state to confirm disconnection.
        await device.connectionState.firstWhere(
          (state) => state == BluetoothConnectionState.disconnected,
          orElse: () => BluetoothConnectionState.disconnected, // Fallback if stream ends before emitting 'disconnected'.
        );
      } catch (e, stackTrace) { // Handle errors during the disconnect call.
        debugPrint("Error disconnecting $deviceName: $e");
        _captureSentryException(e, stackTrace: stackTrace); // Report error to Sentry.
      }
      // Clear the connection and update states.
      connectedBluetoothDevices[deviceName] = null; // Remove device object.
      connectedDevices[deviceName] = false; // Set connection status to false.
      _deviceConnectionNotifiers[deviceName]?.value = false; // Update the ValueNotifier.

      // Cancel any notification subscriptions for this device.
      // Identify all notification subscriptions associated with the disconnecting device.
      final keysToRemove =
          _notificationSubscriptions.keys
              .where((key) => key.startsWith(deviceName)) // Filter by device name prefix.
              .toList();
      for (final key in keysToRemove) { // Iterate and cancel each subscription.
        await _notificationSubscriptions[key]?.cancel();
        _notificationSubscriptions.remove(key); // Remove from the map.
        debugPrint("Cancelled notification subscription for $key.");
      }
      _safeNotifyListeners(); // Notify UI of the disconnection.
    }
  }

  /// Connect to a device by name using scan results.
  // Attempts to find a device by its name via scanning and then connect to it.
  Future<void> connectToDeviceByName(String deviceName) async {
    // 1️⃣ Tell the world we’re scanning
    isScanning = true;
    _safeNotifyListeners();

    try {
      // 2️⃣ Wait for the adapter to be powered on
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on) // Waits for the adapter to be on.
          .first;
      debugPrint("Starting single-device scan for $deviceName (3s)…");

      // 3️⃣ Listen for scan results
      // Subscribe to scan results to find the specific device.
      final scanSubscription = FlutterBluePlus.scanResults.listen((
        results,
      ) async {
        for (var result in results) {
          if (result.device.platformName.trim() == deviceName) { // If the target device is found.
            debugPrint("Found $deviceName; connecting…");
            try {
              await connectToDevice(result.device); // Attempt connection.
              _deviceConnectionNotifiers[deviceName]?.value = true; // Update connection notifier.
              _safeNotifyListeners();
              debugPrint("Connected to $deviceName successfully.");
            } catch (e, st) { // Handle connection failure.
              debugPrint("Failed to connect to $deviceName: $e");
              _captureSentryException(e, stackTrace: st); // Report to Sentry.
            }
            debugPrint("Stopping scan for $deviceName early.");
            await FlutterBluePlus.stopScan(); // Stop scan as device is found.
            break; // Exit loop.
          }
        }
      }, onError: (err) => debugPrint("Scan error (single device): $err")); // Handle errors in the scan stream.
      FlutterBluePlus.cancelWhenScanComplete(scanSubscription);

      // 4️⃣ Kick off the scan
      // Start scan with a short timeout for finding a specific device.
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 3),
        androidScanMode: AndroidScanMode.lowLatency,
        androidUsesFineLocation: true,
      );
      // 5️⃣ Wait for scan to finish
      // Waits for the scan to complete.
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      debugPrint("Single-device scan for $deviceName ended.");
    } finally {
      // 6️⃣ Always clear the scanning flag, even if we errored
      isScanning = false; // Resets the scanning flag.
      _safeNotifyListeners(); // Notifies listeners.
    }
  }

  // Attempts to connect to all predefined "Boxer" devices.
  Future<void> connectAllBoxerDevices() async {
    isScanning = true;
    _safeNotifyListeners();

    _didStopScan = false; // ← reset at the top; flag for early scan stop.
    const targetDevices = {'BlueBoxer', 'RedBoxer', 'BoxerServer'}; // Set of target device names.

    // wait for adapter on…
    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on) // Waits for the Bluetooth adapter to be on.
        .first;

    // Listen to scan results.
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) { // Iterate through each scan result.
        final name = r.device.platformName.trim(); // Gets the trimmed device name.
        // Skips if the device is not a target device or is already connected.
        if (!targetDevices.contains(name) || isDeviceConnected(name)) continue;

        debugPrint("Queued connect attempt for $name");
        // Asynchronously attempts to connect to the device and potentially stops the scan if all targets are connected.
        _connectAndMaybeStop(r.device, name, targetDevices);
      }
    });
    // Ensures the subscription is cancelled when the scan completes.
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    // Starts the scan with a 15-second timeout.
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    // Waits for the scan to complete.
    await FlutterBluePlus.isScanning.where((v) => v == false).first;
    debugPrint("Multi‑device scan ended or timed out.");

    // final summary…
    // Checks which target devices were not connected.
    final notConnected = targetDevices.where((n) => !isDeviceConnected(n));
    debugPrint(
      notConnected.isNotEmpty
          ? "Some devices not connected: $notConnected" // Prints names of devices not connected.
          : "All devices connected successfully!", // Prints success message if all connected.
    );
    isScanning = false; // Resets the scanning flag.
    _safeNotifyListeners(); // Notifies listeners.
  }

  /// Helper that actually does the async connect + stopScan guard
  // Internal helper to connect to a device and stop the scan if all target devices are connected.
  Future<void> _connectAndMaybeStop(
    BluetoothDevice device, // The device to connect to.
    String name, // The name of the device.
    Set<String> targetDevices, // The set of all target device names for the current multi-connect operation.
  ) async {
    debugPrint("Attempting to connect to $name…");
    try {
      await connectToDevice(device); // Calls the main connection logic.
      debugPrint(
        isDeviceConnected(name)
            ? "Connected to $name successfully."
            : "Connection attempt for $name did not succeed.",
      );

      // Checks if all target devices are now connected.
      final allConnected = targetDevices.every(isDeviceConnected);
      if (allConnected && !_didStopScan) { // If all are connected and scan hasn't been stopped yet.
        _didStopScan = true; // ← flip your class‐level flag
        debugPrint("All targets connected → stopping scan early.");
        await FlutterBluePlus.stopScan(); // Stops the Bluetooth scan.
      }
    } catch (e, st) { // Handles connection errors.
      debugPrint("Failed to connect to $name: $e");
      _captureSentryException(e, stackTrace: st); // Reports error to Sentry.
    }
  }

  /// Connect to a device.
  // Core logic for connecting to a Bluetooth device, handling reconnection, MTU requests, and service discovery.
  Future<void> connectToDevice(BluetoothDevice device) async {
    _shouldAutoReconnect = true; // allow auto‑reconnect for this new connection
    final deviceKey = getDeviceKey(device); // Gets a unique key for the device.

    // Verify actual connection state
    // Checks if the device is already considered connected.
    if (connectedBluetoothDevices[deviceKey] != null) {
      // Verifies if the device is truly connected at the system level.
      bool reallyConnected = await _isReallyConnected(
        connectedBluetoothDevices[deviceKey]!,
      );
      if (reallyConnected) { // If truly connected, no need to proceed.
        debugPrint("Device $deviceKey is already connected.");
        return;
      } else { // If not truly connected, clear the stale reference.
        // Clear stale reference
        connectedBluetoothDevices[deviceKey] = null;
      }
    }

    try {
      // 🔧 FBP 2.0.0 requires a license argument (free or commercial) Attempts to connect to the device with a timeout. 
      await device.connect(license: License.free, timeout: const Duration(seconds: 5));
      connectedBluetoothDevices[deviceKey] = device; // Stores the connected device object.
      _updateDeviceConnectionStatus(deviceKey, true); // Updates the connection status.
      _safeNotifyListeners(); // Notifies listeners.
      await Future.delayed(const Duration(seconds: 1)); // Short delay for stability.

      // Listen for disconnection events.
      late final StreamSubscription<BluetoothConnectionState>
      disconnectionSubscription;
      // Subscribes to the device's connection state stream.
      disconnectionSubscription = device.connectionState.listen((
        connectionState,
      ) {
        if (connectionState == BluetoothConnectionState.disconnected) { // If the device disconnects.
          // Clean up notification subs on unexpected disconnect
          // Finds notification subscriptions related to this device.
          final toRemove =
              _notificationSubscriptions.keys
                  .where((k) => k.startsWith(deviceKey)) // Filters by device key prefix.
                  .toList();
          for (final charKey in toRemove) { // Iterates and cancels/removes subscriptions.
            _notificationSubscriptions[charKey]?.cancel();
            _notificationSubscriptions.remove(charKey);
            debugPrint(
                "Cancelled notification subscription for $charKey on disconnect.",
            );
          }

          _updateDeviceConnectionStatus(deviceKey, false); // Updates connection status to disconnected.
          connectedBluetoothDevices[deviceKey] = null; // Clears the device object.
          _disconnectionStreamController.add(deviceKey); // Adds device key to disconnection stream.
          disconnectionSubscription.cancel(); // Cancels this disconnection listener.
          _safeNotifyListeners(); // Notifies listeners.
          Future.delayed(const Duration(seconds: 1), () { // Schedules a reconnection attempt.
            // it wss 3 sec testing 1 second
            // Checks if app is in resumed state, not disposed, and auto-reconnect is enabled.
            if (WidgetsBinding.instance.lifecycleState ==
                    AppLifecycleState.resumed &&
                !_disposed &&
                _shouldAutoReconnect) {
              debugPrint("Attempting to reconnect to $deviceKey...");
              connectToDevice(device).catchError((e, stackTrace) { // Attempts reconnection.
                debugPrint("Reconnection to $deviceKey failed: $e");
                _captureSentryException(e, stackTrace: stackTrace); // Reports reconnection failure to Sentry.
              });
            }
          });
        }
      });

      // Requests a larger MTU (Maximum Transmission Unit) on Android for better performance.
      if (Platform.isAndroid) {
        try {
          int newMtu = await device.requestMtu(247); // Requests an MTU of 247.
          debugPrint('Requested MTU = 247, actually set to: $newMtu');
        } catch (mtuError, stackTrace) { // Handles MTU request errors.
          debugPrint('Error requesting MTU: $mtuError'); // Corrected string interpolation
          _captureSentryException(mtuError, stackTrace: stackTrace); // Reports error to Sentry.
        }
      }
      await discoverServices(); // Discovers services and characteristics on the connected device.
    } catch (e, stackTrace) { // Handles general connection errors.
      debugPrint("Error connecting to device: $e"); // Corrected string interpolation
      _updateDeviceConnectionStatus(deviceKey, false); // Updates connection status to disconnected.
      _safeNotifyListeners(); // Notifies listeners.
      _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
    }
  }

  /// Get a color based on the RSSI value.
  // Used to visually represent signal strength.
  Color getRSSIColor(int rssi) {
    if (rssi >= -30) return Colors.blue; // Strongest signal
    if (rssi >= -55) return Colors.green;
    if (rssi >= -67) return Colors.lightGreen;
    if (rssi >= -80) return Colors.yellow;
    if (rssi >= -90) return Colors.orange;
    return Colors.red; // Weakest signal
  }

  /// Helper method to check if a device is really connected.
  // Verifies the actual connection state of a BluetoothDevice object.
  Future<bool> _isReallyConnected(BluetoothDevice device) async {
    try {
      // Reads the current connection state from the device.
      final state = await device.connectionState.first;
      return state == BluetoothConnectionState.connected; // Returns true if connected.
    } catch (e) { // Catches errors (e.g., if device is no longer accessible).
      return false; // Returns false on error.
    }
  }

  // Updates the connection status for a device in internal maps and notifiers.
  void _updateDeviceConnectionStatus(String deviceName, bool status) {
    // Warns if the device name is not registered.
    if (!connectedDevices.containsKey(deviceName)) {
      debugPrint("Warning: $deviceName is not registered in connectedDevices.");
      return;
    }
    // Updates status only if it has changed.
    if (connectedDevices[deviceName] != status) {
      connectedDevices[deviceName] = status; // Updates the main connection status map.
      debugPrint('$deviceName connection status updated to: $status');
      _deviceConnectionNotifiers[deviceName]?.value = status; // Updates the ValueNotifier for this device.
      _updateConnectedDevicesCount(); // Updates the total connected devices count.
      _safeNotifyListeners(); // Notifies listeners of the change.
    }
  }

  /// Discover services on all connected devices.
  // Iterates through connected devices, discovers their services and characteristics,
  // and subscribes to notifiable characteristics.
  Future<void> discoverServices() async {
    if (_isDiscoveringServices) { // Prevents concurrent service discovery.
      debugPrint("⏳ Service discovery already in progress, skipping new call.");
      return;
    }
    _isDiscoveringServices = true; // Sets the discovery flag.
    debugPrint("🔄 discoverServices() called");
    try {
      // Creates a list of futures for discovering services on each connected device.
      List<Future<void>> discoveryFutures =
          connectedBluetoothDevices.entries.map((entry) async {
            final deviceName = entry.key; // Device name.
            final BluetoothDevice? connectedDevice = entry.value; // BluetoothDevice object.
            if (connectedDevice == null) { // Skips if device object is null.
              debugPrint("⚠️ Device $deviceName is null. Skipping.");
              return;
            }
            debugPrint("🔍 Discovering services for device: $deviceName");
            try {
              // Discovers services for the current device.
              List<BluetoothService> servicesList =
                  await connectedDevice.discoverServices();
              debugPrint(
                  "📡 Discovered ${servicesList.length} services for $deviceName",
              );
              for (var service in servicesList) { // Iterates through discovered services.
                for (var characteristic in service.characteristics) { // Iterates through characteristics of each service.
                  if (characteristic.properties.notify) { // Checks if the characteristic supports notifications.
                    // Creates a unique key for the characteristic subscription.
                    String charKey = '$deviceName-${characteristic.uuid}';
                    // Skips if already subscribed to this characteristic.
                    if (_notificationSubscriptions.containsKey(charKey)) {
                      debugPrint(
                          "⚠️ Listener already exists for $charKey, skipping.",
                      );
                      continue;
                    }
                    debugPrint(
                        "✅ Subscribing to characteristic ${characteristic.uuid} for $deviceName.",
                    );
                    // Enables notifications for the characteristic.
                    await characteristic.setNotifyValue(true);
                    // Short delay after enabling notifications.
                    await Future.delayed(Duration(milliseconds: 400));
                    // Listens to the characteristic's value stream.
                    var subscription = characteristic.lastValueStream.listen(
                      (value) => _handleNotification(value, deviceName), // Handles incoming notification data.
                      onError: (error, stackTrace) { // Handles errors in the notification stream.
                        debugPrint(
                            "❌ Error in notification stream for $deviceName: $error",
                        );
                        debugPrint(stackTrace.toString());
                        _captureSentryException(error, stackTrace: stackTrace); // Reports error to Sentry.
                      },
                    );
                    // Stores the subscription.
                    _notificationSubscriptions[charKey] = subscription;
                    debugPrint(
                        "👂 Active Listeners Count: ${_notificationSubscriptions.length}",
                    );
                  }
                }
              }
            } catch (e, stackTrace) { // Handles errors during service discovery for a specific device.
              debugPrint("❌ Error discovering services for $deviceName: $e");
              _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
            }
          }).toList();
      // Waits for all service discovery futures to complete.
      await Future.wait(discoveryFutures);
    } finally {
      _isDiscoveringServices = false; // Resets the discovery flag.
    }
  }

  /// Process incoming notifications.
  // Decodes, parses, and processes data received from BLE characteristic notifications.
  void _handleNotification(List<int> value, String deviceName) async {
    if (_disposed) return; // Exits if the manager is disposed.
    try {
      final decodedMessage = utf8.decode(value); // Decodes the byte list to a UTF-8 string.
      debugPrint("📩 Received notification from $deviceName: $decodedMessage");
      try {
        // Attempts to parse the message as JSON (e.g., for "RoundState" messages).
        final dynamic parsed = json.decode(decodedMessage);
        if (parsed is Map<String, dynamic> &&
            parsed["RoundState"] == "Completed") { // If it's a "RoundState: Completed" message.
          _timerState?.endMatch(); // Ends the match via TimerState.
        }
      } catch (jsonError) {
        // Ignore JSON parsing errors for messages not in JSON format.
      }
      // Extracts data fields from the message string using regex.
      final punchCount = _extractPunchCount(decodedMessage);
      final timestamp = _extractTimestamp(decodedMessage);
      String extractedDevice = _extractDevice(decodedMessage);
      // Uses the deviceName from the notification source if regex extraction fails.
      final deviceStr =
          (extractedDevice == "UnknownDevice") ? deviceName : extractedDevice;
      final sensorValue = _extractSensorValue(decodedMessage);

      // Proceeds if all required data fields are successfully extracted.
      if (punchCount != null && timestamp != null && sensorValue != null) {
        // Determines the "opposite" device (e.g., if BlueBoxer sent, opposite is RedBoxer).
        String oppositeDevice =
            (deviceStr == "BlueBoxer") ? "RedBoxer" : "BlueBoxer";
        // Creates a DataRow for UI display.
        final newRow = DataRow(
          cells: [
            DataCell(Center(child: Text(deviceStr))),
            DataCell(Center(child: Text(oppositeDevice))),
            DataCell(Center(child: Text(punchCount.toString()))),
            DataCell(Center(child: Text(timestamp))),
            DataCell(Center(child: Text(sensorValue))),
          ],
        );
        rows.add(newRow); // Adds the new row to the internal list.
        if (!_messageStreamController.isClosed) { // Checks if the message stream controller is still active.
          _messageStreamController.add(List.from(rows)); // Adds the updated list to the message stream.
        }
        _scheduleUIUpdate(); // ← debounce rapid‐fire notifications

        // Creates a map of the raw message data.
        final msgMap = {
          'device': deviceStr,
          'punchBy': oppositeDevice,
          'punchCount': punchCount.toString(),
          'timestamp': timestamp,
          'sensorValue': sensorValue,
        };
        _rawMsgs.add(msgMap); // Adds the raw message map to the internal list.
        if (!_rawController.isClosed) { // Checks if the raw message stream controller is still active.
           _rawController.sink.add(List.from(_rawMsgs)); // Adds the updated list to the raw message stream.
        }

        final localRoundId = _currentRoundId; // Gets the current round ID.
        final localMatchId = _currentMatchId; // Gets the current match ID.
        // always insert into messages; matchId can be null (will be stored as NULL)
        // Sends data to BoxerServer (if applicable) and inserts into the database.
        _sendDataAndInsertToDatabase(
          deviceStr,
          oppositeDevice,
          punchCount,
          timestamp,
          sensorValue,
          localRoundId ?? 0, // Uses 0 if round ID is null.
          localMatchId,
        );
      }
    } catch (e, stackTrace) { // Handles errors during notification processing.
      if (!_disposed) { // Checks if not disposed before logging.
        debugPrint("❌ 🔴 Error processing notification from $deviceName: $e");
        debugPrint(stackTrace.toString());
        _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
      }
    }
  }

  /// Send data and insert into the database concurrently.
  // Manages sending data to the BoxerServer (if a match is active) and inserting data into the local database.
  void _sendDataAndInsertToDatabase(
    String deviceStr,
    String oppositeDevice,
    String punchCount,
    String timestamp,
    String sensorValue,
    int roundId,
    int? matchId,
  ) {
  
    // Always insert into messages (with matchId == null storing as NULL)
    final futures = <Future<void>>[ // List to hold asynchronous operations.
      // Adds the database insertion operation to the list.
      _insertDataToDatabase(
        deviceStr,
        oppositeDevice,
        punchCount,
        timestamp,
        sensorValue,
        roundId,
        matchId,
      ),
    ];

    // Only send to server if match is active
    if (matchId != null) { // If a match is currently active (matchId is not null).
      // Adds the operation to send data to BoxerServer to the list.
      futures.add(
        _sendDataToBoxerServer(
          deviceStr,
          oppositeDevice,
          punchCount,
          timestamp,
          sensorValue,
        ),
      );
    }

    // fire both off concurrently
    Future.wait(futures); // Executes all operations in the list concurrently.
  }

  /// Insert data into the database for StartMatch mode.
  // Inserts a message record into the local SQLite database.
  Future<void> _insertDataToDatabase(
    String deviceStr,
    String oppositeDevice,
    String punchCount,
    String timestamp,
    String sensorValue,
    int roundId,
    int? matchId,
  ) async {
    try {
      // Calls the DatabaseHelper to insert the message.
      await dbHelper.insertMessage(
        deviceStr,
        oppositeDevice,
        punchCount,
        timestamp,
        sensorValue,
        roundId,
        matchId,
      );
    } catch (e, stackTrace) { // Handles errors during database insertion.
      debugPrint("❌ 💾 🔴 Error inserting message into DB: $e");
      _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
    }
  }

  /// Bulk‑load a bunch of historical rows from the 'messages' table.
  ///
  /// Internally converts each DB row into a DataRow, pushes it
  /// to the stream, and *debounces* the UI rebuilds to at most
  /// one every 300 ms.
  // Loads message history from the database, optionally filtered by match ID.
  Future<void> loadHistory({int? matchId}) async {
    _rawMsgs.clear(); // Clears existing raw messages.
    // 1) Read the raw message maps from SQLite.
    //    If you want *all* messages, call fetchMessages();
    //    if only for a match, call fetchMessagesByMatchId(matchId).
    // Fetches messages from the database.
    final List<Map<String, dynamic>> history =
        matchId == null
            ? await dbHelper.fetchMessages() // Fetches all messages if matchId is null.
            : await dbHelper.fetchMessagesByMatchId(matchId); // Fetches messages for a specific match.

    // 2) For each DB row, build a DataRow and push it.
    for (final msg in history) { // Iterates through fetched messages.
      // Creates a DataRow from the message data.
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
      rows.add(row); // Adds the DataRow to the internal list.
      if (!_messageStreamController.isClosed) {
         _messageStreamController.add(List.from(rows)); // Adds the updated list to the message stream.
      }


      // Record raw msg and emit
      _rawMsgs.add(msg); // Adds the raw message map to the internal list.
      if (!_rawController.isClosed) {
        _rawController.sink.add(List.from(_rawMsgs)); // Adds the updated list to the raw message stream.
      }


      // ← instead of notifyListeners(), debounce via your existing helper
      _scheduleUIUpdate(); // Schedules a debounced UI update.
    }

    // 3) One final immediate build so UI definitely ends up up‑to‑date.
    _safeNotifyListeners(); // Ensures a final UI update.
  }

  /// Helper function to send data to BoxerServer.
  // Prepares and sends data to the 'BoxerServer' device if it's connected.
  Future<void> _sendDataToBoxerServer(
    String deviceStr,
    String oppositeDevice,
    String punchCount,
    String timestamp,
    String sensorValue,
  ) async {
    // Checks if BoxerServer is connected.
    if (!isDeviceConnected("BoxerServer")) {
      debugPrint(
          "❌ 🔴 BoxerServer not connected. Skipping sendDataToBoxerServer.",
      );
      return; // Exits if BoxerServer is not connected.
    }
    try {
      // Calls the main method to send data specifically to BoxerServer.
      await sendDataToBoxerServer(
        deviceStr: deviceStr,
        oppositeDevice: oppositeDevice,
        punchCount: punchCount,
        timestamp: timestamp,
        sensorValue: sensorValue,
      );
    } catch (e, stackTrace) { // Handles errors during sending.
      debugPrint("➡️ ❌ 🔴 Error sending data to BoxerServer: $e");
      _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
    }
  }

  // Sends a message to a connected device.
  // Prioritizes using a cached writable characteristic, falls back to service discovery if needed.
  Future<void> sendMessageToConnectedDevice(String message) async {
    final trimmedMessage = message.trim(); // Trims whitespace from the message.
    // Refuses to send empty or "[]" messages.
    if (trimmedMessage.isEmpty || trimmedMessage == "[]") {
      debugPrint("Refusing to send empty/bracket message.");
      return;
    }
    // If a writable characteristic is already cached.
    if (writableCharacteristic != null) {
      try {
        final dataToSend = utf8.encode(trimmedMessage); // Encodes the message to UTF-8 bytes.
        // Writes data to the cached characteristic.
        await writableCharacteristic!.write(dataToSend, withoutResponse: false);
        debugPrint("Message sent via cached characteristic: $trimmedMessage");
        return; // Exits after successful send.
      } catch (e, stackTrace) { // Handles errors sending via cached characteristic.
        debugPrint("Error sending message via cached characteristic: $e");
        _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
        debugPrint("Falling back to service discovery.");
        // No return here, will fall through to service discovery.
      }
    } else { // If no cached characteristic.
      debugPrint(
          "No cached writable characteristic found. Falling back to service discovery.",
      );
    }

    // Fallback: find the first available connected device.
    BluetoothDevice? fallbackDevice;
    String fallbackDeviceName = "";
    for (final entry in connectedBluetoothDevices.entries) { // Iterates through connected devices.
      if (entry.value != null) { // If a device is found.
        fallbackDevice = entry.value;
        fallbackDeviceName = entry.key;
        break; // Uses the first one found.
      }
    }

    // If no connected device is available for fallback.
    if (fallbackDevice == null) {
      debugPrint("No connected devices available for fallback.");
      return;
    }

    // Attempts to send the message to the fallback device via service discovery.
    try {
      await _sendMessageToDevice(
        fallbackDevice,
        fallbackDeviceName,
        trimmedMessage,
      );
    } catch (e, stackTrace) { // Handles errors during fallback send.
      debugPrint("Error sending message via service discovery: $e");
      _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
    }
  }

  // Sends a message to a specific device by discovering its writable characteristics.
  Future<void> _sendMessageToDevice(
    BluetoothDevice device, // The target Bluetooth device.
    String deviceName, // The name of the target device.
    String message, // The message string to send.
  ) async {
    try {
      final services = await device.discoverServices(); // Discovers services on the device.
      final List<Future<void>> writeFutures = []; // List to hold write operations.
      for (var service in services) { // Iterates through services.
        for (var characteristic in service.characteristics) { // Iterates through characteristics.
          if (characteristic.properties.write) { // Checks if the characteristic is writable.
            debugPrint(
                "Discovered writable characteristic ${characteristic.uuid} on $deviceName",
            );
            // Adds the write operation to the list of futures.
            writeFutures.add(
              characteristic
                  .write(utf8.encode(message), withoutResponse: false) // Writes the message.
                  .then( // On successful write.
                    (_) => debugPrint(
                        "Message sent to $deviceName via ${characteristic.uuid}: $message",
                    ),
                  )
                  .catchError((error, stackTrace) { // On write error.
                    debugPrint(
                        "Error sending message via ${characteristic.uuid} on $deviceName: $error",
                    );
                    _captureSentryException(error, stackTrace: stackTrace); // Reports error to Sentry.
                  }),
            );
          }
        }
      }
      // If no writable characteristics were found.
      if (writeFutures.isEmpty) {
        debugPrint(
            "No writable characteristics found on $deviceName to send message.",
        );
      } else { // If writable characteristics were found, wait for all writes to complete.
        await Future.wait(writeFutures);
      }
    } catch (e, stackTrace) { // Handles errors during service discovery or message sending.
      debugPrint("Error in _sendMessageToDevice for $deviceName: $e");
      _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
    }
  }

  // Sends a message to all currently connected Bluetooth devices.
  Future<void> sendMessageToAllConnectedDevices(String message) async {
    final trimmedMessage = message.trim(); // Trims the message.
    // Refuses to send empty or "[]" messages.
    if (trimmedMessage.isEmpty || trimmedMessage == "[]") {
      debugPrint("Refusing to send empty/bracket message.");
      return;
    }
    List<Future<void>> sendFutures = []; // List to hold send operations.
    for (var entry in connectedBluetoothDevices.entries) { // Iterates through connected devices map.
      final deviceName = entry.key;
      final BluetoothDevice? device = entry.value;
      if (device != null) { // If the device object exists (is connected).
        // Adds the send operation to the list.
        sendFutures.add(
          _sendMessageToDevice(device, deviceName, trimmedMessage).catchError((
            e,
            stackTrace,
          ) { // Handles errors for individual device sends.
            debugPrint("Error sending message to $deviceName: $e");
            _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
          }),
        );
      } else { // If device object is null.
        debugPrint("Device $deviceName is not connected.");
      }
    }
    // If no devices were available to send to.
    if (sendFutures.isEmpty) {
      debugPrint("No connected devices available to send the message.");
      return;
    }
    await Future.wait(sendFutures); // Waits for all send operations to complete.
  }

  // Sends structured data specifically to the 'BoxerServer' device.
  Future<void> sendDataToBoxerServer({
    required String deviceStr,
    required String oppositeDevice,
    required String punchCount,
    required String timestamp,
    required String sensorValue,
  }) async {
    // Creates a map of the data to be sent.
    final dataMap = {
      "deviceStr": deviceStr,
      "oppositeDevice": oppositeDevice,
      "punchCount": punchCount,
      "timestamp": timestamp,
      "sensorValue": sensorValue,
    };
    final dataMessage = jsonEncode(dataMap); // Encodes the map to a JSON string.
    debugPrint("Sending data to BoxerServer (JSON): $dataMessage");

    final boxerServerDevice = connectedBluetoothDevices["BoxerServer"]; // Gets the BoxerServer device object.
    if (boxerServerDevice == null) { // If BoxerServer is not connected.
      debugPrint("🚀 ❌ BoxerServer is not connected. Cannot send data.");
      return;
    }
    try {
      // Sends the JSON message to the BoxerServer device.
      await _sendMessageToDevice(boxerServerDevice, "BoxerServer", dataMessage);
      debugPrint("📤 ➡️ Data sent to BoxerServer successfully.");
    } catch (e, stackTrace) { // Handles errors during sending.
      debugPrint("❌ Error sending data to BoxerServer: $e");
      _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
    }
  }

  @override
  // Called when the BluetoothManager instance is being disposed.
  // Cleans up resources like timers, stream controllers, and subscriptions.
  void dispose() {
    _notifyDebounce?.cancel(); // Cancels any active UI debounce timer.
    try {
      _messageStreamController.close(); // Closes the message stream controller.
      _disconnectionStreamController.close(); // Closes the disconnection stream controller.
      _rawController.close(); // Closes the raw message stream controller.
      // Cancels all active notification subscriptions.
      _notificationSubscriptions.forEach((_, subscription) {
        subscription.cancel();
      });
      _notificationSubscriptions.clear(); // Clears the map of subscriptions.
    } catch (e, stackTrace) { // Handles errors during resource cleanup.
      debugPrint("Error during BluetoothManager dispose: $e");
      _captureSentryException(e, stackTrace: stackTrace); // Reports error to Sentry.
    }
    // Disposes all device connection ValueNotifiers.
    _deviceConnectionNotifiers.forEach((_, notifier) => notifier.dispose());
    // Disposes the connected devices count ValueNotifier.
    _connectedDevicesCount.dispose();
    _disposed = true; // Sets the disposed flag to true.
    super.dispose(); // Calls the dispose method of the superclass (ChangeNotifier).
  }
}

