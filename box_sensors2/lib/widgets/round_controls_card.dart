// lib/screens/round_controls_card.dart
import 'package:flutter/material.dart';
import 'package:box_sensors2/widgets/common_buttons.dart';

class RoundControlsCard extends StatelessWidget {
  final ThemeData theme;
  final bool isStartDisabled, isEndDisabled, isPauseDisabled, isResumeDisabled;
  final VoidCallback onStart, onEnd, onPause, onResume; 

  const RoundControlsCard({
    super.key,
    required this.theme,
    required this.isStartDisabled,
    required this.isEndDisabled,
    required this.isPauseDisabled,
    required this.isResumeDisabled,
    required this.onStart,
    required this.onEnd,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Round Controls',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    CommonButtons.buildRoundControlButton(
                      context,
                      'Start Match',
                      isStartDisabled
                          ? null
                          : () {
                            onStart();
                          },
                      theme,
                    ),
                    const SizedBox(height: 4),
                    CommonButtons.buildRoundControlButton(
                      context,
                      'End Match',
                      isEndDisabled ? null : onEnd,
                      theme,
                    ),
                  ],
                ),
                Column(
                  children: [
                    CommonButtons.buildRoundControlButton(
                      context,
                      'Pause Match',
                      isPauseDisabled ? null : onPause,
                      theme,
                    ),
                    const SizedBox(height: 4),
                    CommonButtons.buildRoundControlButton(
                      context,
                      'Resume Match',
                      isResumeDisabled ? null : onResume,
                      theme,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
