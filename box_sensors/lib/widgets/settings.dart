// lib/widgets/settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/settings_header.dart';
import 'package:box_sensors/widgets/settings_form_card.dart';
import 'package:box_sensors/widgets/sample_data_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final Function(int) onTabChange;
  const SettingsScreen({super.key, required this.onTabChange});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // controllers and dbHelper same as before…
  final TextEditingController fsrSensitivityController =
      TextEditingController(text: '800');
  final TextEditingController fsrThresholdController =
      TextEditingController(text: '200');
  final TextEditingController roundsController =
      TextEditingController(text: '1');
  final TextEditingController roundTimeController =
      TextEditingController(text: '3');
  final TextEditingController breakTimeController =
      TextEditingController(text: '120');
  final TextEditingController secondsBeforeRoundBeginsController =
      TextEditingController(text: '5');
  late final DatabaseHelper dbHelper;
  bool isLoading = false;
  bool _disposed = false;

    /// Helper method to safely call setState.
  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  /// Helper method to safely show a SnackBar.
  void _showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    dbHelper = ref.read(databaseHelperProvider);
    _loadExistingSettings();
  }

  // ... _loadExistingSettings, _saveSettings, _insertSampleData, _safeSetState, _showSnackBar, dispose()
    Future<void> _loadExistingSettings() async {
    _safeSetState(() {
      isLoading = true;
    });
    try {
      Map<String, dynamic>? settings = await dbHelper.fetchSettings();
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
    } catch (e, stackTrace) {
      debugPrint('Error loading settings: $e\n$stackTrace');
      _showSnackBar('Failed to load settings.');
    } finally {
      if (mounted) {
        _safeSetState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    String fsrSensitivityText = fsrSensitivityController.text.trim();
    String fsrThresholdText = fsrThresholdController.text.trim();
    String roundsText = roundsController.text.trim();
    String roundTimeText = roundTimeController.text.trim();
    String breakTimeText = breakTimeController.text.trim();
    String secondsBeforeRoundBeginsText =
        secondsBeforeRoundBeginsController.text.trim();

    if (fsrSensitivityText.isEmpty ||
        fsrThresholdText.isEmpty ||
        roundsText.isEmpty ||
        roundTimeText.isEmpty ||
        breakTimeText.isEmpty ||
        secondsBeforeRoundBeginsText.isEmpty) {
      _showSnackBar('Please fill in all fields.');
      return;
    }

    int? fsrSensitivity = int.tryParse(fsrSensitivityText);
    int? fsrThreshold = int.tryParse(fsrThresholdText);
    int? rounds = int.tryParse(roundsText);
    int? roundTime = int.tryParse(roundTimeText);
    int? breakTime = int.tryParse(breakTimeText);
    int? secondsBeforeRoundBegins = int.tryParse(secondsBeforeRoundBeginsText);

    if (fsrSensitivity == null ||
        fsrThreshold == null ||
        rounds == null ||
        roundTime == null ||
        breakTime == null ||
        secondsBeforeRoundBegins == null) {
      _showSnackBar('Please enter valid integer values.');
      return;
    }

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

    if (secondsBeforeRoundBegins < 5 || secondsBeforeRoundBegins > 30) {
      _showSnackBar('Seconds before round begins must be between 5 and 30.');
      return;
    }

    _safeSetState(() {
      isLoading = true;
    });

    try {
      await dbHelper.upsertSettings(
        fsrSensitivity: fsrSensitivity,
        fsrThreshold: fsrThreshold,
        rounds: rounds,
        roundTime: roundTime,
        breakTime: breakTime,
        secondsBeforeRoundBegins: secondsBeforeRoundBegins,
      );
      if (!mounted) return;
      _showSnackBar('Settings saved successfully.');
      Map<String, dynamic>? updatedSettings = await dbHelper.fetchSettings();
      debugPrint("Updated Settings: $updatedSettings");
    } catch (e, stackTrace) {
      debugPrint("Error saving settings: $e\n$stackTrace");
      if (!mounted) return;
      _showSnackBar('Failed to save settings.');
    } finally {
      if (mounted) {
        _safeSetState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _insertSampleData() async {
    try {
      await dbHelper.insertSampleMatches();
      // await dbHelper.insertComprehensiveSampleData();
      if (!mounted) return;
      _showSnackBar('Sample data inserted successfully.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to insert sample data.');
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
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Theme(
        data: theme.copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          ),
        ),
        child: Column(
          children: [
            SettingsHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SettingsFormCard(
                            theme: theme,
                            fsrSensitivityController:
                                fsrSensitivityController,
                            fsrThresholdController: fsrThresholdController,
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
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}













// // lib/widgets/settings.dart
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:flutter/material.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/widgets/custom_text_form_field.dart';
// import 'package:gap/gap.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class SettingsScreen extends ConsumerStatefulWidget {
//   final Function(int) onTabChange; // Callback function for changing tabs

//   const SettingsScreen({super.key, required this.onTabChange});

//   @override
//   ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends ConsumerState<SettingsScreen> {
//   final TextEditingController fsrSensitivityController =
//       TextEditingController(text: '800');
//   final TextEditingController fsrThresholdController =
//       TextEditingController(text: '200');
//   final TextEditingController roundsController =
//       TextEditingController(text: '1');
//   final TextEditingController roundTimeController =
//       TextEditingController(text: '3');
//   final TextEditingController breakTimeController =
//       TextEditingController(text: '120');
//   final TextEditingController secondsBeforeRoundBeginsController =
//       TextEditingController(text: '5');

//   // Obtain DatabaseHelper through Riverpod instead of directly instantiating.
//   late final DatabaseHelper dbHelper;

//   bool isLoading = false;
//   bool _disposed = false; // Flag to track if widget is disposed

//   /// Helper method to safely call setState.
//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) {
//       setState(fn);
//     }
//   }

//   /// Helper method to safely show a SnackBar.
//   void _showSnackBar(String message) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text(message)));
//       }
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Initialize dbHelper using the provider.
//     dbHelper = ref.read(databaseHelperProvider);
//     _loadExistingSettings();
//   }

//   Future<void> _loadExistingSettings() async {
//     _safeSetState(() {
//       isLoading = true;
//     });
//     try {
//       Map<String, dynamic>? settings = await dbHelper.fetchSettings();
//       if (!mounted) return;
//       if (settings != null) {
//         _safeSetState(() {
//           fsrSensitivityController.text =
//               (settings['fsrSensitivity'] ?? '800').toString();
//           fsrThresholdController.text =
//               (settings['fsrThreshold'] ?? '200').toString();
//           roundsController.text = (settings['rounds'] ?? '3').toString();
//           roundTimeController.text = (settings['roundTime'] ?? '3').toString();
//           breakTimeController.text =
//               (settings['breakTime'] ?? '120').toString();
//           secondsBeforeRoundBeginsController.text =
//               (settings['secondsBeforeRoundBegins'] ?? '5').toString();
//         });
//       }
//     } catch (e, stackTrace) {
//       debugPrint('Error loading settings: $e\n$stackTrace');
//       _showSnackBar('Failed to load settings.');
//     } finally {
//       if (mounted) {
//         _safeSetState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _saveSettings() async {
//     String fsrSensitivityText = fsrSensitivityController.text.trim();
//     String fsrThresholdText = fsrThresholdController.text.trim();
//     String roundsText = roundsController.text.trim();
//     String roundTimeText = roundTimeController.text.trim();
//     String breakTimeText = breakTimeController.text.trim();
//     String secondsBeforeRoundBeginsText =
//         secondsBeforeRoundBeginsController.text.trim();

//     if (fsrSensitivityText.isEmpty ||
//         fsrThresholdText.isEmpty ||
//         roundsText.isEmpty ||
//         roundTimeText.isEmpty ||
//         breakTimeText.isEmpty ||
//         secondsBeforeRoundBeginsText.isEmpty) {
//       _showSnackBar('Please fill in all fields.');
//       return;
//     }

//     int? fsrSensitivity = int.tryParse(fsrSensitivityText);
//     int? fsrThreshold = int.tryParse(fsrThresholdText);
//     int? rounds = int.tryParse(roundsText);
//     int? roundTime = int.tryParse(roundTimeText);
//     int? breakTime = int.tryParse(breakTimeText);
//     int? secondsBeforeRoundBegins = int.tryParse(secondsBeforeRoundBeginsText);

//     if (fsrSensitivity == null ||
//         fsrThreshold == null ||
//         rounds == null ||
//         roundTime == null ||
//         breakTime == null ||
//         secondsBeforeRoundBegins == null) {
//       _showSnackBar('Please enter valid integer values.');
//       return;
//     }

//     if (fsrSensitivity < 500 || fsrSensitivity > 3300) {
//       _showSnackBar('FSR Sensitivity must be between 500 and 3300.');
//       return;
//     }

//     if (fsrThreshold < 50 || fsrThreshold > 1000) {
//       _showSnackBar('FSR Threshold must be between 50 and 1000.');
//       return;
//     }

//     if (rounds < 1 || rounds > 15) {
//       _showSnackBar('Rounds must be between 1 and 15.');
//       return;
//     }

//     if (roundTime < 1 || roundTime > 20) {
//       _showSnackBar('Round time must be between 1 and 20 minutes.');
//       return;
//     }

//     if (breakTime < 10 || breakTime > 600) {
//       _showSnackBar('Break time must be between 10 and 600 seconds.');
//       return;
//     }

//     if (secondsBeforeRoundBegins < 5 || secondsBeforeRoundBegins > 30) {
//       _showSnackBar('Seconds before round begins must be between 5 and 30.');
//       return;
//     }

//     _safeSetState(() {
//       isLoading = true;
//     });

//     try {
//       await dbHelper.upsertSettings(
//         fsrSensitivity: fsrSensitivity,
//         fsrThreshold: fsrThreshold,
//         rounds: rounds,
//         roundTime: roundTime,
//         breakTime: breakTime,
//         secondsBeforeRoundBegins: secondsBeforeRoundBegins,
//       );
//       if (!mounted) return;
//       _showSnackBar('Settings saved successfully.');
//       Map<String, dynamic>? updatedSettings = await dbHelper.fetchSettings();
//       debugPrint("Updated Settings: $updatedSettings");
//     } catch (e, stackTrace) {
//       debugPrint("Error saving settings: $e\n$stackTrace");
//       if (!mounted) return;
//       _showSnackBar('Failed to save settings.');
//     } finally {
//       if (mounted) {
//         _safeSetState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _insertSampleData() async {
//     try {
//       await dbHelper.insertSampleMatches();
//       if (!mounted) return;
//       _showSnackBar('Sample data inserted successfully.');
//     } catch (e) {
//       if (!mounted) return;
//       _showSnackBar('Failed to insert sample data.');
//     }
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     fsrSensitivityController.dispose();
//     fsrThresholdController.dispose();
//     roundsController.dispose();
//     roundTimeController.dispose();
//     breakTimeController.dispose();
//     secondsBeforeRoundBeginsController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       body: Theme(
//         data: theme.copyWith(
//           inputDecorationTheme: const InputDecorationTheme(
//             isDense: true,
//             contentPadding: EdgeInsets.symmetric(
//               vertical: 8.0,
//               horizontal: 12.0,
//             ),
//           ),
//         ),
//         child: Column(
//           children: [
//             DisplayRow(
//               title: 'Settings',
//               actions: [
//                 IconButton(
//                   icon: Icon(
//                     Icons.arrow_back,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//             Expanded(
//               child: isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : SingleChildScrollView(
//                       padding: const EdgeInsets.all(4.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Card(
//                             color: theme.cardColor,
//                             elevation: 6,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               side: BorderSide(
//                                 color: theme.colorScheme.outline,
//                                 width: 1,
//                               ),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                                 children: [
//                                   Text(
//                                     'Json settings for ESP32',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: theme.colorScheme.primary,
//                                     ),
//                                   ),
//                                   const Gap(16),
//                                   CustomTextFormField(
//                                     controller: fsrSensitivityController,
//                                     label: 'FSR Sensitivity (500 to 3300)',
//                                   ),
//                                   const Gap(16),
//                                   CustomTextFormField(
//                                     controller: fsrThresholdController,
//                                     label: 'FSR Threshold (50 to 1000)',
//                                   ),
//                                   const Gap(16),
//                                   CustomTextFormField(
//                                     controller: roundsController,
//                                     label: 'Rounds (1 to 15)',
//                                   ),
//                                   const Gap(16),
//                                   CustomTextFormField(
//                                     controller: roundTimeController,
//                                     label: 'Round time in minutes (1 to 20 minutes)',
//                                   ),
//                                   const Gap(16),
//                                   CustomTextFormField(
//                                     controller: breakTimeController,
//                                     label: 'Break time in seconds (10 to 600 seconds)',
//                                   ),
//                                   const Gap(16),
//                                   CustomTextFormField(
//                                     controller: secondsBeforeRoundBeginsController,
//                                     label: 'Seconds before Round Begins (5 to 30 seconds)',
//                                   ),
//                                   const Gap(4),
//                                   ElevatedButton(
//                                     onPressed: isLoading ? null : _saveSettings,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: theme.colorScheme.primary,
//                                       foregroundColor: theme.colorScheme.onPrimary,
//                                       elevation: 6,
//                                       shadowColor: theme.shadowColor,
//                                       surfaceTintColor:
//                                           theme.colorScheme.primaryContainer,
//                                       fixedSize: const Size.fromHeight(40),
//                                     ),
//                                     child: const Text(
//                                       'Save Json Settings',
//                                       style: TextStyle(fontSize: 16),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           Card(
//                             color: theme.cardColor,
//                             elevation: 6,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               side: BorderSide(
//                                 color: theme.colorScheme.outline,
//                                 width: 1,
//                               ),
//                             ),
//                             child: Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Database Sample Data',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: theme.colorScheme.primary,
//                                     ),
//                                   ),
//                                   Text(
//                                     'Click below to insert sample matches for testing.',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: theme.colorScheme.onSurface,
//                                     ),
//                                   ),
//                                   const Gap(4),
//                                   Center(
//                                     child: ElevatedButton(
//                                       onPressed: _insertSampleData,
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: theme.colorScheme.primary,
//                                         foregroundColor: theme.colorScheme.onPrimary,
//                                         elevation: 6,
//                                         shadowColor: theme.shadowColor,
//                                         surfaceTintColor:
//                                             theme.colorScheme.primaryContainer,
//                                         fixedSize: const Size(300, 40),
//                                       ),
//                                       child: const Text(
//                                         'Insert Sample Data',
//                                         style: TextStyle(fontSize: 16),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
