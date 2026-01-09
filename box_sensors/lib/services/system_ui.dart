// lib/services/system_ui.dart
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

final class SystemUi {
  static bool _done = false;

  static Future<void> configure({
    Brightness statusIcons = Brightness.light,
    Brightness navIcons = Brightness.light,
  }) async {
    if (_done) return;
    _done = true;

    // ANDROID: no-op (το κάνει το Jetpack στο MainActivity)
    if (Platform.isAndroid) return;  // if (!Platform.isIOS) return; // τρέχει αποκλειστικά σε iOS

    // iOS: edge-to-edge + μόνο φωτεινότητα εικονιδίων
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // ignore
    }

    final style = SystemUiOverlayStyle(
      statusBarIconBrightness: statusIcons,
      systemNavigationBarIconBrightness: navIcons,
      statusBarBrightness: statusIcons == Brightness.light
          ? Brightness.dark
          : Brightness.light,
      // ⚠️ ΚΑΘΟΛΟΥ statusBarColor / navigationBarColor / divider
    );

    // ΕΠΙΣΤΡΕΦΕΙ void → ΧΩΡΙΣ await
    SystemChrome.setSystemUIOverlayStyle(style);
  }
}
