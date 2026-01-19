import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/utils/device_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Handles the distribution of sensor data to external systems (Web Server)
/// and internal storage (SQLite Database).
class DataDistributionService {
  final DatabaseHelper _dbHelper;

  DataDistributionService(this._dbHelper);

  void _captureSentryException(Object error, {StackTrace? stackTrace}) {
    if (!Sentry.isEnabled) return;
    Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Inserts data into the database for StartMatch mode.
  Future<void> saveToDatabase({
    required String deviceStr,
    required String oppositeDevice,
    required String punchCount,
    required String timestamp,
    required String sensorValue,
    required int roundId,
    required int? matchId,
  }) async {
    try {
      await _dbHelper.insertMessage(
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
      _captureSentryException(e, stackTrace: stackTrace);
    }
  }

  /// Sends data to the external Web Dashboard via HTTP POST.
  Future<void> sendToWebServer({
    required String deviceStr,
    required String oppositeDevice,
    required String punchCount,
    required String timestamp,
    required String sensorValue,
    required int roundId,
  }) async {
    try {
      final uri = Uri.parse(DeviceConfig.webServerUrl);
      final body = jsonEncode({
        "deviceStr": deviceStr,
        "oppositeDevice": oppositeDevice,
        "punchCount": punchCount,
        "timestamp": timestamp,
        "sensorValue": sensorValue,
        "roundId": roundId,
      });

      debugPrint("🌐 Sending data to Web Server ($uri): $body");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ 🌐 Data sent to Web Server successfully.");
      } else {
        debugPrint(
          "⚠️ 🌐 Web Server returned status ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      debugPrint("❌ 🌐 Error sending specific data to Web Server: $e");
      // Optional: report to Sentry if critical
    }
  }

  /// Sends a request to the Web Server to clear/reset the dashboard data.
  Future<void> resetServerData() async {
    try {
      // Append ?action=clear to the base URL
      final baseUri = Uri.parse(DeviceConfig.webServerUrl);
      final uri = baseUri.replace(
        queryParameters: {...baseUri.queryParameters, 'action': 'clear'},
      );

      debugPrint("🧹 Requesting Web Server Reset: $uri");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        debugPrint("✅ 🧹 Web Server data cleared successfully.");
      } else {
        debugPrint(
          "⚠️ 🧹 Failed to clear Web Server data. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("❌ 🧹 Error resetting Web Server data: $e");
    }
  }
}
