class DeviceConfig {
  static const String blueBoxer = 'BlueBoxer';
  static const String redBoxer = 'RedBoxer';
  static const String boxerServer = 'BoxerServer';

  static const List<String> allDevices = [blueBoxer, redBoxer, boxerServer];

  /// Flag to detect if we are running in integration test mode.
  /// Use: flutter drive --dart-define=INTEGRATION_TEST=true ...
  static const bool isIntegrationTest = bool.fromEnvironment(
    'INTEGRATION_TEST',
  );
}
