import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:box_sensors/utils/system_ui.dart';
import 'package:box_sensors/services/riverpod_imports.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/Themes/theme_provider.dart';
import 'package:box_sensors/widgets/my_app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:box_sensors/utils/orientation_gate.dart'; // OrientationGate
import 'package:box_sensors/utils/ble_permissions.dart';

// ---------------------------
// Build-time config (dart-define)
// ---------------------------

// “Ενιαίο” DSN (αν θες το πιο απλό): --dart-define=SENTRY_DSN=...
const String sentryDsnSingle =
    String.fromEnvironment('SENTRY_DSN', defaultValue: '');

// Προαιρετικό staging/prod switch:
// --dart-define=APP_ENV=prod|staging|dev
// --dart-define=SENTRY_DSN_PROD=...
// --dart-define=SENTRY_DSN_STAGING=...
// --dart-define=SENTRY_DSN_DEV=...
const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
const String sentryDsnProd =
    String.fromEnvironment('SENTRY_DSN_PROD', defaultValue: '');
const String sentryDsnStaging =
    String.fromEnvironment('SENTRY_DSN_STAGING', defaultValue: '');
const String sentryDsnDev =
    String.fromEnvironment('SENTRY_DSN_DEV', defaultValue: '');

String _pickSentryDsnFromDartDefine() {
  // 1) Αν έχει δοθεί το “single” DSN, το χρησιμοποιούμε και τελειώσαμε.
  if (sentryDsnSingle.isNotEmpty) return sentryDsnSingle;

  // 2) Αλλιώς, αν δουλεύεις με APP_ENV + ξεχωριστά DSNs:
  final env = appEnv.trim().toLowerCase();
  switch (env) {
    case 'staging':
      return sentryDsnStaging;
    case 'dev':
      return sentryDsnDev;
    case 'prod':
    default:
      return sentryDsnProd;
  }
}

/// Request all necessary permissions once at startup.
/// [PATCHED]: Κρατάμε το ίδιο API, αλλά το delegate γίνεται στον helper μας
/// ώστε σε Android 12+ να μη ζητά Location άδεια, ενώ σε Android ≤11 να γίνεται
/// fallback αυτόματα (χωρίς να αλλάξουμε καμία άλλη ροή).
Future<void> requestAllPermissionsOnce() async {
  if (Platform.isAndroid) {
    // Ζήτα SCAN/CONNECT σε Android 12+ και fallback σε Location για ≤11.
    await BlePermissions.ensure();

    // Ό,τι άλλο έχεις ως “εξτρά” (π.χ. εξαιρέσεις από Doze) μένει ως έχει:
    await [Permission.ignoreBatteryOptimizations].request();
  }
  // iOS ή άλλα platforms: δεν ζητάμε κάτι εδώ (μένει όπως πριν ή και κενό).
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemUi.configure();

  // Φορτώνουμε .env αν υπάρχει (για ό,τι άλλο χρησιμοποιείς).
  // Αν λείπει, ΔΕΝ θέλουμε να ρίξει την εφαρμογή.
  // try {
  //   await dotenv.load(fileName: ".env");
  // } catch (e) {
  //   if (!kReleaseMode) {
  //     debugPrint('dotenv.load failed (optional): $e');
  //   }
  // }

  await requestAllPermissionsOnce();

  // Initialize theme (we’ll inject this instance via override).
  final themeProvider = ThemeProvider();
  await themeProvider.initTheme();

  // ---------------------------
  // Resolve Sentry DSN safely
  // ---------------------------
  final dsnFromDefines = _pickSentryDsnFromDartDefine();
  final effectiveDsn = dsnFromDefines;
  // final dsnFromDotenv = dotenv.env['SENTRY_DSN'] ?? '';
  // final effectiveDsn = dsnFromDefines.isNotEmpty ? dsnFromDefines : dsnFromDotenv;
   
  final bool sentryEnabled = effectiveDsn.trim().isNotEmpty;

  // Error UI + Sentry Override error widget.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (sentryEnabled) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Oops!")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
    if (sentryEnabled) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
    FlutterError.presentError(details);
  };

  await SentryFlutter.init(
    (options) {
      // ✅ Αν δεν υπάρχει DSN, το Sentry μένει OFF χωρίς crash.
      options.dsn = sentryEnabled ? effectiveDsn.trim() : null;

      // ✅ Πιο ασφαλές default (GDPR/PII).
      options.sendDefaultPii = false;

      // Βοηθάει να ξεχωρίζεις prod/staging στο Sentry UI.
      options.environment = appEnv;

      // Κρατάω τις τωρινές σου τιμές για να μη σου αλλάξω behavior.
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;

      // Session Replay (όπως το είχες)
      options.replay.sessionSampleRate = 1.0;
      options.replay.onErrorSampleRate = 1.0;

      if (!kReleaseMode) {
        debugPrint(
          'Sentry enabled: $sentryEnabled | APP_ENV=$appEnv | DSN source: '
          '${dsnFromDefines.isNotEmpty ? 'dart-define' : 'none'}',
        );
      }
    },
    appRunner: () {
      runZonedGuarded(
        () => runApp(
          ProviderScope(
            retry: (_, _) => null,
            overrides: [
              themeProviderProvider.overrideWith((_) => themeProvider),
            ],
            child: SentryWidget(
              child: OrientationGate(
                child: const MyApp(),
              ),
            ),
          ),
        ),
        (error, stack) {
          if (sentryEnabled) {
            Sentry.captureException(error, stackTrace: stack);
          }
        },
      );
    },
  );
}












// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// import 'package:box_sensors/utils/system_ui.dart';
// import 'package:box_sensors/services/riverpod_imports.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/Themes/theme_provider.dart';
// import 'package:box_sensors/widgets/my_app.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';
// import 'package:box_sensors/utils/orientation_gate.dart';  // ΝΕΟ: OrientationGate
// // ⬅️ ΝΕΟ import για τον helper BLE permissions
// import 'package:box_sensors/utils/ble_permissions.dart';

// /// Request all necessary permissions once at startup.
// /// [PATCHED]: Κρατάμε το ίδιο API, αλλά το delegate γίνεται στον helper μας
// /// ώστε σε Android 12+ να μη ζητά Location άδεια, ενώ σε Android ≤11 να γίνεται
// /// fallback αυτόματα (χωρίς να αλλάξουμε καμία άλλη ροή).
// Future<void> requestAllPermissionsOnce() async {
//   if (Platform.isAndroid) {
//     // Ζήτα SCAN/CONNECT σε Android 12+ και fallback σε Location για ≤11.
//     await BlePermissions.ensure();

//     // Ό,τι άλλο έχεις ως “εξτρά” (π.χ. εξαιρέσεις από Doze) μένει ως έχει:
//     await [Permission.ignoreBatteryOptimizations].request();
//   }
//   // iOS ή άλλα platforms: δεν ζητάμε κάτι εδώ (μένει όπως πριν ή και κενό).
// }

// /// (Παραμένουν όλα ίδια από εδώ και κάτω)
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await SystemUi.configure();

//   await dotenv.load(fileName: ".env");
//   await requestAllPermissionsOnce();

//   // Initialize theme (we’ll inject this instance via override).
//   final themeProvider = ThemeProvider();
//   await themeProvider.initTheme();

//   // ❌ ΑΦΑΙΡΕΘΗΚΕ το global lock:
//   // await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   //
//   // Το OrientationGate θα εφαρμόσει προσαρμοστική πολιτική
//   // (κινητά => πορτραίτο μόνο, tablets => ελεύθερα).

//   // Error UI + Sentry  Override error widget.
//   ErrorWidget.builder = (FlutterErrorDetails details) {
//     Sentry.captureException(details.exception, stackTrace: details.stack);
//     return Scaffold(
//       appBar: AppBar(title: const Text("Oops!")),
//       body: const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 80, color: Colors.red),
//             SizedBox(height: 16),
//             Text(
//               "Something went wrong.\nPlease restart the app.",
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   };

//   FlutterError.onError = (FlutterErrorDetails details) {
//     Sentry.captureException(details.exception, stackTrace: details.stack);
//     FlutterError.presentError(details);
//   };

//   await SentryFlutter.init(
//     (options) {
//       final dsn = dotenv.env['SENTRY_DSN'];
//       if (dsn == null) {
//         throw Exception(
//             'SENTRY_DSN not found in .env file. Make sure it is set and the .env file is in your pubspec.yaml assets.');
//       }
//       options.dsn = dsn;
//       options.sendDefaultPii = true;
//       options.tracesSampleRate = 1.0;
//       options.profilesSampleRate = 1.0;

//       // Session Replay
//       options.replay.sessionSampleRate = 1.0;
//       options.replay.onErrorSampleRate = 1.0;
//     },
//     appRunner: () {
//       runZonedGuarded(
//         () => runApp(
//           ProviderScope(
//             retry: (_, _) => null,
//             overrides: [
//               themeProviderProvider.overrideWith((_) => themeProvider),
//             ],
//             // 👉 ΤΥΛΙΓΟΥΜΕ εδώ το MyApp
//             child: SentryWidget(
//               child: OrientationGate(
//                 child: const MyApp(),
//               ),
//             ),
//           ),
//         ),
//         (error, stack) => Sentry.captureException(error, stackTrace: stack),
//       );
//     },
//   );
// }