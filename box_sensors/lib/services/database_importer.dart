import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Call these methods before you ever use DatabaseHelper.database.
class DatabaseImporter {
  DatabaseImporter._();
  static final instance = DatabaseImporter._();

  /// Overwrites your app’s on-device DB with the one at [sourceFile].
  Future<void> importFromFile(File sourceFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'messages.db');

    // Close and delete any existing DB so the copy is clean
    if (await databaseExists(dbPath)) {
      await deleteDatabase(dbPath);
    }

    // Copy it in place
    await sourceFile.copy(dbPath);
  }

  /// Overwrites your app’s on-device DB with an asset packaged in your APK/AAB.
  ///
  /// Example: if your asset is at assets/prebuilt/messages.db, call:
  ///   await DatabaseImporter.instance.importFromAsset('assets/prebuilt/messages.db');
  Future<void> importFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'messages.db');

    if (await databaseExists(dbPath)) {
      await deleteDatabase(dbPath);
    }

    final file = File(dbPath);
    await file.writeAsBytes(bytes, flush: true);
  }

  /// After import, just call your normal DatabaseHelper(); it will open the new file.
}
