// lib/screens_widgets/match_detail_actions.dart
import 'package:flutter/material.dart';

class MatchDetailActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onAdd;
  final VoidCallback onStart;

  const MatchDetailActions({
    super.key,
    required this.onEdit,
    required this.onAdd,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 6,
                  shadowColor: theme.shadowColor,
                  surfaceTintColor: theme.colorScheme.primaryContainer,
                ),
                child: const Text('Edit Game', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 6,
                  shadowColor: theme.shadowColor,
                  surfaceTintColor: theme.colorScheme.primaryContainer,
                ),
                child: const Text('Add New Game', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: Icon(
                  Icons.sports_mma,
                  color: theme.colorScheme.onPrimary,
                ),
                label: const Text('Start Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 6,
                  shadowColor: theme.shadowColor,
                  surfaceTintColor: theme.colorScheme.primaryContainer,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
