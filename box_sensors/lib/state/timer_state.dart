// lib/state/timer_state.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/bluetooth_manager.dart';

enum MatchState { notStarted, running, breakTime, paused, ended }

class TimerState with ChangeNotifier {
  int _countdown = 0;
  int _round = 1;
  int roundTime = 0;
  int breakTime = 0;
  int rounds = 0;
  int totalRounds = 0;

  Timer? _timer;
  MatchState _matchState = MatchState.notStarted;
  MatchState? _previousState;

  bool _isStartEnabled = true;
  bool _isPauseEnabled = false;
  bool _isResumeEnabled = false;
  bool _isEndEnabled = false;

  bool _isStartButtonDisabled = false;
  bool _isEndButtonDisabled = true;
  bool _isPauseButtonDisabled = true;
  bool _isResumeButtonDisabled = true;

  VoidCallback? _sendSettingsAndStartRoundCallback;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Database & Bluetooth dependencies, to be set via initialize().
  late DatabaseHelper _dbHelper;
  late BluetoothManager _bluetoothManager;
  int? _matchId;
  String? _eventId;
  String? get eventId => _eventId;

  bool _disposed = false; // Track if the notifier is disposed.

  // ─── Your safe‐call helper ─────────────────────────────────────────────────
  void _safeCall(void Function() fn) {
    if (_disposed) return;
    try {
      fn();
    } catch (e, st) {
      debugPrint("TimerState caught: $e\n$st");
    }
  }

  // Getters for countdown and round.
  int get countdown => _countdown;
  int get round => _round;

  // Getters for match states.
  bool get isRunning => _matchState == MatchState.running;
  bool get isBreak => _matchState == MatchState.breakTime;
  bool get isPaused => _matchState == MatchState.paused;
  bool get isEndMatch => _matchState == MatchState.ended;

  // Getters and setters for button enabled flags.
  bool get isStartEnabled => _isStartEnabled;
  bool get isPauseEnabled => _isPauseEnabled;
  bool get isResumeEnabled => _isResumeEnabled;
  bool get isEndEnabled => _isEndEnabled;

  bool get isStartButtonDisabled => _isStartButtonDisabled;
  set isStartButtonDisabled(bool value) => _safeCall(() {
    _isStartButtonDisabled = value;
    notifyListeners();
  });

  bool get isEndButtonDisabled => _isEndButtonDisabled;
  set isEndButtonDisabled(bool value) => _safeCall(() {
    _isEndButtonDisabled = value;
    notifyListeners();
  });

  bool get isPauseButtonDisabled => _isPauseButtonDisabled;
  set isPauseButtonDisabled(bool value) => _safeCall(() {
    _isPauseButtonDisabled = value;
    notifyListeners();
  });

  bool get isResumeButtonDisabled => _isResumeButtonDisabled;
  set isResumeButtonDisabled(bool value) => _safeCall(() {
    _isResumeButtonDisabled = value;
    notifyListeners();
  });

  /// Initializes TimerState with the required dependencies.
  void initialize(
    DatabaseHelper dbHelper,
    BluetoothManager bluetoothManager,
    int matchId,
    String? eventId,
  ) => _safeCall(() {
    _dbHelper = dbHelper;
    _bluetoothManager = bluetoothManager;
    _matchId = matchId;
    _eventId = eventId;
    notifyListeners();
  });

  /// Called once to kick off Round 1 and every subsequent round via the callback.
  void startCountdown(VoidCallback sendStartRoundCallback) => _safeCall(() {
    _sendSettingsAndStartRoundCallback = sendStartRoundCallback;
    _matchState = MatchState.running;
    _round = 1;
    _countdown = roundTime;
    _isStartButtonDisabled = true;
    _isPauseButtonDisabled = false;
    _isEndButtonDisabled = false;
    _isResumeButtonDisabled = true;
    notifyListeners();

    _insertRound();
    _sendSettingsAndStartRoundCallback?.call();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _safeCall(() {
        if (_countdown > 0) {
          _countdown--;
          if (_countdown <= 10) _playSound();
          notifyListeners();
        } else {
          t.cancel();
          if (_round < rounds) {
            _startBreak();
          } else {
            _endMatch();
          }
        }
      });
    });
  });

  void _startRound() => _safeCall(() {
    _countdown = roundTime;
    _matchState = MatchState.running;
    notifyListeners();

    _sendSettingsAndStartRoundCallback?.call();
    _insertRound();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _safeCall(() {
        if (_countdown > 0) {
          _countdown--;
          if (_countdown <= 10) _playSound();
          notifyListeners();
        } else {
          t.cancel();
          if (_round < rounds) {
            _startBreak();
          } else {
            _endMatch();
          }
        }
      });
    });
  });

  // Starts a break period between rounds.
  void _startBreak() => _safeCall(() {
    _countdown = breakTime;
    _matchState = MatchState.breakTime;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _safeCall(() {
        if (_countdown > 0) {
          _countdown--;
          if (_countdown <= 10) _playSound();
        } else {
          _round++;
          if (_round <= rounds) {
            _startRound();
          } else {
            _round--;
            _endMatch();
          }
        }
        notifyListeners();
      });
    });
  });

  /// Ends the match.
  void endMatch() => _safeCall(_endMatch);
  
  /// Manually ends the match.
  void endMatchManually() => _safeCall(_endMatch);

  Future<void> _endMatch() async {
    _timer?.cancel();
    _matchState = MatchState.ended;
    _countdown = 0;
    _round = 1;
    resetButtonStates();

    if (_eventId != null) {
      try {
        final counts = await _dbHelper.getEventPunchCounts(_eventId!);
        final blueCount = counts['BlueBoxer'] ?? 0;
        final redCount = counts['RedBoxer'] ?? 0;
        String computedWinner;
        if (blueCount > redCount) {
          computedWinner = 'BlueBoxer';
        } else if (redCount > blueCount) {
          computedWinner = 'RedBoxer';
        } else {
          computedWinner = 'Draw';
        }
        await _dbHelper.updateCurrentEventWinner(_eventId!, computedWinner);
      } catch (e) {
        debugPrint("Error updating event winner: $e");
      }
    }

    notifyListeners();
  }

  /// Pauses the timer.
  void pauseTimer() => _safeCall(() {
    if (_matchState == MatchState.running ||
        _matchState == MatchState.breakTime) {
      _timer?.cancel();
      _previousState = _matchState;
      _matchState = MatchState.paused;
      _isPauseButtonDisabled = true;
      _isResumeButtonDisabled = false;
      notifyListeners();
    }
  });

  /// Resumes the timer if paused.
  void resumeTimer() => _safeCall(() {
    if (_matchState == MatchState.paused) {
      _matchState = _previousState ?? _matchState;
      _isPauseButtonDisabled = false;
      _isResumeButtonDisabled = true;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _safeCall(() {
          if (_countdown > 0) {
            _countdown--;
            if (_countdown <= 10) _playSound();
          } else {
            if (_matchState == MatchState.breakTime) {
              _round++;
              if (_round <= rounds) {
                _startRound();
              } else {
                _endMatch();
              }
            } else if (_round < rounds) {
              _startBreak();
            } else {
              _endMatch();
            }
          }
          notifyListeners();
        });
      });
    }
  });

  /// Resets button flags to their initial values.
  void resetButtonStates() => _safeCall(() {
    _isStartEnabled = true;
    _isPauseEnabled = false;
    _isResumeEnabled = false;
    _isEndEnabled = false;
    _isStartButtonDisabled = false;
    _isPauseButtonDisabled = true;
    _isResumeButtonDisabled = true;
    _isEndButtonDisabled = true;
    notifyListeners();
  });

  /// Plays a sound when the countdown is low.
  void _playSound() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/timetick.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  /// Inserts a new round into the database and updates BluetoothManager.
  Future<void> _insertRound() async {
    if (_matchId != null) {
      try {
        final roundId = await _dbHelper.insertRound(
          matchId: _matchId!,
          round: _round,
          eventId: _eventId,
        );
        _bluetoothManager.setCurrentRoundId(roundId);
        _bluetoothManager.setCurrentMatchId(_matchId);
      } catch (e) {
        debugPrint("Error inserting round: $e");
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _disposed = true;
    super.dispose();
  }
}










// original code
// import 'package:flutter/foundation.dart';
// import 'dart:async';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:box_sensors/services/database_helper.dart';
// import 'package:box_sensors/services/bluetooth_manager.dart';

// enum MatchState { notStarted, running, breakTime, paused, ended }

// class TimerState with ChangeNotifier {
//   int _countdown = 0;
//   int _round = 1;
//   int roundTime = 0;
//   int breakTime = 0;
//   int rounds = 0;
//   int totalRounds = 0;

//   Timer? _timer;
//   MatchState _matchState = MatchState.notStarted;
//   MatchState? _previousState;

//   bool _isStartEnabled = true;
//   bool _isPauseEnabled = false;
//   bool _isResumeEnabled = false;
//   bool _isEndEnabled = false;

//   bool _isStartButtonDisabled = false;
//   bool _isEndButtonDisabled = true;
//   bool _isPauseButtonDisabled = true;
//   bool _isResumeButtonDisabled = true;

//   VoidCallback? _sendSettingsAndStartRoundCallback;
//   final AudioPlayer _audioPlayer = AudioPlayer();

//   // Database & Bluetooth dependencies, to be set via initialize().
//   late DatabaseHelper _dbHelper;
//   late BluetoothManager _bluetoothManager;
//   int? _matchId;
//   String? _eventId;
//   String? get eventId => _eventId;

//   bool _disposed = false; // Track if the notifier is disposed.

//   // Getters for countdown and round.
//   int get countdown => _countdown;
//   int get round => _round;

//   // Getters for match states.
//   bool get isRunning => _matchState == MatchState.running;
//   bool get isBreak => _matchState == MatchState.breakTime;
//   bool get isPaused => _matchState == MatchState.paused;
//   bool get isEndMatch => _matchState == MatchState.ended;

//   // Getters and setters for button enabled flags.
//   bool get isStartEnabled => _isStartEnabled;
//   bool get isPauseEnabled => _isPauseEnabled;
//   bool get isResumeEnabled => _isResumeEnabled;
//   bool get isEndEnabled => _isEndEnabled;

//   bool get isStartButtonDisabled => _isStartButtonDisabled;
//   set isStartButtonDisabled(bool value) {
//     _isStartButtonDisabled = value;
//     _safeNotifyListeners();
//   }

//   bool get isEndButtonDisabled => _isEndButtonDisabled;
//   set isEndButtonDisabled(bool value) {
//     _isEndButtonDisabled = value;
//     _safeNotifyListeners();
//   }

//   bool get isPauseButtonDisabled => _isPauseButtonDisabled;
//   set isPauseButtonDisabled(bool value) {
//     _isPauseButtonDisabled = value;
//     _safeNotifyListeners();
//   }

//   bool get isResumeButtonDisabled => _isResumeButtonDisabled;
//   set isResumeButtonDisabled(bool value) {
//     _isResumeButtonDisabled = value;
//     _safeNotifyListeners();
//   }

//   /// Safely calls notifyListeners if not disposed.
//   void _safeNotifyListeners() {
//     if (!_disposed) {
//       notifyListeners();
//     }
//   }

//   /// Initializes TimerState with the required dependencies.
//   void initialize(
//     DatabaseHelper dbHelper,
//     BluetoothManager bluetoothManager,
//     int matchId,
//     String? eventId,
//   ) {
//     _dbHelper = dbHelper;
//     _bluetoothManager = bluetoothManager;
//     _matchId = matchId;
//     _eventId = eventId;
//     _safeNotifyListeners();
//   }

//   // void startCountdown(VoidCallback sendSettingsAndStartRoundCallback) {
//   //   _sendSettingsAndStartRoundCallback = sendSettingsAndStartRoundCallback;

//   //   // 1) Seed Round 1 state
//   //   _matchState = MatchState.running;
//   //   _round = 1;
//   //   _countdown = roundTime;
//   //   _isStartButtonDisabled = true;
//   //   _isPauseButtonDisabled = false;
//   //   _isEndButtonDisabled = false;
//   //   _isResumeButtonDisabled = true;
//   //   _safeNotifyListeners();

//   //   // 2) Send settings to ESP32 and record Round 1
//   //   _sendSettingsAndStartRoundCallback?.call();
//   //   _insertRound(); // <-- exactly once for Round 1

//   //   // 3) Start the per‑second ticker for Round 1
//   //   _timer?.cancel();
//   //   _timer = Timer.periodic(const Duration(seconds: 1), (t) {
//   //     if (_countdown > 0) {
//   //       _countdown--;
//   //       if (_countdown <= 10) _playSound();
//   //       _safeNotifyListeners();
//   //     } else {
//   //       t.cancel();
//   //       if (_round < rounds) {
//   //         _startBreak();
//   //       } else {
//   //         _endMatch();
//   //       }
//   //     }
//   //   });
//   // }

//   /// Called once to kick off Round 1 and every subsequent round via the callback.
//   void startCountdown(VoidCallback sendStartRoundCallback) {
//     _sendSettingsAndStartRoundCallback = sendStartRoundCallback;

//     // 1) Seed Round 1 state
//     _matchState = MatchState.running;
//     _round = 1;
//     _countdown = roundTime;
//     _isStartButtonDisabled = true;
//     _isPauseButtonDisabled = false;
//     _isEndButtonDisabled = false;
//     _isResumeButtonDisabled = true;
//     _safeNotifyListeners();

//     // 2) Record & announce Round 1
//     _insertRound(); // write Round 1 to the DB
//     _sendSettingsAndStartRoundCallback?.call(); // send "start round" JSON

//     // 3) Start the per‑second ticker
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (_countdown > 0) {
//         _countdown--;
//         if (_countdown <= 10) _playSound();
//         _safeNotifyListeners();
//       } else {
//         t.cancel();
//         if (_round < rounds) {
//           _startBreak(); // after break, we'll bump _round and call _startRound()
//         } else {
//           _endMatch();
//         }
//       }
//     });
//   }

//   void _startRound() {
//     // 1) Enter Round N state
//     _countdown = roundTime;
//     _matchState = MatchState.running;

//     _safeNotifyListeners();

//     // 2) Send settings & record the new round
//     _sendSettingsAndStartRoundCallback?.call();
//     _insertRound(); // <-- exactly once per round

//     // 3) Start the ticker
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (_countdown > 0) {
//         _countdown--;
//         if (_countdown <= 10) _playSound();
//         _safeNotifyListeners();
//       } else {
//         t.cancel();
//         if (_round < rounds) {
//           _startBreak();
//         } else {
//           _endMatch();
//         }
//       }
//     });
//   }

//   // Starts a break period between rounds.
//   void _startBreak() {
//     _countdown = breakTime;
//     _matchState = MatchState.breakTime;
//     _timer?.cancel();

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       try {
//         if (_countdown > 0) {
//           _countdown--;
//           if (_countdown <= 10) {
//             _playSound();
//           }
//         } else {
//           _round++;
//           if (_round <= rounds) {
//             _startRound();
//           } else {
//             _round--; // Decrement round if no more rounds and then end match.
//             _endMatch();
//           }
//         }
//       } catch (e) {
//         debugPrint("Error in break timer: $e");
//       }
//       _safeNotifyListeners();
//     });
//   }

//   /// Ends the match.
//   void endMatch() {
//     _endMatch();
//   }

//   /// Ends the match and resets values.
//   Future<void> _endMatch() async {
//     debugPrint('🔔🔔🔔 _endMatch() CALLED 🔔🔔🔔');
//     _timer?.cancel();
//     _matchState = MatchState.ended;
//     _countdown = 0;
//     _round = 1;
//     resetButtonStates();

//     // If an event is active, update the winner.
//     // if (_eventId != null) {
//     //   try {
//     //     Map<String, int> counts = await _dbHelper.getEventPunchCounts(_eventId);
//     //     String computedWinner = '';
//     //     if (counts['BlueBoxer_Punches'] != null &&
//     //         counts['RedBoxer_Punches'] != null) {
//     //       if (counts['BlueBoxer_Punches']! > counts['RedBoxer_Punches']!) {
//     //         computedWinner = "BlueBoxer";
//     //       } else if (counts['RedBoxer_Punches']! >
//     //           counts['BlueBoxer_Punches']!) {
//     //         computedWinner = "RedBoxer";
//     //       } else {
//     //         computedWinner = "Draw";
//     //       }
//     //     }
//     //     await _dbHelper.updateCurrentEventWinner(_eventId!, computedWinner);
//     //   } catch (e) {
//     //     debugPrint("Error updating event winner: $e");
//     //   }
//     // }

//     // If an event is active, compute & persist the winner.
//     if (_eventId != null) {
//       try {
//         final counts = await _dbHelper.getEventPunchCounts(_eventId!);
//         final blueCount = counts['BlueBoxer'] ?? 0;
//         final redCount = counts['RedBoxer'] ?? 0;

//         String computedWinner;
//         if (blueCount > redCount) {
//           computedWinner = 'BlueBoxer';
//         } else if (redCount > blueCount)
//           // ignore: curly_braces_in_flow_control_structures
//           computedWinner = 'RedBoxer';
//         else
//           // ignore: curly_braces_in_flow_control_structures
//           computedWinner = 'Draw';

//         await _dbHelper.updateCurrentEventWinner(_eventId!, computedWinner);
//       } catch (e) {
//         debugPrint("Error updating event winner: $e");
//       }
//     }

//     _safeNotifyListeners();
//   }

//   /// Pauses the timer.
//   void pauseTimer() {
//     if (_matchState == MatchState.running ||
//         _matchState == MatchState.breakTime) {
//       _timer?.cancel();
//       _previousState = _matchState;
//       _matchState = MatchState.paused;

//       _isPauseEnabled = false;
//       _isResumeEnabled = true;
//       _isPauseButtonDisabled = true;
//       _isResumeButtonDisabled = false;

//       _safeNotifyListeners();
//     }
//   }

//   /// Resumes the timer if paused.
//   void resumeTimer() {
//     if (_matchState == MatchState.paused) {
//       if (_previousState != null) {
//         _matchState = _previousState!;
//         _previousState = null;
//       }

//       _isPauseButtonDisabled = false;
//       _isResumeButtonDisabled = true;
//       _isPauseEnabled = true;
//       _isResumeEnabled = false;

//       _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//         try {
//           if (_countdown > 0) {
//             _countdown--;
//             if (_countdown <= 10) {
//               _playSound();
//             }
//           } else {
//             if (_matchState == MatchState.breakTime) {
//               _round++;
//               if (_round <= rounds) {
//                 _startRound();
//               } else {
//                 _endMatch();
//               }
//             } else if (_round < rounds) {
//               _startBreak();
//             } else {
//               _endMatch();
//             }
//           }
//         } catch (e) {
//           debugPrint("Error in resume timer: $e");
//         }
//         _safeNotifyListeners();
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _audioPlayer.dispose();
//     _disposed = true;
//     super.dispose();
//   }

//   /// Resets button flags to their initial values.
//   void resetButtonStates() {
//     _isStartEnabled = true;
//     _isPauseEnabled = false;
//     _isResumeEnabled = false;
//     _isEndEnabled = false;
//     _isStartButtonDisabled = false;
//     _isPauseButtonDisabled = true;
//     _isResumeButtonDisabled = true;
//     _isEndButtonDisabled = true;
//     _safeNotifyListeners();
//   }

//   /// Plays a sound when the countdown is low.
//   void _playSound() async {
//     try {
//       await _audioPlayer.setVolume(1.0);
//       await _audioPlayer.play(AssetSource('sounds/timetick.mp3'));
//     } catch (e) {
//       debugPrint("Error playing sound: $e");
//     }
//   }

//   /// Inserts a new round into the database and updates BluetoothManager.
//   Future<void> _insertRound() async {
//     if (_matchId != null) {
//       try {
//         int roundId = await _dbHelper.insertRound(
//           matchId: _matchId!,
//           round: _round,
//           eventId: _eventId,
//         );
//         _bluetoothManager.setCurrentRoundId(roundId);
//         _bluetoothManager.setCurrentMatchId(_matchId);
//       } catch (e) {
//         debugPrint("Error inserting round: $e");
//       }
//     }
//   }

//   /// Manually ends the match.
//   void endMatchManually() {
//     _endMatch();
//   }
// }
