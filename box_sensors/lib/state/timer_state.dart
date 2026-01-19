// lib/state/timer_state.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/bluetooth_manager.dart';
import 'package:box_sensors/utils/device_config.dart';

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

  /// Formats seconds into "mm:ss:00" format to match the punch data format (mm:ss:cs).
  /// We assume 00 centiseconds for these system events as they happen on the second tick.
  String _formatSystemTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    String minStr = minutes.toString().padLeft(2, '0');
    String secStr = seconds.toString().padLeft(2, '0');
    return "$minStr:$secStr:00";
  }

  /// Called once to kick off Round 1 and every subsequent round via the callback.
  void startCountdown(VoidCallback sendStartRoundCallback) =>
      _safeCall(() async {
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
        // Reset server data if this is the start of the match (Round 1)
        if (_round == 1) {
          await _bluetoothManager.resetServerData();
        }
        _bluetoothManager.sendSystemEvent(
          _round,
          "RoundStart",
          timestamp: _formatSystemTime(0),
        );
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
    _bluetoothManager.sendSystemEvent(
      _round,
      "RoundStart",
      timestamp: _formatSystemTime(0),
    );

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
    _matchState = MatchState.breakTime;
    _bluetoothManager.sendSystemEvent(
      _round,
      "RoundEnd",
      timestamp: _formatSystemTime(0),
    );
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
    // Send Match End event for the *final* round that just finished
    // Note: _round has been reset to 1, but we likely want to record the last round.
    // However, logic above increments _round. If we are here, we finished the last round.
    // So current _round is 1. We might need to track `rounds`.
    // Actually, let's just send "MatchEnd" with round 0 or generic updates?
    // Or we send it for `rounds` (max rounds)?
    // The dashboard sorts by round ID.
    _bluetoothManager.sendSystemEvent(
      rounds,
      "MatchEnd",
      timestamp: _formatSystemTime(0),
    );

    if (_eventId != null) {
      try {
        final counts = await _dbHelper.getEventPunchCounts(_eventId!);
        final blueCount = counts[DeviceConfig.blueBoxer] ?? 0;
        final redCount = counts[DeviceConfig.redBoxer] ?? 0;
        String computedWinner;
        if (blueCount > redCount) {
          computedWinner = DeviceConfig.blueBoxer;
        } else if (redCount > blueCount) {
          computedWinner = DeviceConfig.redBoxer;
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
        _bluetoothManager.setCurrentRoundNumber(_round);
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
