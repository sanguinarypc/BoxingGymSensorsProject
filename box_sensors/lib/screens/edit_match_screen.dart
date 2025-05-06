import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Provides TextInputFormatter.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/widgets/custom_text_form_field.dart';
import 'package:intl/intl.dart';

class EditMatchScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> match;

  const EditMatchScreen({required this.match, super.key});

  @override
  ConsumerState<EditMatchScreen> createState() => _EditMatchScreenState();
}

class _EditMatchScreenState extends ConsumerState<EditMatchScreen> {
  final _formKey = GlobalKey<FormState>();

  // Obtain DatabaseHelper via Riverpod.
  late final DatabaseHelper dbHelper;

  // Controllers for input fields.
  final matchNameController = TextEditingController();
  final matchDateController = TextEditingController();
  final roundsController = TextEditingController();
  final finishedAtRoundController = TextEditingController();
  final totalTimeController = TextEditingController();
  final roundTimeController = TextEditingController();
  final breakTimeController = TextEditingController();

  // Mutable copy of match data.
  late Map<String, dynamic> matchData;

  @override
  void initState() {
    super.initState();
    dbHelper = ref.read(databaseHelperProvider);
    matchData = Map<String, dynamic>.from(widget.match);

    // Populate controllers from match.
    matchNameController.text = widget.match['matchName'] ?? '';
    if (widget.match['matchDate'] != null && widget.match['matchDate'].toString().isNotEmpty) {
      try {
        final parsed = DateTime.parse(widget.match['matchDate']);
        matchDateController.text = DateFormat('dd/MM/yyyy').format(parsed);
      } catch (_) {
        matchDateController.text = widget.match['matchDate'];
      }
    }
    roundsController.text = widget.match['rounds'].toString();
    finishedAtRoundController.text = widget.match['finishedAtRound'].toString();
    totalTimeController.text = widget.match['totalTime'] ?? '';
    roundTimeController.text = widget.match['roundTime'].toString();
    breakTimeController.text = widget.match['breakTime'].toString();
  }

  @override
  void dispose() {
    matchNameController.dispose();
    matchDateController.dispose();
    roundsController.dispose();
    finishedAtRoundController.dispose();
    totalTimeController.dispose();
    roundTimeController.dispose();
    breakTimeController.dispose();
    super.dispose();
  }

  Future<void> _updateMatch() async {
    if (!_formKey.currentState!.validate()) return;

    int safeFinished = 0;
    try {
      safeFinished = int.parse(finishedAtRoundController.text);
    } catch (_) {}

    try {
      await dbHelper.updateEditMatch(
        matchName: matchNameController.text,
        matchDate: matchDateController.text,
        rounds: int.parse(roundsController.text),
        finishedAtRound: safeFinished,
        totalTime: totalTimeController.text,
        roundTime: int.parse(roundTimeController.text),
        breakTime: int.parse(breakTimeController.text),
        id: widget.match['id'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match updated successfully.')),
      );

      // Update local matchData
      matchData
        ..['matchName'] = matchNameController.text
        ..['matchDate'] = matchDateController.text
        ..['rounds'] = int.parse(roundsController.text)
        ..['finishedAtRound'] = safeFinished
        ..['totalTime'] = totalTimeController.text
        ..['roundTime'] = int.parse(roundTimeController.text)
        ..['breakTime'] = int.parse(breakTimeController.text);

      Navigator.pop(context, matchData);
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('Error updating match: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update match.')),
      );
    }
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
        matchDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          DisplayRow(
            title: 'Edit/Update Game',
            actions: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context, matchData),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Match Info Card
                    Card(
                      color: theme.cardColor,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outline, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Match Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              controller: matchNameController,
                              label: 'Match Name',
                              validator: (v) => v==null||v.isEmpty?'Please enter a match name':null,
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _selectMatchDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: matchDateController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: theme.colorScheme.surface,
                                    labelText: 'Match Date (DD/MM/YYYY)',
                                    suffixIcon: Icon(Icons.calendar_today),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextFormField(
                              controller: roundsController,
                              label: 'Rounds (1-15)',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter the number of rounds';
                                final v = int.tryParse(value);
                                if (v == null) return 'Enter a valid integer';
                                if (v < 1 || v > 15) return 'Rounds must be 1–15';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Timings Card
                    Card(
                      color: theme.cardColor,
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outline, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Timings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                            const SizedBox(height: 16),
                            CustomTextFormField(
                              controller: roundTimeController,
                              label: 'Round Time (1-20) in minutes',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter the round time in minutes';
                                final v=int.tryParse(value);
                                if (v==null) return 'Enter a valid integer';
                                if (v<1||v>20) return 'Round time must be 1–20 minutes';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextFormField(
                              controller: breakTimeController,
                              label: 'Break Time (10-600) in seconds',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter the break time in seconds';
                                final v=int.tryParse(value);
                                if (v==null) return 'Enter a valid integer';
                                if (v<10||v>600) return 'Break time must be 10–600 seconds';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextFormField(
                              controller: finishedAtRoundController,
                              label: 'Finished at Round',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: totalTimeController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                labelText: 'Total Time (MM:SS)',
                                hintText: 'MM:SS',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [CustomTimeInputFormatter()],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter total time';
                                if (!RegExp(r'^\d{2}:\d{2}\$').hasMatch(value)) return 'Invalid format! Use MM:SS';
                                final parts=value.split(':');
                                final m=int.tryParse(parts[0])??-1;
                                final s=int.tryParse(parts[1])??-1;
                                if (m<0||s<0||s>=60) return 'Minutes:0–99, Seconds:0–59';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: _updateMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 6,
                        fixedSize: const Size.fromHeight(40),
                      ),
                      child: Text('Update Game', style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats input as MM:SS.
class CustomTimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text=newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length>4) text=text.substring(0,4);
    var formatted=text;
    if (text.length>=3) formatted='${text.substring(0,2)}:${text.substring(2)}';
    return TextEditingValue(text:formatted, selection: TextSelection.collapsed(offset:formatted.length));
  }
}











// // lib/screens/edit_match_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Provides TextInputFormatter.
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/providers.dart';
// import 'package:box_sensors/widgets/display_row.dart';
// import 'package:box_sensors/widgets/custom_text_form_field.dart';
// import 'package:intl/intl.dart';

// class EditMatchScreen extends ConsumerStatefulWidget {
//   final Map<String, dynamic> match;

//   const EditMatchScreen({required this.match, super.key});

//   @override
//   ConsumerState<EditMatchScreen> createState() => _EditMatchScreenState();
// }

// class _EditMatchScreenState extends ConsumerState<EditMatchScreen> {
//   final _formKey = GlobalKey<FormState>();

//   // Instead of instantiating DatabaseHelper directly, we obtain it via Riverpod.
//   late final DatabaseHelper dbHelper;

//   // Text controllers to capture input fields.
//   final TextEditingController matchNameController = TextEditingController();
//   final TextEditingController matchDateController = TextEditingController();
//   final TextEditingController roundsController = TextEditingController();
//   final TextEditingController finishedAtRoundController = TextEditingController();
//   final TextEditingController totalTimeController = TextEditingController();
//   final TextEditingController roundTimeController = TextEditingController();
//   final TextEditingController breakTimeController = TextEditingController();

//   // A simple safe setState helper.
//   void _safeSetState(VoidCallback fn) {
//     if (mounted) setState(fn);
//   }

//   late Map<String, dynamic> matchData;

//   @override
//   void initState() {
//     super.initState();

//     // Obtain the DatabaseHelper instance from the provider.
//     dbHelper = ref.read(databaseHelperProvider);

//     // Create a mutable copy of the passed match.
//     matchData = Map<String, dynamic>.from(widget.match);

//     // Populate the controllers with the passed match data.
//     matchNameController.text = widget.match['matchName'] ?? '';
//     if (widget.match['matchDate'] != null && widget.match['matchDate'].toString().isNotEmpty) {
//       try {
//         DateTime parsedDate = DateTime.parse(widget.match['matchDate']);
//         matchDateController.text = DateFormat('dd/MM/yyyy').format(parsedDate);
//       } catch (e) {
//         matchDateController.text = widget.match['matchDate'];
//       }
//     } else {
//       matchDateController.text = '';
//     }
//     roundsController.text = widget.match['rounds'].toString();
//     finishedAtRoundController.text = widget.match['finishedAtRound'].toString();
//     totalTimeController.text = widget.match['totalTime'] ?? '';
//     roundTimeController.text = widget.match['roundTime'].toString();
//     breakTimeController.text = widget.match['breakTime'].toString();
//   }

//   @override
//   void dispose() {
//     matchNameController.dispose();
//     matchDateController.dispose();
//     roundsController.dispose();
//     finishedAtRoundController.dispose();
//     totalTimeController.dispose();
//     roundTimeController.dispose();
//     breakTimeController.dispose();
//     super.dispose();
//   }

//   Future<void> _updateMatch() async {
//     if (_formKey.currentState!.validate()) {
//       int safeFinishedAtRound = 0;
//       try {
//         safeFinishedAtRound = int.parse(finishedAtRoundController.text);
//       } catch (e) {
//         safeFinishedAtRound = 0;
//       }

//       try {
//         await dbHelper.updateEditMatch(
//           matchName: matchNameController.text,
//           matchDate: matchDateController.text,
//           rounds: int.parse(roundsController.text),
//           finishedAtRound: safeFinishedAtRound,
//           totalTime: totalTimeController.text,
//           roundTime: int.parse(roundTimeController.text),
//           breakTime: int.parse(breakTimeController.text),
//           id: widget.match['id'],
//         );

//         if (!mounted) return;

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Match updated successfully.')),
//         );

//         matchData['matchName'] = matchNameController.text;
//         matchData['matchDate'] = matchDateController.text;
//         matchData['rounds'] = int.parse(roundsController.text);
//         matchData['finishedAtRound'] = safeFinishedAtRound;
//         matchData['totalTime'] = totalTimeController.text;
//         matchData['roundTime'] = int.parse(roundTimeController.text);
//         matchData['breakTime'] = int.parse(breakTimeController.text);

//         Navigator.pop(context, matchData);
//       } catch (e, stackTrace) {
//         if (!mounted) return;
//         debugPrint('Failed to update match: $e\n$stackTrace');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to update match.')),
//         );
//       }
//     }
//   }

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
//       body: Column(
//         children: [
//           DisplayRow(
//             title: 'Edit/Update Game',
//             actions: [
//               IconButton(
//                 icon: Icon(
//                   Icons.arrow_back,
//                   color: theme.colorScheme.onSurface,
//                 ),
//                 // onPressed: () {
//                 //   Navigator.pop(context);
//                 // },
//                 onPressed: () => Navigator.pop(context, matchData),
//               ),
//             ],
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
//               child: Form(
//                 key: _formKey,
//                 child: ListView(
//                   children: [
//                     // Card for Match Info
//                     Card(
//                       color: theme.cardColor,
//                       elevation: 6,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         side: BorderSide(
//                           color: theme.colorScheme.outline,
//                           width: 1,
//                         ),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Match Info',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: theme.colorScheme.primary,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             CustomTextFormField(
//                               controller: matchNameController,
//                               label: 'Match Name',
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter a match name';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 16),
//                             GestureDetector(
//                               onTap: _selectMatchDate,
//                               child: AbsorbPointer(
//                                 child: TextFormField(
//                                   controller: matchDateController,
//                                   decoration: InputDecoration(
//                                     border: const OutlineInputBorder(),
//                                     filled: true,
//                                     fillColor: theme.colorScheme.surface,
//                                     labelText: 'Match Date (DD/MM/YYYY)',
//                                     labelStyle: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                     suffixIcon: const Icon(Icons.calendar_today),
//                                     isDense: true,
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       vertical: 8,
//                                       horizontal: 10,
//                                     ),
//                                     floatingLabelBehavior: FloatingLabelBehavior.always,
//                                   ),
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             CustomTextFormField(
//                               controller: roundsController,
//                               label: 'Rounds',
//                               keyboardType: TextInputType.number,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter the number of rounds';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     // Card for Timings
//                     Card(
//                       color: theme.cardColor,
//                       elevation: 6,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         side: BorderSide(
//                           color: theme.colorScheme.outline,
//                           width: 1,
//                         ),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Timings',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: theme.colorScheme.primary,
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             CustomTextFormField(
//                               controller: roundTimeController,
//                               label: 'Round Time (in minutes)',
//                               keyboardType: TextInputType.number,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter the round time in minutes';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 16),
//                             CustomTextFormField(
//                               controller: breakTimeController,
//                               label: 'Break Time (in seconds)',
//                               keyboardType: TextInputType.number,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter the break time in seconds';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 16),
//                             CustomTextFormField(
//                               controller: finishedAtRoundController,
//                               label: 'Finished at Round',
//                               keyboardType: TextInputType.number,
//                             ),
//                             const SizedBox(height: 16),
//                             TextFormField(
//                               controller: totalTimeController,
//                               decoration: InputDecoration(
//                                 border: const OutlineInputBorder(),
//                                 filled: true,
//                                 fillColor: theme.colorScheme.surface,
//                                 labelText: 'Total Time (MM:SS)',
//                                 labelStyle: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 hintText: 'Enter time in MM:SS format',
//                                 isDense: true,
//                                 contentPadding: const EdgeInsets.symmetric(
//                                   vertical: 8,
//                                   horizontal: 10,
//                                 ),
//                               ),
//                               style: const TextStyle(fontSize: 14),
//                               keyboardType: TextInputType.number,
//                               // Specify the type of the list literal:
//                               inputFormatters: <TextInputFormatter>[CustomTimeInputFormatter()],
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter total time in MM:SS format';
//                                 }
//                                 if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
//                                   return 'Invalid format! Use MM:SS';
//                                 }
//                                 List<String> parts = value.split(':');
//                                 int minutes = int.tryParse(parts[0]) ?? -1;
//                                 int seconds = int.tryParse(parts[1]) ?? -1;
//                                 if (minutes < 0 || seconds < 0 || seconds >= 60) {
//                                   return 'Minutes: 0-99, Seconds: 0-59';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     ElevatedButton(
//                       onPressed: () async {
//                         await _updateMatch();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: theme.colorScheme.primary,
//                         foregroundColor: theme.colorScheme.onPrimary,
//                         elevation: 6,
//                         shadowColor: theme.shadowColor,
//                         surfaceTintColor: theme.colorScheme.primaryContainer,
//                         fixedSize: const Size.fromHeight(40),
//                       ),
//                       child: Text(
//                         'Update Game',
//                         style: TextStyle(
//                           color: theme.colorScheme.onPrimary,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// /// CustomTimeInputFormatter: formats input as MM:SS.
// class CustomTimeInputFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
//     if (text.length > 4) {
//       text = text.substring(0, 4); // Limit input to 4 digits (MMSS)
//     }
//     String formatted = text;
//     if (text.length >= 3) {
//       formatted = '${text.substring(0, 2)}:${text.substring(2)}';
//     }
//     return TextEditingValue(
//       text: formatted,
//       selection: TextSelection.collapsed(offset: formatted.length),
//     );
//   }
// }
