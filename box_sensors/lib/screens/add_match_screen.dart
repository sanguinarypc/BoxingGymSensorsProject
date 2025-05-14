// lib/widgets/add_match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/screens_widgets/match_info_card.dart';
import 'package:box_sensors/screens_widgets/timings_card.dart';
import 'package:box_sensors/screens_widgets/add_game_button.dart';

/// Public base class so ConnectHome can call resetForm()
abstract class AddMatchResettable extends ConsumerState<AddMatchScreen> {
  /// Must clear out the form fields.
  void resetForm();
}

class AddMatchScreen extends ConsumerStatefulWidget {
  final void Function(int)? onTabChange;
  const AddMatchScreen({super.key, this.onTabChange});

  @override
  AddMatchResettable createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends AddMatchResettable {
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

  @override
  void resetForm() {
    _formKey.currentState?.reset();
    _matchNameCtrl.clear();
    _matchDateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _roundsCtrl.clear();
    _roundTimeCtrl.clear();
    _breakTimeCtrl.clear();
  }

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

    // 3) range-checks
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

    // 4) all clear—insert
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

      // ALWAYS refresh the matches list:
      // ignore: unused_result
      ref.refresh(matchesFutureProvider);

      if (widget.onTabChange != null) {
        // bottom-nav flow: switch to Games tab
        widget.onTabChange!(1);
      } else {
        // pushed route flow: pop back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to add match: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.onTabChange?.call(0);
        }
      },
      child: Scaffold(
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
                title: 'Add Game',
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      if (widget.onTabChange != null) {
                        // we’re in the bottom-nav flow: just switch tabs
                        widget.onTabChange!(0);
                      } else {
                        // we were pushed onto the Navigator stack: pop
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    8,
                    2,
                    8,
                    0,
                  ), // const EdgeInsets.all(16),
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
                                  v == null || v.isEmpty
                                      ? 'Enter a date'
                                      : null,
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
      ),
    );
  }
}
