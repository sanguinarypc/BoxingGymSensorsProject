// lib/screens/start_match_header.dart
import 'package:flutter/material.dart';
import 'package:box_sensors2/widgets/display_row.dart';

class StartMatchHeader extends StatelessWidget {
  final String? matchName;
  final dynamic timerState;
  final ThemeData theme;

  const StartMatchHeader({
    super.key,
    required this.matchName,
    required this.timerState,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return DisplayRow(
      fontSize: 14,
      title: 'Start Game: $matchName',
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: timerState.isEndMatch || !timerState.isStartButtonDisabled
              ? () => Navigator.pop(context)
              : null,
        ),
      ],
    );
  }
}