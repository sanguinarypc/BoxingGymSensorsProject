// lib/screens/add_match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/screens_widgets/match_info_card.dart';
import 'package:box_sensors/screens_widgets/timings_card.dart';
import 'package:box_sensors/screens_widgets/add_game_button.dart';
import 'package:box_sensors/screens/matches_screen.dart';

class AddMatchScreen extends ConsumerStatefulWidget {
  const AddMatchScreen({super.key});

  @override
  ConsumerState<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends ConsumerState<AddMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  late final DatabaseHelper _dbHelper;

  final _matchNameCtrl = TextEditingController();
  final _matchDateCtrl = TextEditingController();
  final _roundsCtrl = TextEditingController();
  final _roundTimeCtrl = TextEditingController();
  final _breakTimeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dbHelper = ref.read(databaseHelperProvider);
    _matchDateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _matchNameCtrl.dispose();
    _matchDateCtrl.dispose();
    _roundsCtrl.dispose();
    _roundTimeCtrl.dispose();
    _breakTimeCtrl.dispose();
    super.dispose();
  }

  /// Exactly like in SettingsScreen: safely show a SnackBar after this frame.
  void _showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  Future<void> _selectMatchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _matchDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

    // 1) parse the text to ints
    final roundsVal = int.tryParse(_roundsCtrl.text.trim());
    final roundTimeVal = int.tryParse(_roundTimeCtrl.text.trim());
    final breakTimeVal = int.tryParse(_breakTimeCtrl.text.trim());

    // 2) ensure they parsed
    if (roundsVal == null || roundTimeVal == null || breakTimeVal == null) {
      _showSnackBar('Please enter valid numbers for rounds/times.');
      return;
    }

    // 3) range‐checks exactly like SettingsScreen
    if (roundsVal < 1 || roundsVal > 15) {
      _showSnackBar('Rounds must be between 1 and 15.');
      return;
    }
    if (roundTimeVal < 1 || roundTimeVal > 20) {
      _showSnackBar('Round time must be between 1 and 20 minutes.');
      return;
    }
    if (breakTimeVal < 10 || breakTimeVal > 600) {
      _showSnackBar('Break time must be between 10 and 600 seconds.');
      return;
    }

    // 4) all clear—go ahead insert
    try {
      await _dbHelper.insertMatch(
        matchName: _matchNameCtrl.text,
        rounds: roundsVal,
        matchDate: _matchDateCtrl.text,
        roundTime: roundTimeVal,
        breakTime: breakTimeVal,
      );

      if (!mounted) return;
      _showSnackBar('Match added successfully.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MatchesScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to add match: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface.withAlpha(5),
              theme.colorScheme.surface.withAlpha(8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            DisplayRow(
              title: 'Add New Game',
              actions: [BackButton(color: theme.colorScheme.onSurface)],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 0), // const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      MatchInfoCard(
                        nameCtrl: _matchNameCtrl,
                        dateCtrl: _matchDateCtrl,
                        onDateTap: _selectMatchDate,
                        roundsCtrl: _roundsCtrl,
                        roundsValidator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter number of rounds'
                                    : null,
                        nameValidator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter a match name'
                                    : null,
                        dateValidator:
                            (v) =>
                                v == null || v.isEmpty ? 'Enter a date' : null,
                      ),
                      TimingsCard(
                        roundTimeCtrl: _roundTimeCtrl,
                        breakTimeCtrl: _breakTimeCtrl,

                        roundTimeValidator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter round time'
                                    : null,
                        breakTimeValidator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter break time'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      AddGameButton(onSave: _saveMatch),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// // // lib/screens/add_match_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:box_sensors/screens/match_info_card.dart';
// import 'package:box_sensors/screens/timings_card.dart';
// import 'package:box_sensors/screens/add_game_button.dart';
// import 'package:box_sensors/screens/matches_screen.dart';

// class AddMatchScreen extends ConsumerStatefulWidget {
//   const AddMatchScreen({super.key});

//   @override
//   ConsumerState<AddMatchScreen> createState() => _AddMatchScreenState();
// }

// class _AddMatchScreenState extends ConsumerState<AddMatchScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late final DatabaseHelper _dbHelper;

//   final _matchNameCtrl = TextEditingController();
//   final _matchDateCtrl = TextEditingController();
//   final _roundsCtrl = TextEditingController();
//   final _roundTimeCtrl = TextEditingController();
//   final _breakTimeCtrl = TextEditingController();

//   String? _notEmpty(String? v) =>
//       (v == null || v.isEmpty) ? 'This field is required' : null;

//   @override
//   void initState() {
//     super.initState();
//     _dbHelper = ref.read(databaseHelperProvider);
//     _matchDateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
//   }

//   @override
//   void dispose() {
//     _matchNameCtrl.dispose();
//     _matchDateCtrl.dispose();
//     _roundsCtrl.dispose();
//     _roundTimeCtrl.dispose();
//     _breakTimeCtrl.dispose();
//     super.dispose();
//   }

//   /// Helper method to safely show a SnackBar.
//   void _showSnackBar(String message) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(message)));
//       }
//     });
//   }

//   Future<void> _selectMatchDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null && mounted) {
//       setState(() {
//         _matchDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
//       });
//     }
//   }

//   Future<void> _saveMatch() async {
//     if (!_formKey.currentState!.validate()) return;

//     String rounds = _roundsCtrl.text.trim();
//     String roundTime = _roundTimeCtrl.text.trim();
//     String breakTime = _breakTimeCtrl.text.trim();

//     int? roundsCtrl = int.tryParse(rounds);


//     if (rounds < 1 || rounds > 15) {
//       _showSnackBar('Rounds must be between 1 and 15.');
//       return;
//     }

//     // if (roundTime < 1 || roundTime > 20) {
//     //   _showSnackBar('Round time must be between 1 and 20 minutes.');
//     //   return;
//     // }

//     // if (breakTime < 10 || breakTime > 600) {
//     //   _showSnackBar('Break time must be between 10 and 600 seconds.');
//     //   return;
//     // }

//     try {
//       await _dbHelper.insertMatch(
//         matchName: _matchNameCtrl.text,
//         rounds: int.parse(_roundsCtrl.text),
//         matchDate: _matchDateCtrl.text,
//         roundTime: int.parse(_roundTimeCtrl.text),
//         breakTime: int.parse(_breakTimeCtrl.text),
//       );

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Match added successfully.')),
//       );
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const MatchesScreen()),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to add match: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               theme.colorScheme.surface.withAlpha(5),
//               theme.colorScheme.surface.withAlpha(8),
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           children: [
//             DisplayRow(
//               title: 'Add New Game',
//               actions: [BackButton(color: theme.colorScheme.onSurface)],
//             ),

//             // the form goes inside Expanded so it scrolls if needed
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: ListView(
//                     children: [
//                       MatchInfoCard(
//                         nameCtrl: _matchNameCtrl,
//                         dateCtrl: _matchDateCtrl,
//                         roundsCtrl: _roundsCtrl,
//                         onDateTap: _selectMatchDate,
//                         nameValidator: _notEmpty,
//                         dateValidator: _notEmpty,
//                         roundsValidator: _notEmpty,
//                       ),
//                       TimingsCard(
//                         roundTimeCtrl: _roundTimeCtrl,
//                         breakTimeCtrl: _breakTimeCtrl,
//                         roundTimeValidator: (v) {
//                           if (v == null || v.isEmpty) return 'Enter a time';
//                           if (int.tryParse(v) == null)
//                             return 'Must be a number';
//                           return null;
//                         },
//                         breakTimeValidator: (v) {
//                           if (v == null || v.isEmpty) return 'Enter a break';
//                           if (int.tryParse(v) == null)
//                             return 'Must be a number';
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),
//                       AddGameButton(onSave: _saveMatch),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }






// // lib/screens/add_match_screen.dart
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:flutter/material.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/widgets/custom_text_form_field.dart';
// import 'package:intl/intl.dart';
// import 'package:box_sensors/screens/matches_screen.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class AddMatchScreen extends ConsumerStatefulWidget {
//   const AddMatchScreen({super.key});

//   @override
//   ConsumerState<AddMatchScreen> createState() => _AddMatchScreenState();
// }

// class _AddMatchScreenState extends ConsumerState<AddMatchScreen> {
//   final _formKey = GlobalKey<FormState>();
//   // Instead of creating a new instance here, get it from the provider.
//   late final DatabaseHelper dbHelper;

//   // Text controllers for input fields.
//   final TextEditingController matchNameController = TextEditingController();
//   final TextEditingController matchDateController = TextEditingController();
//   final TextEditingController roundsController = TextEditingController();
//   final TextEditingController finishedAtRoundController = TextEditingController();
//   final TextEditingController roundTimeController = TextEditingController();
//   final TextEditingController breakTimeController = TextEditingController();

//   bool _disposed = false;

//   /// Helper method to safely call setState if the widget is still mounted.
//   void _safeSetState(VoidCallback fn) {
//     if (!_disposed && mounted) {
//       setState(fn);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     // Get the DatabaseHelper from Riverpod.
//     dbHelper = ref.read(databaseHelperProvider);

//     // Automatically set today's date in dd/MM/yyyy format.
//     matchDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
//   }

//   @override
//   void dispose() {
//     _disposed = true;
//     matchNameController.dispose();
//     matchDateController.dispose();
//     roundsController.dispose();
//     finishedAtRoundController.dispose();
//     roundTimeController.dispose();
//     breakTimeController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveMatch() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         await dbHelper.insertMatch(
//           matchName: matchNameController.text,
//           rounds: int.parse(roundsController.text),
//           matchDate: matchDateController.text,
//           roundTime: int.parse(roundTimeController.text),
//           breakTime: int.parse(breakTimeController.text),
//         );
//         if (!mounted) return;
//         // Show a success SnackBar.
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Match added successfully.')),
//         );
//         // Navigate to MatchesScreen.
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const MatchesScreen()),
//         );
//       } catch (e) {
//         if (!mounted) return;
//         // Show a failure SnackBar.
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to add match.')),
//         );
//       }
//     }
//   }

//   /// Opens a date picker to select a match date.
//   Future<void> _selectMatchDate() async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (pickedDate != null) {
//       _safeSetState(() {
//         matchDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       // Wrap the content in a Container with a gradient background.
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               theme.colorScheme.surface.withAlpha(5),
//               theme.colorScheme.surface.withAlpha(8),
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Column(
//           children: [
//             DisplayRow(
//               title: 'Add New Game',
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
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Form(
//                   key: _formKey,
//                   child: ListView(
//                     children: [
//                       Card(
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         color: theme.cardColor,
//                         elevation: 6,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           side: BorderSide(
//                             color: theme.colorScheme.outline,
//                             width: 1,
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Match Info',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               // Match Name
//                               CustomTextFormField(
//                                 controller: matchNameController,
//                                 label: 'Match Name',
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter a match name';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                               const SizedBox(height: 16),
//                               // Match Date with date picker.
//                               GestureDetector(
//                                 onTap: _selectMatchDate,
//                                 child: AbsorbPointer(
//                                   child: TextFormField(
//                                     controller: matchDateController,
//                                     decoration: InputDecoration(
//                                       border: const OutlineInputBorder(),
//                                       filled: true,
//                                       fillColor: theme.colorScheme.surface,
//                                       labelText: 'Match Date (DD/MM/YYYY)',
//                                       labelStyle: const TextStyle(fontWeight: FontWeight.bold),
//                                       suffixIcon: const Icon(Icons.calendar_today),
//                                       isDense: true,
//                                       contentPadding: const EdgeInsets.symmetric(
//                                         vertical: 12,
//                                         horizontal: 10,
//                                       ),
//                                       floatingLabelBehavior: FloatingLabelBehavior.always,
//                                     ),
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               // Rounds.
//                               CustomTextFormField(
//                                 controller: roundsController,
//                                 label: 'Rounds',
//                                 keyboardType: TextInputType.number,
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter the number of rounds';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       Card(
//                         margin: const EdgeInsets.symmetric(vertical: 8),
//                         color: theme.cardColor,
//                         elevation: 6,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           side: BorderSide(
//                             color: theme.colorScheme.outline,
//                             width: 1,
//                           ),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Timings',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: theme.colorScheme.primary,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               // Round Time.
//                               CustomTextFormField(
//                                 controller: roundTimeController,
//                                 label: 'Round Time (in minutes)',
//                                 keyboardType: TextInputType.number,
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter the round time in minutes';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                               const SizedBox(height: 16),
//                               // Break Time.
//                               CustomTextFormField(
//                                 controller: breakTimeController,
//                                 label: 'Break Time (in seconds)',
//                                 keyboardType: TextInputType.number,
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please enter the break time in seconds';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       ElevatedButton(
//                         onPressed: _saveMatch,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: theme.colorScheme.primary,
//                           foregroundColor: theme.colorScheme.onPrimary,
//                           elevation: 6,
//                           shadowColor: theme.shadowColor,
//                           surfaceTintColor: theme.colorScheme.primaryContainer,
//                           fixedSize: const Size.fromHeight(40),
//                         ),
//                         child: Text(
//                           'Add Game',
//                           style: TextStyle(
//                             color: theme.colorScheme.onPrimary,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
