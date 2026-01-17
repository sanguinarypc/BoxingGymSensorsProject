import 'package:flutter/material.dart';

class UIUtils {
  /// Get a color based on the RSSI value.
  // Used to visually represent signal strength.
  static Color getRSSIColor(int rssi) {
    if (rssi >= -30) return Colors.blue; // Strongest signal
    if (rssi >= -55) return Colors.green;
    if (rssi >= -67) return Colors.lightGreen;
    if (rssi >= -80) return Colors.yellow;
    if (rssi >= -90) return Colors.orange;
    return Colors.red; // Weakest signal
  }
}
