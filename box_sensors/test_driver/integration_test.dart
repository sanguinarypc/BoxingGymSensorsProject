// test_driver/integration_test.dart
import 'dart:io';
// import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? args,
        ]) async {
          // Use absolute path to ensure we write where expected
          final currentDir = Directory.current.path;
          if (kDebugMode) {
            print('DEBUG-DRIVER: Current dir: $currentDir');
          }

          final File image = File(
            '$currentDir/screenshots/$screenshotName.png',
          );
          if (kDebugMode) {
            print('DEBUG-DRIVER: Saving screenshot to: ${image.path}');
          }

          try {
            image.parent.createSync(recursive: true);
            image.writeAsBytesSync(screenshotBytes);
            if (kDebugMode) {
              print('DEBUG-DRIVER: Successfully saved ${image.path}');
            }
            return true;
          } catch (e) {
            if (kDebugMode) {
              print('DEBUG-DRIVER: Error saving screenshot: $e');
            }
            return false;
          }
        },
  );
}
