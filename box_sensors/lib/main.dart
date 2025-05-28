// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/Themes/theme_provider.dart';
import 'package:box_sensors/widgets/my_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Request all necessary permissions once at startup.
Future<void> requestAllPermissionsOnce() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
    Permission.ignoreBatteryOptimizations,
  ].request();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await requestAllPermissionsOnce();

  // Initialize theme.
  final themeProvider = ThemeProvider();
  await themeProvider.initTheme();

  // Force portrait orientation.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Override error widget.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    Sentry.captureException(details.exception, stackTrace: details.stack);
    return Scaffold(
      appBar: AppBar(title: const Text("Oops!")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text(
              "Something went wrong.\nPlease restart the app.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    Sentry.captureException(details.exception, stackTrace: details.stack);
    FlutterError.presentError(details);
  };

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://65073676965c01d4d4267a6c1b386ed8@o4509046173597696.ingest.de.sentry.io/4509046194241616';
      options.sendDefaultPii = true;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.experimental.replay.sessionSampleRate = 1.0;
      options.experimental.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () {
      runZonedGuarded(
        () {
          runApp(
            ProviderScope(
              // Override the theme provider with the pre-initialized instance.
              overrides: [
                themeProviderProvider.overrideWith((ref) => themeProvider),
              ],
              child: SentryWidget(child: const MyApp()),
            ),
          );
        },
        (error, stackTrace) {
          Sentry.captureException(error, stackTrace: stackTrace);
        },
      );
    },
  );
}
