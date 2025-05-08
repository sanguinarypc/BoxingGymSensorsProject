// lib/screens_widgets/start_match_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/services/bluetooth_manager.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/screens_widgets/start_match_header.dart';
import 'package:box_sensors/widgets/round_controls_card.dart';
import 'package:box_sensors/widgets/display_row.dart'; // ← add this import
import 'package:box_sensors/widgets/match_data_table.dart';

class StartMatchScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? match;

  const StartMatchScreen({super.key, this.match});

  @override
  ConsumerState<StartMatchScreen> createState() => _StartMatchScreenState();
}

class _StartMatchScreenState extends ConsumerState<StartMatchScreen> {
  late final DatabaseHelper dbHelper;
  Map<String, dynamic>? settings;
  late final Map<String, dynamic>? matchData;
  final List<DataRow> tableRows = [];

  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);

  static const int start = 1, pause = 2, resume = 3, end = 5;

  @override
  void initState() {
    super.initState();
    dbHelper = ref.read(databaseHelperProvider);
    matchData = widget.match;
    _loadSettings();
    // _loadHistory();
  }

  @override
  void dispose() {
    _countdownNotifier.dispose();
    super.dispose();
  }

  /// Only call setState if still mounted.
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // … rest of your methods (_loadSettings, _showCountdown, etc.) stay unchanged …
  Future<void> _loadSettings() async {
    try {
      final fetched = await dbHelper.fetchSettings();
      settings = fetched;
      _safeSetState(() {});
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }
  }

  Future<void> _loadMatchAndStart(BluetoothManager mgr) async {
    final timerState = ref.read(timerStateProvider);
    final current = widget.match;
    timerState.rounds = current?['rounds'] ?? 1;
    timerState.totalRounds = timerState.rounds;
    timerState.roundTime = ((current?['roundTime'] ?? 3) * 60);
    timerState.breakTime = current?['breakTime'] ?? 60;

    try {
      final eventId = await dbHelper.insertEvent(matchId: current?['id'] ?? 0);
      timerState.initialize(dbHelper, mgr, current?['id'], eventId);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }

    // must await to get a String
    final settingsJson = await _genSettingsJson();
    mgr.sendMessageToAllConnectedDevices(settingsJson);

    if (!mounted) return;
    _showCountdown(mgr);
  }

  Future<void> _showCountdown(BluetoothManager mgr) async {
    if (!mounted || settings == null) return;
    final int totalSecs = settings!['secondsBeforeRoundBegins'] ?? 5;
    _countdownNotifier.value = totalSecs;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.hourglass_top,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Get Ready!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Starting in…',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: _countdownNotifier,
                  builder:
                      (_, v, __) => Text(
                        '$v',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: _countdownNotifier,
                  builder: (_, v, __) {
                    final progress = (totalSecs - v) / totalSecs;
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(ctx).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );

    // wait briefly for the dialog to mount
    await Future.delayed(const Duration(milliseconds: 10));

    for (int i = totalSecs - 1; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _countdownNotifier.value = i;
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ref.read(timerStateProvider).startCountdown(() {
        final startJson = _genRoundJson(start);
        mgr.sendMessageToAllConnectedDevices(startJson);
      });
    }
  }

  String _genRoundJson(int cmd) => jsonEncode({
    'RoundStatusCommand': {'Command': cmd},
  });

  Future<String> _genSettingsJson() async {
    final s = await dbHelper.fetchSettings();
    return jsonEncode({
      'SensorSettings': {
        'FsrSensitivity': s!['fsrSensitivity'].toString(),
        'FsrThreshold': s['fsrThreshold'].toString(),
        'RoundTime':
            ((widget.match?['roundTime'] ?? s['roundTime']) * 60000).toString(),
        'BreakTime':
            ((widget.match?['breakTime'] ?? s['breakTime']) * 1000).toString(),
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothManager = ref.watch(bluetoothManagerProvider);
    final timerState = ref.watch(timerStateProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: !timerState.isStartButtonDisabled || timerState.isEndMatch,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              StartMatchHeader(
                matchName: matchData?['matchName'],
                timerState: timerState,
                theme: theme,
              ),
              Container(
                height: 24,
                alignment: Alignment.center,
                child: Text(
                  timerState.isEndMatch
                      ? "Match Ended – total rounds ${timerState.totalRounds}"
                      : timerState.isBreak
                      ? "Break time ${timerState.countdown}s left"
                      : "Round ${timerState.round}: ${timerState.countdown}s left",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              RoundControlsCard(
                theme: theme,
                isStartDisabled: timerState.isStartButtonDisabled,
                isEndDisabled: timerState.isEndButtonDisabled,
                isPauseDisabled: timerState.isPauseButtonDisabled,
                isResumeDisabled: timerState.isResumeButtonDisabled,
                onStart: () async {
                  try {
                    bluetoothManager.clearTable();
                    _safeSetState(() => tableRows.clear());
                    await _loadSettings();
                    await _loadMatchAndStart(bluetoothManager);
                  } catch (e, st) {
                    Sentry.captureException(e, stackTrace: st);
                  }
                },
                onEnd: () {
                  final json = _genRoundJson(end);
                  bluetoothManager.sendMessageToAllConnectedDevices(json);
                  ref.read(timerStateProvider).endMatchManually();
                },
                onPause: () {
                  final json = _genRoundJson(pause);
                  bluetoothManager.sendMessageToAllConnectedDevices(json);
                  ref.read(timerStateProvider).pauseTimer();
                },
                onResume: () {
                  final json = _genRoundJson(resume);
                  bluetoothManager.sendMessageToAllConnectedDevices(json);
                  ref.read(timerStateProvider).resumeTimer();
                },
              ),

              // DATA TABLE
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: bluetoothManager.rawMessageStream,
                  initialData: const [],
                  builder: (context, snap) {
                    final msgs = snap.data ?? [];
                    final blue =
                        msgs.where((m) => m['punchBy'] == 'BlueBoxer').length;
                    final red =
                        msgs.where((m) => m['punchBy'] == 'RedBoxer').length;

                    return Column(
                      children: [
                        DisplayRow(
                          fontSize: 14,
                          title: 'Punches ➜ BlueBoxer: $blue - RedBoxer: $red',
                        ),
                        Expanded(
                          child: MatchDataTable(
                            tableStream: bluetoothManager.messageStream,
                            tableWidthProvider: () {
                              final w =
                                  MediaQuery.of(context).size.width * 0.95;
                              return w < 350 ? 350 : w;
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
