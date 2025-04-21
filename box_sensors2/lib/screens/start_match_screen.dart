// lib/screens_widgets/start_match_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:box_sensors2/services/providers.dart';
import 'package:box_sensors2/services/bluetooth_manager.dart';
import 'package:box_sensors2/services/database_helper.dart';
import 'package:box_sensors2/screens_widgets/start_match_header.dart';
import 'package:box_sensors2/widgets/round_controls_card.dart';
import 'package:box_sensors2/widgets/display_row.dart'; // ← add this import
import 'package:box_sensors2/widgets/match_data_table.dart';

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

  // Future<void> _loadHistory() async {
  //   try {
  //     await ref
  //         .read(bluetoothManagerProvider)
  //         .loadHistory(matchId: widget.match?['id']);
  //   } catch (_) {}
  // }

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



















// // lib/screens_widgets/start_match_screen.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';
// import 'package:box_sensors2/services/providers.dart';
// import 'package:box_sensors2/services/bluetooth_manager.dart';
// import 'package:box_sensors2/services/database_helper.dart';
// import 'package:box_sensors2/screens_widgets/start_match_header.dart';
// import 'package:box_sensors2/widgets/round_controls_card.dart';
// import 'package:box_sensors2/widgets/match_data_table.dart';

// class StartMatchScreen extends ConsumerStatefulWidget {
//   final Map<String, dynamic>? match;

//   const StartMatchScreen({super.key, this.match});

//   @override
//   ConsumerState<StartMatchScreen> createState() => _StartMatchScreenState();
// }

// class _StartMatchScreenState extends ConsumerState<StartMatchScreen> {
//   late final DatabaseHelper dbHelper;
//   Map<String, dynamic>? settings;
//   late final Map<String, dynamic>? matchData;
//   final List<DataRow> tableRows = [];

//   final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);

//   static const int start = 1, pause = 2, resume = 3, end = 5;

//   @override
//   void initState() {
//     super.initState();
//     dbHelper = ref.read(databaseHelperProvider);
//     matchData = widget.match;
//     _loadSettings();
//     _loadHistory();
//   }

//   @override
//   void dispose() {
//     _countdownNotifier.dispose();
//     super.dispose();
//   }

//   /// Only call setState if still mounted.
//   void _safeSetState(VoidCallback fn) {
//     if (!mounted) return;
//     setState(fn);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bluetoothManager = ref.watch(bluetoothManagerProvider);
//     final timerState = ref.watch(timerStateProvider);
//     final theme = Theme.of(context);

//     return PopScope(
//       canPop: !timerState.isStartButtonDisabled || timerState.isEndMatch,
//       onPopInvokedWithResult: (didPop, result) {},
//       child: Scaffold(
//         body: SafeArea(
//           child: Column(
//             children: [
//               StartMatchHeader(
//                 matchName: matchData?['matchName'],
//                 timerState: timerState,
//                 theme: theme,
//               ),
//               Container(
//                 height: 24,
//                 alignment: Alignment.center,
//                 child: Text(
//                   timerState.isEndMatch
//                       ? "Match Ended – total rounds ${timerState.totalRounds}"
//                       : timerState.isBreak
//                           ? "Break time ${timerState.countdown}s left"
//                           : "Round ${timerState.round}: ${timerState.countdown}s left",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.primary,
//                   ),
//                 ),
//               ),
//               RoundControlsCard(
//                 theme: theme,
//                 isStartDisabled: timerState.isStartButtonDisabled,
//                 isEndDisabled: timerState.isEndButtonDisabled,
//                 isPauseDisabled: timerState.isPauseButtonDisabled,
//                 isResumeDisabled: timerState.isResumeButtonDisabled,
//                 onStart: () async {
//                   try {
//                     bluetoothManager.clearTable();
//                     _safeSetState(() => tableRows.clear());
//                     await _loadSettings();
//                     await _loadMatchAndStart(bluetoothManager);
//                   } catch (e, st) {
//                     Sentry.captureException(e, stackTrace: st);
//                   }
//                 },
//                 onEnd: () {
//                   final json = _genRoundJson(end);
//                   bluetoothManager.sendMessageToAllConnectedDevices(json);
//                   ref.read(timerStateProvider).endMatchManually();
//                 },
//                 onPause: () {
//                   final json = _genRoundJson(pause);
//                   bluetoothManager.sendMessageToAllConnectedDevices(json);
//                   ref.read(timerStateProvider).pauseTimer();
//                 },
//                 onResume: () {
//                   final json = _genRoundJson(resume);
//                   bluetoothManager.sendMessageToAllConnectedDevices(json);
//                   ref.read(timerStateProvider).resumeTimer();
//                 },
//               ),
//               Expanded(
//                 child: MatchDataTable(
//                   tableStream: bluetoothManager.messageStream,
//                   tableWidthProvider: () {
//                     final w = MediaQuery.of(context).size.width * 0.95;
//                     return w < 350 ? 350 : w;
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _loadSettings() async {
//     try {
//       final fetched = await dbHelper.fetchSettings();
//       settings = fetched;
//       _safeSetState(() {});
//     } catch (e, st) {
//       Sentry.captureException(e, stackTrace: st);
//     }
//   }

//   Future<void> _loadHistory() async {
//     try {
//       await ref
//           .read(bluetoothManagerProvider)
//           .loadHistory(matchId: widget.match?['id']);
//     } catch (_) {}
//   }

//   Future<void> _loadMatchAndStart(BluetoothManager mgr) async {
//     final timerState = ref.read(timerStateProvider);
//     final current = widget.match;
//     timerState.rounds = current?['rounds'] ?? 1;
//     timerState.totalRounds = timerState.rounds;
//     timerState.roundTime = ((current?['roundTime'] ?? 3) * 60);
//     timerState.breakTime = current?['breakTime'] ?? 60;

//     try {
//       final eventId = await dbHelper.insertEvent(matchId: current?['id'] ?? 0);
//       timerState.initialize(dbHelper, mgr, current?['id'], eventId);
//     } catch (e, st) {
//       Sentry.captureException(e, stackTrace: st);
//     }

//     // must await to get a String
//     final settingsJson = await _genSettingsJson();
//     mgr.sendMessageToAllConnectedDevices(settingsJson);

//     if (!mounted) return;
//     _showCountdown(mgr);
//   }

//   Future<void> _showCountdown(BluetoothManager mgr) async {
//     if (!mounted || settings == null) return;
//     final int totalSecs = settings!['secondsBeforeRoundBegins'] ?? 5;
//     _countdownNotifier.value = totalSecs;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       useRootNavigator: true,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15),
//         ),
//         title: Row(
//           children: [
//             Icon(Icons.hourglass_top, color: Theme.of(ctx).colorScheme.primary),
//             const SizedBox(width: 8),
//             const Text('Get Ready!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('Starting in…', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
//             const SizedBox(height: 16),
//             ValueListenableBuilder<int>(
//               valueListenable: _countdownNotifier,
//               builder: (_, v, __) => Text(
//                 '$v',
//                 style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ValueListenableBuilder<int>(
//               valueListenable: _countdownNotifier,
//               builder: (_, v, __) {
//                 final progress = (totalSecs - v) / totalSecs;
//                 return LinearProgressIndicator(
//                   value: progress,
//                   backgroundColor: Colors.grey[300],
//                   valueColor: AlwaysStoppedAnimation<Color>(Theme.of(ctx).colorScheme.primary),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );

//     // wait briefly for the dialog to mount
//     await Future.delayed(const Duration(milliseconds: 10));

//     for (int i = totalSecs - 1; i >= 0; i--) {
//       await Future.delayed(const Duration(seconds: 1));
//       if (!mounted) return;
//       _countdownNotifier.value = i;
//     }

//     if (mounted) {
//       Navigator.of(context, rootNavigator: true).pop();
//       ref.read(timerStateProvider).startCountdown(() {
//         final startJson = _genRoundJson(start);
//         mgr.sendMessageToAllConnectedDevices(startJson);
//       });
//     }
//   }

//   String _genRoundJson(int cmd) => jsonEncode({'RoundStatusCommand': {'Command': cmd}});

//   Future<String> _genSettingsJson() async {
//     final s = await dbHelper.fetchSettings();
//     return jsonEncode({
//       'SensorSettings': {
//         'FsrSensitivity': s!['fsrSensitivity'].toString(),
//         'FsrThreshold': s['fsrThreshold'].toString(),
//         'RoundTime': ((widget.match?['roundTime'] ?? s['roundTime']) * 60000).toString(),
//         'BreakTime': ((widget.match?['breakTime'] ?? s['breakTime']) * 1000).toString(),
//       },
//     });
//   }
// }














// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';
// import 'package:box_sensors2/services/providers.dart';
// import 'package:box_sensors2/services/bluetooth_manager.dart';
// import 'package:box_sensors2/services/database_helper.dart';
// import 'package:box_sensors2/screens_widgets/start_match_header.dart';
// import 'package:box_sensors2/widgets/round_controls_card.dart';
// import 'package:box_sensors2/widgets/match_data_table.dart';

// class StartMatchScreen extends ConsumerStatefulWidget {
//   final Map<String, dynamic>? match;

//   const StartMatchScreen({super.key, this.match});

//   @override
//   ConsumerState<StartMatchScreen> createState() => _StartMatchScreenState();
// }

// class _StartMatchScreenState extends ConsumerState<StartMatchScreen> {
//   late final DatabaseHelper dbHelper;
//   Map<String, dynamic>? settings;
//   late final Map<String, dynamic>? matchData;
//   final List<DataRow> tableRows = [];

//   Timer? _dialogCountdownTimer;
//   final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);

//   static const int start = 1, pause = 2, resume = 3, end = 5;

//   @override
//   void initState() {
//     super.initState();
//     dbHelper = ref.read(databaseHelperProvider);
//     matchData = widget.match;
//     _loadSettings();
//     _loadHistory();
//   }

//   @override
//   void dispose() {
//     _dialogCountdownTimer?.cancel();
//     _countdownNotifier.dispose();
//     super.dispose();
//   }

//   void _safeSetState(VoidCallback fn) {
//   if (!mounted) return;
//   setState(fn);
// }

//   @override
//   Widget build(BuildContext context) {
//     //final dialogContext = context; // capture before any awaits
//     final bluetoothManager = ref.watch(bluetoothManagerProvider);
//     final timerState = ref.watch(timerStateProvider);
//     final theme = Theme.of(context);

//     return PopScope(
//       canPop: !timerState.isStartButtonDisabled || timerState.isEndMatch,
//       onPopInvokedWithResult: (didPop, result) {},
//       child: Scaffold(
//         body: SafeArea(
//           child: Column(
//             children: [
//               StartMatchHeader(
//                 matchName:
//                     matchData?['matchName'], // Start Game: ${matchData?['matchName']}
//                 //matchName: 'Start Game: ${matchData?['matchName']}'
//                 timerState: timerState,
//                 theme: theme,
//               ),
//               Container(
//                 height: 24,
//                 alignment: Alignment.center,
//                 child: Text(
//                   timerState.isEndMatch
//                       ? "Match Ended – total rounds ${timerState.totalRounds}"
//                       : timerState.isBreak
//                       ? "Break time ${timerState.countdown}s left"
//                       : "Round ${timerState.round}: ${timerState.countdown}s left",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.primary,
//                   ),
//                 ),
//               ),

//               RoundControlsCard(
//                 theme: theme,
//                 isStartDisabled: timerState.isStartButtonDisabled,
//                 isEndDisabled: timerState.isEndButtonDisabled,
//                 isPauseDisabled: timerState.isPauseButtonDisabled,
//                 isResumeDisabled: timerState.isResumeButtonDisabled,
//                 onStart: () async {
//                   try {
//                     bluetoothManager.clearTable();
//                     if (!mounted) return;
//                     setState(() => tableRows.clear());
//                     await _loadSettings();
//                     await _loadMatchAndStart(bluetoothManager);
//                   } catch (e, st) {
//                     Sentry.captureException(e, stackTrace: st);
//                   }
//                 },
//                 onEnd: () {
//                   final json = _genRoundJson(end);
//                   bluetoothManager.sendMessageToAllConnectedDevices(json);
//                   ref.read(timerStateProvider).endMatchManually();
//                 },
//                 onPause: () {
//                   final json = _genRoundJson(pause);
//                   bluetoothManager.sendMessageToAllConnectedDevices(json);
//                   ref.read(timerStateProvider).pauseTimer();
//                 },
//                 onResume: () {
//                   final json = _genRoundJson(resume);
//                   bluetoothManager.sendMessageToAllConnectedDevices(json);
//                   ref.read(timerStateProvider).resumeTimer();
//                 },
//               ),
//               Expanded(
//                 child: MatchDataTable(
//                   tableStream: bluetoothManager.messageStream,
//                   tableWidthProvider: () {
//                     final w = MediaQuery.of(context).size.width * 0.95;
//                     return w < 350 ? 350 : w;
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _loadSettings() async {
//     try {
//       settings = await dbHelper.fetchSettings();
//       if (!mounted) return;
//       setState(() {});
//     } catch (e, st) {
//       Sentry.captureException(e, stackTrace: st);
//     }
//   }

//   Future<void> _loadHistory() async {
//     try {
//       await ref
//           .read(bluetoothManagerProvider)
//           .loadHistory(matchId: widget.match?['id']);
//     } catch (_) {}
//   }

//   Future<void> _loadMatchAndStart(BluetoothManager mgr) async {
//     final timerState = ref.read(timerStateProvider);
//     final current = widget.match;
//     timerState.rounds = current?['rounds'] ?? 1;
//     timerState.totalRounds = timerState.rounds;
//     timerState.roundTime = ((current?['roundTime'] ?? 3) * 60);
//     timerState.breakTime = current?['breakTime'] ?? 60;

//     try {
//       final eventId = await dbHelper.insertEvent(matchId: current?['id'] ?? 0);
//       timerState.initialize(dbHelper, mgr, current?['id'], eventId);
//     } catch (e, st) {
//       Sentry.captureException(e, stackTrace: st);
//     }

//     // ← **this** must be awaited so you pass a String, not a Future<String>
//     final settingsJson = await _genSettingsJson();
//     mgr.sendMessageToAllConnectedDevices(settingsJson);

//     if (!mounted) return; // <-----------------------------------------
//     _showCountdown(mgr);
//   }

//   Future<void> _showCountdown(BluetoothManager mgr) async {
//     if (!mounted || settings == null) return;
//     // 1) How many seconds?
//     final int totalSecs = settings!['secondsBeforeRoundBegins'] ?? 5;
//     _countdownNotifier.value = totalSecs;

//     // 2) Show the dialog (it uses ValueListenableBuilder on our notifier)
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       useRootNavigator: true,
//       builder:
//           (ctx) => AlertDialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             title: Row(
//               children: [
//                 Icon(
//                   Icons.hourglass_top,
//                   color: Theme.of(ctx).colorScheme.primary,
//                 ),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Get Ready!',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Starting in…',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // Big countdown number
//                 ValueListenableBuilder<int>(
//                   valueListenable: _countdownNotifier,
//                   builder:
//                       (_, v, __) => Text(
//                         '$v',
//                         style: TextStyle(
//                           fontSize: 48,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(ctx).colorScheme.primary,
//                         ),
//                       ),
//                 ),
//                 const SizedBox(height: 16),
//                 // Progress bar
//                 ValueListenableBuilder<int>(
//                   valueListenable: _countdownNotifier,
//                   builder: (_, v, __) {
//                     final progress = (totalSecs - v) / totalSecs;
//                     return LinearProgressIndicator(
//                       value: progress,
//                       backgroundColor: Colors.grey[300],
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         Theme.of(ctx).colorScheme.primary,
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//     );

//     // give Flutter a moment to actually mount that dialog widget
//     await Future.delayed(const Duration(milliseconds: 10));

//     // 3) Drive the countdown yourself
//     for (int i = totalSecs - 1; i >= 0; i--) {
//       await Future.delayed(const Duration(seconds: 1));
//       if (!mounted) return;
//       _countdownNotifier.value = i;
//     }

//     // 4) Close the dialog, then hand off to TimerState
//     if (mounted) {
//       Navigator.of(context, rootNavigator: true).pop();

//       // Start your rounds—TimerState.startCountdown will now send exactly one “start round” JSON per round
//       ref.read(timerStateProvider).startCountdown(() {
//         final startJson = _genRoundJson(start);
//         mgr.sendMessageToAllConnectedDevices(startJson);
//       });
//     }
//   }

//   String _genRoundJson(int cmd) => jsonEncode({
//     'RoundStatusCommand': {'Command': cmd},
//   });

//   Future<String> _genSettingsJson() async {
//     final s = await dbHelper.fetchSettings();
//     return jsonEncode({
//       'SensorSettings': {
//         'FsrSensitivity': s!['fsrSensitivity'].toString(),
//         'FsrThreshold': s['fsrThreshold'].toString(),
//         'RoundTime':
//             ((widget.match?['roundTime'] ?? s['roundTime']) * 60000).toString(),
//         'BreakTime':
//             ((widget.match?['breakTime'] ?? s['breakTime']) * 1000).toString(),
//       },
//     });
//   }
// }





// Original Code  ----------------------- Dont remove it-------------------
// lib/screens/start_match_screen.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:box_sensors2/services/providers.dart';
// import 'package:box_sensors2/services/bluetooth_manager.dart';
// import 'package:box_sensors2/services/database_helper.dart';
// import 'package:box_sensors2/widgets/display_row.dart';
// import 'package:box_sensors2/widgets/common_buttons.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

// class StartMatchScreen extends ConsumerStatefulWidget {
//   final Stream<List<DataRow>> dataTableStream;
//   final Function(String) sendMessage;
//   final Map<String, dynamic>? match;

//   const StartMatchScreen({
//     super.key,
//     required this.dataTableStream,
//     required this.sendMessage,
//     this.match,
//   });

//   @override
//   ConsumerState<StartMatchScreen> createState() => _StartMatchScreenState();
// }

// class _StartMatchScreenState extends ConsumerState<StartMatchScreen> {
//   List<DataRow> tableRows = [];
//   // late final DatabaseHelper dbHelper = DatabaseHelper();
//   late final DatabaseHelper dbHelper;
//   Map<String, dynamic>? settings;
//   String matchTimeCounter = "";
//   late Map<String, dynamic>? matchData;

//   static const int start = 1;
//   static const int pause = 2;
//   static const int resume = 3;
//   static const int end = 5;

//   static const List<String> tableHeaders = [
//     'Device',
//     'PunchBy',
//     'PunchCount',
//     'Timestamp',
//     'Sensor',
//   ];

//   Timer? _dialogCountdownTimer;
//   final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(0);

//   @override
//   void initState() {
//     super.initState();
//      // Initialize the dbHelper using ref.read here
//     dbHelper = ref.read(databaseHelperProvider);

//     _loadSettings();
//     matchData = widget.match;
//     _loadMessagesFromDatabase();
//   }

//   @override
//   void dispose() {
//     _dialogCountdownTimer?.cancel();
//     _countdownNotifier.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     double tableWidth = screenWidth * 0.95;
//     if (tableWidth < 350) tableWidth = 350;

//     final bluetoothManager = ref.watch(bluetoothManagerProvider);
//     final timerState = ref.watch(timerStateProvider);
//     final theme = Theme.of(context);

//     return PopScope(
//       canPop: !timerState.isStartButtonDisabled || timerState.isEndMatch,
//       onPopInvokedWithResult: (bool didPop, dynamic result) {},
//       child: Scaffold(
//         body: SafeArea(
//           child: Column(
//             children: [
//               DisplayRow(
//                 fontSize: 14,
//                 title: 'Start Game: ${matchData?['matchName']}',
//                 actions: [
//                   IconButton(
//                     icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
//                     onPressed: timerState.isEndMatch || !timerState.isStartButtonDisabled
//                         ? () => Navigator.pop(context)
//                         : null,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 2),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 1),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         Center(
//                           child: Text(
//                             timerState.isEndMatch
//                                 ? "Match Ended total rounds ${timerState.totalRounds}"
//                                 : timerState.isBreak
//                                     ? "Break time ${timerState.countdown}s left"
//                                     : "Round ${timerState.round}: ${timerState.countdown}s left",
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
//                           ),
//                         ),
//                       ],
//                     ),
//                     Card(
//                       elevation: 4.0,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
//                       child: Padding(
//                         padding: const EdgeInsets.all(4.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text('Round Controls', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//                             const SizedBox(height: 2),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                               children: [
//                                 Column(
//                                   children: [
//                                     CommonButtons.buildRoundControlButton(
//                                       context,
//                                       'Start Match',
//                                       timerState.isStartButtonDisabled
//                                           ? null
//                                           : () async {
//                                               try {
//                                                 setState(() => timerState.isStartButtonDisabled = true);
//                                                 bluetoothManager.clearTable();
//                                                 setState(() => tableRows.clear());
//                                                 await loadMatchSettingsAndStartGame(bluetoothManager);
//                                               } catch (e, stackTrace) {
//                                                 debugPrint("Error starting match: $e\n$stackTrace");
//                                                 Sentry.captureException(e, stackTrace: stackTrace);
//                                               }
//                                             },
//                                       theme,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     CommonButtons.buildRoundControlButton(
//                                       context,
//                                       'End Match',
//                                       timerState.isEndButtonDisabled
//                                           ? null
//                                           : () async {
//                                               try {
//                                                 setState(() => timerState.isEndButtonDisabled = true);
//                                                 final jsonString = generateRoundStatusCommandJson(end);
//                                                 bluetoothManager.sendMessageToAllConnectedDevices(jsonString);
//                                                 setState(() => timerState.endMatchManually());
//                                               } catch (e, stackTrace) {
//                                                 debugPrint("Error ending match: $e\n$stackTrace");
//                                                 Sentry.captureException(e, stackTrace: stackTrace);
//                                               }
//                                             },
//                                       theme,
//                                     ),
//                                   ],
//                                 ),
//                                 Column(
//                                   children: [
//                                     CommonButtons.buildRoundControlButton(
//                                       context,
//                                       'Pause Match',
//                                       timerState.isPauseButtonDisabled
//                                           ? null
//                                           : () async {
//                                               try {
//                                                 setState(() => timerState.isPauseButtonDisabled = true);
//                                                 final jsonString = generateRoundStatusCommandJson(pause);
//                                                 bluetoothManager.sendMessageToAllConnectedDevices(jsonString);
//                                                 timerState.pauseTimer();
//                                               } catch (e, stackTrace) {
//                                                 debugPrint("Error pausing match: $e\n$stackTrace");
//                                                 Sentry.captureException(e, stackTrace: stackTrace);
//                                               }
//                                             },
//                                       theme,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     CommonButtons.buildRoundControlButton(
//                                       context,
//                                       'Resume Match',
//                                       timerState.isResumeButtonDisabled
//                                           ? null
//                                           : () async {
//                                               try {
//                                                 setState(() => timerState.isResumeButtonDisabled = true);
//                                                 final jsonString = generateRoundStatusCommandJson(resume);
//                                                 bluetoothManager.sendMessageToAllConnectedDevices(jsonString);
//                                                 timerState.resumeTimer();
//                                               } catch (e, stackTrace) {
//                                                 debugPrint("Error resuming match: $e\n$stackTrace");
//                                                 Sentry.captureException(e, stackTrace: stackTrace);
//                                               }
//                                             },
//                                       theme,
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: ConstrainedBox(
//                     constraints: BoxConstraints(minWidth: tableWidth),
//                     child: Column(
//                       children: [
//                         _buildTableHeader(theme, tableWidth),
//                         const Divider(height: 1, thickness: 1),
//                         Expanded(
//                           child: SingleChildScrollView(
//                             child: _buildTableBody(context, bluetoothManager, tableWidth),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTableHeader(ThemeData theme, double tableWidth) {
//     return Container(
//       width: tableWidth,
//       color: theme.colorScheme.surfaceTint,
//       child: Row(
//         children: tableHeaders.map((header) => _buildHeaderCell(header, theme)).toList(),
//       ),
//     );
//   }

//   Widget _buildHeaderCell(String text, ThemeData theme) {
//     return Expanded(
//       flex: 1,
//       child: Container(
//         color: theme.colorScheme.primary,
//         child: Center(
//           child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.0, color: theme.colorScheme.onPrimary)),
//         ),
//       ),
//     );
//   }

//   Widget _buildTableBody(BuildContext context, BluetoothManager bluetoothManager, double tableWidth) {
//     return StreamBuilder<List<DataRow>>(
//       stream: bluetoothManager.messageStream,
//       builder: (context, snapshot) {
//         final rowsToDisplay =
//             snapshot.hasData && snapshot.data!.isNotEmpty ? snapshot.data! : tableRows;
//         if (rowsToDisplay.isEmpty) {
//           return const Center(child: Text('No sensor(s) data yet.'));
//         }
//         return Scrollbar(
//           child: SingleChildScrollView(
//             child: Column(
//               children: rowsToDisplay.reversed.map((dataRow) {
//                 return IntrinsicHeight(
//                   child: Row(
//                     children: dataRow.cells.map((dataCell) {
//                       return Container(
//                         width: tableWidth / tableHeaders.length,
//                         padding: const EdgeInsets.all(1),
//                         alignment: Alignment.center,
//                         child: dataCell.child,
//                       );
//                     }).toList(),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Future<void> loadMatchSettingsAndStartGame(BluetoothManager bluetoothManager) async {
//     final timerState = ref.read(timerStateProvider);
//     final currentMatch = widget.match;
//     timerState.rounds = currentMatch?['rounds'] ?? 1;
//     timerState.totalRounds = timerState.rounds;
//     timerState.roundTime = (currentMatch?['roundTime'] != null
//         ? (currentMatch!['roundTime'] is int
//             ? currentMatch['roundTime']
//             : int.tryParse(currentMatch['roundTime'].toString()) ?? 0)
//         : 3) *
//         60;
//     timerState.breakTime = currentMatch?['breakTime'] ?? 60;

//     debugPrint('⚙️ Game settings loaded:');
//     debugPrint('Rounds: ${timerState.rounds}');
//     debugPrint('Total Rounds: ${timerState.totalRounds}');
//     debugPrint('Round Time (seconds): ${timerState.roundTime}');
//     debugPrint('Break Time (seconds): ${timerState.breakTime}');

//     try {
//       String eventId = await dbHelper.insertEvent(matchId: currentMatch?['id'] ?? 0);
//       timerState.initialize(dbHelper, bluetoothManager, currentMatch?['id'], eventId);
//     } catch (e, stackTrace) {
//       debugPrint('Error inserting event: $e\n$stackTrace');
//       Sentry.captureException(e, stackTrace: stackTrace);
//     }

//     if (!mounted) return;
//     showCountdownDialog(context, bluetoothManager);
//   }

//   Future<String> generateSensorSettingsJson() async {
//     try {
//       Map<String, dynamic>? settings = await dbHelper.fetchSettings();
//       int roundTime = widget.match?['roundTime'] ?? settings?['roundTime'] ?? 3;
//       int breakTime = widget.match?['breakTime'] ?? settings?['breakTime'] ?? 60;
//       return jsonEncode({
//         "SensorSettings": {
//           "FsrSensitivity": settings!['fsrSensitivity'].toString(),
//           "FsrThreshold": settings['fsrThreshold'].toString(),
//           "RoundTime": (roundTime * 60000).toString(),
//           "BreakTime": (breakTime * 1000).toString(),
//         },
//       }).toString();
//     } catch (e, stackTrace) {
//       debugPrint('Error generating sensor settings JSON: $e\n$stackTrace');
//       Sentry.captureException(e, stackTrace: stackTrace);
//       return '';
//     }
//   }

//   // Future<void> _loadMessagesFromDatabaseOld() async {
//   //   try {
//   //     final messages = await dbHelper.fetchMessagesByMatchId(widget.match?['id']);
//   //     if (!mounted) return;
//   //     setState(() {
//   //       tableRows.insertAll(0, messages.map((message) => _buildDataRow(message)));
//   //     });
//   //   } catch (e, stackTrace) {
//   //     debugPrint('Error loading messages: $e\n$stackTrace');
//   //     Sentry.captureException(e, stackTrace: stackTrace);
//   //   }
//   // }

//   Future<void> _loadMessagesFromDatabase() async {
//   try {
//     // 1️⃣ Grab your BluetoothManager instance
//     final bluetoothManager = ref.read(bluetoothManagerProvider);

//     // 2️⃣ Ask it to bulk‑load history for this match (debounced under the hood)
//     await bluetoothManager.loadHistory(matchId: widget.match?['id']);

//     // 3️⃣ Done!  The StreamBuilder on `bluetoothManager.messageStream`
//     // will automatically rebuild your table at a throttled cadence.
//   } catch (e, stackTrace) {
//     debugPrint('Error loading messages: $e\n$stackTrace');
//     Sentry.captureException(e, stackTrace: stackTrace);
//   }
// }


//   // DataRow _buildDataRow(Map<String, dynamic> message) {
//   //   return DataRow(
//   //     cells: [
//   //       _buildDataCell(message['device']),
//   //       _buildDataCell(message['punchBy']),
//   //       _buildDataCell(message['punchCount']),
//   //       _buildDataCell(message['timestamp']),
//   //       _buildDataCell(message['sensorValue']),
//   //     ],
//   //   );
//   // }

//   // DataCell _buildDataCell(String? value) {
//   //   return DataCell(Center(child: Text(value ?? '', style: const TextStyle(fontSize: 12.0))));
//   // }

//   Future<void> _loadSettings() async {
//     try {
//       settings = await dbHelper.fetchSettings();
//       if (!mounted) return;
//       setState(() {});
//     } catch (e, stackTrace) {
//       debugPrint('Error loading settings: $e\n$stackTrace');
//       Sentry.captureException(e, stackTrace: stackTrace);
//     }
//   }

//   Future<void> clearDatabaseMessages() async {
//     try {
//       await dbHelper.clearMessages();
//       if (!mounted) return;
//       setState(() {
//         tableRows.clear();
//       });
//     } catch (e, stackTrace) {
//       debugPrint('Error clearing messages: $e\n$stackTrace');
//       Sentry.captureException(e, stackTrace: stackTrace);
//     }
//   }

//   String generateRoundStatusCommandJson(int command) {
//     return jsonEncode({
//       "RoundStatusCommand": {"Command": command},
//     });
//   }

//   void showCountdownDialog(BuildContext context, BluetoothManager bluetoothManager) {
//     if (!mounted || settings == null) return;
//     final secondsBefore = settings!['secondsBeforeRoundBegins'] ?? 5;
//     _countdownNotifier.value = secondsBefore;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         _dialogCountdownTimer?.cancel();
//         _dialogCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
//           if (_countdownNotifier.value > 0) {
//             _countdownNotifier.value--;
//           } else {
//             timer.cancel();
//             Navigator.of(context, rootNavigator: true).maybePop();
//             if (!mounted) return;
//             final timerState = ref.read(timerStateProvider);
//             timerState.startCountdown(() =>
//                 _sendSettingsAndStartRound(bluetoothManager, timerState.eventId!));
//           }
//         });
//         return AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           title: Row(
//             children: [
//               Icon(Icons.hourglass_top, color: Theme.of(dialogContext).colorScheme.primary),
//               const SizedBox(width: 8),
//               const Text('Get Ready!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Starting in...',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
//               const SizedBox(height: 16),
//               ValueListenableBuilder<int>(
//                 valueListenable: _countdownNotifier,
//                 builder: (context, value, child) => Text('$value',
//                     style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(dialogContext).colorScheme.primary)),
//               ),
//               const SizedBox(height: 16),
//               ValueListenableBuilder<int>(
//                 valueListenable: _countdownNotifier,
//                 builder: (context, value, child) {
//                   final progress = (secondsBefore - value) / secondsBefore;
//                   return LinearProgressIndicator(
//                     value: progress,
//                     backgroundColor: Colors.grey[300],
//                     valueColor: AlwaysStoppedAnimation<Color>(Theme.of(dialogContext).colorScheme.primary),
//                   );
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     ).then((_) => _dialogCountdownTimer?.cancel());
//   }

//   Future<void> _sendSettingsAndStartRound(BluetoothManager bluetoothManager, String eventId) async {
//     try {
//       String sensorSettings = await generateSensorSettingsJson();
//       bluetoothManager.sendMessageToAllConnectedDevices(sensorSettings);
//       bluetoothManager.sendMessageToAllConnectedDevices(generateRoundStatusCommandJson(start));
//     } catch (e, stackTrace) {
//       debugPrint("Error sending settings and starting round: $e\n$stackTrace");
//       Sentry.captureException(e, stackTrace: stackTrace);
//     }
//   }
// }
