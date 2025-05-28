// lib/widgets/settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:box_sensors/widgets/android_battery_setting_card.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/settings_header.dart';
import 'package:box_sensors/widgets/settings_form_card.dart';
import 'package:box_sensors/widgets/card_wdgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:box_sensors/services/database_importer.dart';
import 'package:path_provider/path_provider.dart'; // getApplicationDocumentsDirectory
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
// import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/services.dart';

/// Allows parent widgets to request settings reload
mixin SettingsReloadable on State<SettingsScreen> {
  Future<void> reloadSettings();
}

class SettingsScreen extends ConsumerStatefulWidget {
  final void Function(int) onTabChange;
  const SettingsScreen({super.key, required this.onTabChange});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SettingsReloadable {
  // Controllers
  final fsrSensitivityController = TextEditingController(text: '800');
  final fsrThresholdController = TextEditingController(text: '200');
  final roundsController = TextEditingController(text: '1');
  final roundTimeController = TextEditingController(text: '3');
  final breakTimeController = TextEditingController(text: '120');
  final secondsBeforeRoundBeginsController = TextEditingController(text: '5');

  late final TextEditingController filenameController;

  late final DatabaseHelper dbHelper;
  bool isLoading = false;
  bool _disposed = false;

  @override
  Future<void> reloadSettings() async {
    await _loadExistingSettings();
  }

  // /// Safely call setState
  // void _safeSetState(VoidCallback fn) {
  //   if (!_disposed && mounted) fn();
  //   if (!_disposed && mounted) setState(() {});
  // }

  /// Safely call setState (πιο συνηθισμένη προσέγγιση)
  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(
        fn,
      ); // Η fn (που περιέχει τις αλλαγές κατάστασης) καλείται μέσα στο setState
    }
  }

  /// Show a SnackBar after build
  void _showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          super.context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    dbHelper = ref.read(databaseHelperProvider);
    _loadExistingSettings();
    filenameController = TextEditingController();
  }

  Future<void> _loadExistingSettings() async {
    _safeSetState(() => isLoading = true);
    try {
      final settings = await dbHelper.fetchSettings();
      if (!mounted) return;
      if (settings != null) {
        _safeSetState(() {
          fsrSensitivityController.text =
              (settings['fsrSensitivity'] ?? '800').toString();
          fsrThresholdController.text =
              (settings['fsrThreshold'] ?? '200').toString();
          roundsController.text = (settings['rounds'] ?? '3').toString();
          roundTimeController.text = (settings['roundTime'] ?? '3').toString();
          breakTimeController.text =
              (settings['breakTime'] ?? '120').toString();
          secondsBeforeRoundBeginsController.text =
              (settings['secondsBeforeRoundBegins'] ?? '5').toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: \$e');
      _showSnackBar('Failed to load settings.');
    } finally {
      if (mounted) _safeSetState(() => isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final texts = [
      fsrSensitivityController.text.trim(),
      fsrThresholdController.text.trim(),
      roundsController.text.trim(),
      roundTimeController.text.trim(),
      breakTimeController.text.trim(),
      secondsBeforeRoundBeginsController.text.trim(),
    ];
    if (texts.any((t) => t.isEmpty)) {
      _showSnackBar('Please fill in all fields.');
      return;
    }

    final values = texts.map(int.tryParse).toList();
    if (values.any((v) => v == null)) {
      _showSnackBar('Please enter valid integer values.');
      return;
    }

    final fsrSensitivity = values[0]!;
    final fsrThreshold = values[1]!;
    final rounds = values[2]!;
    final roundTime = values[3]!;
    final breakTime = values[4]!;
    final secondsBeforeStart = values[5]!;

    if (fsrSensitivity < 500 || fsrSensitivity > 3300) {
      _showSnackBar('FSR Sensitivity must be between 500 and 3300.');
      return;
    }
    if (fsrThreshold < 50 || fsrThreshold > 1000) {
      _showSnackBar('FSR Threshold must be between 50 and 1000.');
      return;
    }
    if (rounds < 1 || rounds > 15) {
      _showSnackBar('Rounds must be between 1 and 15.');
      return;
    }
    if (roundTime < 1 || roundTime > 20) {
      _showSnackBar('Round time must be between 1 and 20 minutes.');
      return;
    }
    if (breakTime < 10 || breakTime > 600) {
      _showSnackBar('Break time must be between 10 and 600 seconds.');
      return;
    }
    if (secondsBeforeStart < 5 || secondsBeforeStart > 30) {
      _showSnackBar('Seconds before round begins must be between 5 and 30.');
      return;
    }

    _safeSetState(() => isLoading = true);
    try {
      await dbHelper.upsertSettings(
        fsrSensitivity: fsrSensitivity,
        fsrThreshold: fsrThreshold,
        rounds: rounds,
        roundTime: roundTime,
        breakTime: breakTime,
        secondsBeforeRoundBegins: secondsBeforeStart,
      );
      if (!mounted) return;
      _showSnackBar('Settings saved successfully.');
    } catch (e) {
      debugPrint('Error saving settings: \$e');
      if (mounted) _showSnackBar('Failed to save settings.');
    } finally {
      if (mounted) _safeSetState(() => isLoading = false);
    }
  }

  Future<void> _insertSampleData() async {
    try {
      await dbHelper.insertSampleMatches();
      if (!mounted) return;
      _showSnackBar('Sample data inserted successfully.');
      ///// ignore: unused_result
      ///ref.refresh(matchesFutureProvider);
      ref.invalidate(matchesFutureProvider);

      widget.onTabChange(1);
    } catch (e) {
      if (mounted) _showSnackBar('Failed to insert sample data: \$e');
    }
  }

  // Μέσα στην κλάση _SettingsScreenState

  Future<void> _showExportDatabaseDialog() async {
    // 1️⃣ Δημιούργησε ένα προτεινόμενο όνομα για τον διάλογο "Save As..." του συστήματος
    final now = DateTime.now();
    final safeDate = '${now.day}_${now.month}_${now.year}';
    // Αυτό θα είναι το όνομα που θα προτείνεται στον χρήστη στον διάλογο του συστήματος
    final String suggestedFinalFileName = 'BoxSensors_Export_$safeDate.db';
    // Ένα σταθερό όνομα για το προσωρινό αρχείο που δημιουργείται εσωτερικά
    const String tempInternalFileName = "temp_internal_export.db";

    // 2️⃣ (Προαιρετικό) Αίτηση άδειας αποθήκευσης - το έχεις σχολιασμένο, το αφήνω έτσι.
    // Για το SAF, η άδεια συνήθως δίνεται μέσω του picker του συστήματος.
    // if (!await requestStoragePermissionIfNeeded()) return;

    _safeSetState(() => isLoading = true); // Εμφάνισε ένδειξη φόρτωσης
    String? tempPath;
    File? tempFile;
    String messageToShow =
        'Export failed: An unknown error occurred.'; // Προεπιλεγμένο μήνυμα σφάλματος

    try {
      // 3️⃣ Δημιούργησε ένα προσωρινό αντίγραφο της ενεργής βάσης δεδομένων
      debugPrint(
        "SAF Export: Creating temporary DB copy: $tempInternalFileName",
      );
      tempPath = await dbHelper.exportDatabaseToFile(tempInternalFileName);

      if (!mounted) {
        // Έλεγχος αν το widget είναι ακόμα ενεργό
        // Το isLoading θα γίνει false στο finally block
        return;
      }

      if (tempPath == null) {
        messageToShow =
            'Unable to create temporary export file. Please check logs.';
        // Δεν κάνουμε return εδώ, για να εκτελεστεί το finally και να δείξει το SnackBar
      } else {
        tempFile = File(tempPath);
        debugPrint("SAF Export: Temporary file created at: $tempPath");

        final bytes = await tempFile.readAsBytes();
        if (!mounted) {
          return;
        } // Έλεγχος μετά την ανάγνωση των bytes

        // 4️⃣ Εμφάνισε τον διάλογο "Save As..." του συστήματος μέσω SAF
        debugPrint("SAF Export: Showing system 'Save As...' dialog.");
        final String? savedPath = await FilePicker.platform.saveFile(
          dialogTitle:
              'Save Database As…', // Τίτλος του διαλόγου του συστήματος
          fileName: suggestedFinalFileName, // Προτεινόμενο όνομα αρχείου
          type: FileType.custom, // Ορίζουμε ότι είναι custom τύπος
          allowedExtensions: ['db'], // (Προαιρετικό) Βοηθά τον χρήστη
          bytes: bytes, // Τα δεδομένα προς εγγραφή
        );

        if (!mounted) {
          return;
        } // Έλεγχος μετά το saveFile

        if (savedPath != null) {
          // final trimmedPath = savedPath.substring(0, savedPath.lastIndexOf('/'));
          // final trimmedPath = savedPath.replaceAll(RegExp(r'/\d+$'), '');
          // messageToShow = 'Database exported successfully to: $savedPath';
          // messageToShow = 'Database exported successfully to: $trimmedPath';
          messageToShow = 'Database exported successfully';
          debugPrint("SAF Export: File saved to: $savedPath");
        } else {
          messageToShow =
              'Export cancelled by user.'; 
          debugPrint("SAF Export: User cancelled the save dialog.");
        }
      }
    } catch (e) {
      debugPrint("SAF Export: Error during export process: $e");
      messageToShow = 'Export failed: $e';
    } finally {
      // 5️⃣ Καθάρισε το προσωρινό αρχείο, αν δημιουργήθηκε
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
          debugPrint(
            "SAF Export: Temporary export file deleted: ${tempFile.path}",
          );
        } catch (e) {
          debugPrint("SAF Export: Error deleting temporary export file: $e");          
        }
      }

      // Εμφάνισε το τελικό μήνυμα και την ένδειξη φόρτωσης
      if (mounted) {
        _safeSetState(() => isLoading = false);
        _showSnackBar(messageToShow);
      }
    }
  }

  // Future<void> _showExportDatabaseDialog2() async {
  //   // 1️⃣ Build a safe default filename final defaultName = 'messages.db';
  //   final now = DateTime.now();
  //   final safeDate = '${now.day}_${now.month}_${now.year}';
  //   final defaultName = 'BoxSensors_$safeDate.db';

  //   // 2️⃣ Ask for storage permission
  //   // if (!await requestStoragePermissionIfNeeded()) return;

  //   // 2️⃣ 3️⃣ Create a temporary copy of your live DB
  //   final tempPath = await dbHelper.exportDatabaseToFile(defaultName);
  //   if (!mounted || tempPath == null) {
  //     _showSnackBar('Unable to create temporary export file.');
  //     return;
  //   }
  //   final tempFile = File(tempPath);

  //   // 4️⃣ Show a custom dialog so you can style everything
  //   String? pickedDir;

  //   filenameController.text = defaultName;
  //   if (!mounted) {
  //     return;
  //   }
  //   await showDialog(
  //     context: context,
  //     builder: (BuildContext dialogCtx) {
  //       return AlertDialog(
  //         title: const Text('Export Database'),
  //         content: StatefulBuilder(
  //           builder: (BuildContext sbCtx, void Function(VoidCallback) sbSet) {
  //             return Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 // Filename field
  //                 TextField(
  //                   controller: filenameController,
  //                   decoration: const InputDecoration(labelText: 'Filename'),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 // Folder picker row
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: Text(
  //                         pickedDir ?? 'No folder selected',
  //                         style: TextStyle(
  //                           fontSize: 12,
  //                           color: Colors.grey[700],
  //                         ),
  //                       ),
  //                     ),
  //                     TextButton(
  //                       onPressed: () async {
  //                         final dir = await FilePicker.platform
  //                             .getDirectoryPath(
  //                               dialogTitle: 'Choose export folder',
  //                             );
  //                         if (dir != null) {
  //                           sbSet(() => pickedDir = dir);
  //                         }
  //                       },
  //                       child: const Text('Browse…'),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(dialogCtx).pop(),
  //             child: const Text('Cancel'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               final folder = pickedDir;
  //               final name = filenameController.text.trim();

  //               if (folder == null || name.isEmpty) {
  //                 if (!mounted) {
  //                   return; // Έλεγχos mounted της _SettingsScreenState
  //                 }
  //                 ScaffoldMessenger.of(dialogCtx).showSnackBar(
  //                   const SnackBar(
  //                     content: Text('Please pick folder and filename'),
  //                   ),
  //                 );
  //                 return;
  //               }

  //               // Κράτα μια αναφορά στο Navigator και ScaffoldMessenger *πριν* το await
  //               // αν και για το SnackBar θα χρησιμοποιήσουμε το _showSnackBar της _SettingsScreenState
  //               final navigator = Navigator.of(dialogCtx);

  //               String messageToShow = ''; // Για το τελικό SnackBar

  //               try {
  //                 // 1️⃣ Read your temp DB bytes
  //                 final bytes = await tempFile.readAsBytes();

  //                 // 2️⃣ Let SAF show the “Save As…” UI & do the write for you
  //                 final savedPath = await FilePicker.platform.saveFile(
  //                   dialogTitle: 'Save Database As…',
  //                   fileName: name, // e.g. 'BoxSensors_16_5_2025.db'
  //                   type: FileType.custom,
  //                   allowedExtensions: ['db'],
  //                   bytes: bytes,
  //                 );

  //                 // 3️⃣ Prepare the SnackBar message
  //                 if (savedPath != null) {
  //                   messageToShow =
  //                       'Database exported successfully to: $savedPath';
  //                 } else {
  //                   messageToShow = 'Export cancelled';
  //                 }
  //               } catch (e) {
  //                 messageToShow = 'Export failed: $e';
  //               }

  //               // Έλεγχος mounted της _SettingsScreenState πριν από UI operations
  //               if (!mounted) return;

  //               navigator.pop(); // Κλείσε τον διάλογο ΠΡΩΤΑ

  //               _showSnackBar(
  //                 messageToShow,
  //               ); // Μετά δείξε το SnackBar χρησιμοποιώντας τη μέθοδο της _SettingsScreenState
  //               // η οποία έχει τον δικό της έλεγχο mounted και χρησιμοποιεί το this.context.
  //             },
  //             child: const Text('Save'),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   // 5️⃣ Clean up the temp file
  //   if (await tempFile.exists()) {
  //     await tempFile.delete();
  //   }
  // }

  Future<void> _showImportDatabaseDialog() async {
    // 1️⃣ Let the user pick *any* file, then filter for “.db”
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select a database file to import',
      type: FileType.any,
    );
    // Έλεγχος mounted μετά από το πρώτο await
    if (!mounted) return;

    // 2️⃣ Handle cancel / no selection
    if (result == null ||
        result.files.isEmpty ||
        result.files.single.path == null) {
      _showSnackBar('Import cancelled.');
      return;
    }

    final path = result.files.single.path!;
    // 3️⃣ Ensure it’s a .db
    if (!path.toLowerCase().endsWith('.db')) {
      _showSnackBar('Please pick a .db file');
      return;
    }

    final file = File(path);
    // 4️⃣ Pre-flight checks
    if (!await file.exists()) {
      // Έλεγχος mounted μετά από το πρώτο await
      if (!mounted) return;
      _showSnackBar('Selected file does not exist.');
      return;
    }

    int fileLength = await file.length();
    if (!mounted) return;

    if (fileLength == 0) {
      _showSnackBar('Selected file is empty.');
      return;
    }

    // 5️⃣ Warn the user that they’re about to overwrite
    // don't show dialog if widget disposed
    if (!mounted) return;
    final really = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext ctx) => AlertDialog(
            title: const Text('Overwrite Existing Data?'),
            content: const Text(
              'Importing this database will replace all your current data. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (!mounted) return;
    // you can now safely check `really`
    if (really != true) {
      _showSnackBar('Database import canceled by user.');
      return;
    }

    // 6️⃣ Do the import
    _safeSetState(() => isLoading = true);
    String importMessage =
        'Import failed: Unknown error.'; // Default error message

    try {
      await dbHelper.close();
      if (!mounted) {
        _safeSetState(() => isLoading = false);
        return;
      }

      await DatabaseImporter.instance.importFromFile(file);
      if (!mounted) {
        _safeSetState(() => isLoading = false);
        return;
      }

      final docs = await getApplicationDocumentsDirectory();
      if (!mounted) {
        _safeSetState(() => isLoading = false);
        return;
      }

      final testDbPath = p.join(docs.path, 'messages.db');
      final testDb = await openDatabase(testDbPath);
      if (!mounted) {
        await testDb.close();
        _safeSetState(() => isLoading = false);
        return;
      }

      final userV =
          Sqflite.firstIntValue(await testDb.rawQuery('PRAGMA user_version')) ??
          0;
      await testDb.close();
      if (!mounted) {
        _safeSetState(() => isLoading = false);
        return;
      }

      const expectedVersion = 1;
      if (userV < expectedVersion) {
        throw FormatException(
          'Incompatible DB schema (found v$userV, need ≥ v$expectedVersion).',
        );
      }

      await dbHelper.database;

      if (!mounted) {
        _safeSetState(() => isLoading = false);
        return;
      }
      importMessage = 'Database imported successfully.';
      ref.invalidate(matchesFutureProvider);
      widget.onTabChange(1);
    } on PlatformException catch (pe) {
      debugPrint('Platform error during import: $pe');
      importMessage = 'Import failed (platform error): ${pe.message}';
    } on FileSystemException catch (fs) {
      debugPrint('I/O error during import: $fs');
      importMessage = 'Import failed (I/O error): ${fs.message}';
    } on FormatException catch (fe) {
      debugPrint('Schema error: $fe');
      importMessage = 'Import failed: ${fe.message}';
    } catch (e) {
      debugPrint('Unexpected error during import: $e');
      importMessage = 'Import failed: $e';
    } finally {
      if (mounted) {
        _safeSetState(() => isLoading = false);
        _showSnackBar(importMessage);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    fsrSensitivityController.dispose();
    fsrThresholdController.dispose();
    roundsController.dispose();
    roundTimeController.dispose();
    breakTimeController.dispose();
    secondsBeforeRoundBeginsController.dispose();
    filenameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onTabChange(0);
      },
      child: Scaffold(
        body: Theme(
          data: theme.copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            ),
          ),
          child: Column(
            children: [
              SettingsHeader(onBack: () => widget.onTabChange(0)),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Scrollbar(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SettingsFormCard(
                                  theme: theme,
                                  fsrSensitivityController:
                                      fsrSensitivityController,
                                  fsrThresholdController:
                                      fsrThresholdController,
                                  roundsController: roundsController,
                                  roundTimeController: roundTimeController,
                                  breakTimeController: breakTimeController,
                                  secondsBeforeRoundBeginsController:
                                      secondsBeforeRoundBeginsController,
                                  isLoading: isLoading,
                                  onSave: _saveSettings,
                                ),
                                SampleDataCard(
                                  theme: theme,
                                  onInsert: _insertSampleData,
                                ),
                                ExportDatabaseCard(
                                  theme: theme,
                                  onInsert: _showExportDatabaseDialog,
                                ),
                                ImportDatabaseCard(
                                  theme: theme,
                                  onInsert: _showImportDatabaseDialog,
                                ),
                                AndroidBatterySettingCard(),
                              ],
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



  // Future<void> _showImportDatabaseDialog() async {
  //   // 1️⃣ Let the user pick *any* file, then filter for “.db”
  //   final result = await FilePicker.platform.pickFiles(
  //     dialogTitle: 'Select a database file to import',
  //     type: FileType.any, // allow all file types
  //   );

  //   // 2️⃣ If they cancelled, bail out
  //   if (result == null ||
  //       result.files.isEmpty ||
  //       result.files.single.path == null) {
  //     _showSnackBar('Import cancelled.');
  //     return;
  //   }

  //   final pickedPath = result.files.single.path!;
  //   if (!pickedPath.toLowerCase().endsWith('.db')) {
  //     _showSnackBar('Please pick a .db file');
  //     return;
  //   }

  //   // 3️⃣ We’ve got a .db — proceed with import
  //   final pickedFile = File(pickedPath);

  //   _safeSetState(() => isLoading = true);
  //   try {
  //     await dbHelper.close();
  //     await DatabaseImporter.instance.importFromFile(pickedFile);
  //     await dbHelper.database;
  //     _showSnackBar('Database imported successfully.');
  //     ref.invalidate(matchesFutureProvider);
  //     widget.onTabChange(1);
  //   } catch (e) {
  //     debugPrint('Import failed: $e');
  //     _showSnackBar('Import failed: $e');
  //   } finally {
  //     if (mounted) _safeSetState(() => isLoading = false);
  //   }
  // }