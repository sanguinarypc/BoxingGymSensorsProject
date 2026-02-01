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

  static const String webServerUrl =
      "https://boxing-dashboard.ndimitrakarakos.gr/api/data";

  //   static const String webServerUrl = String.fromEnvironment(
  // 'WEB_SERVER_URL',
  // defaultValue: 'https://boxing-dashboard.ndimitrakarakos.gr/api/data',
  // );
  // flutter run --dart-define=WEB_SERVER_URL=http://192.168.1.3:3000/api/data
  // static const String webServerUrl = "https://ndim.codecraft.gr/receiver.php";
  // static const String webServerUrl = "https://ndim.codecraft.gr/api/data";
  // static const String webServerUrl = "http://192.168.1.3:3000/api/data";
  // static const String webServerUrl = "http://192.168.1.3:3000/api/data";
}
