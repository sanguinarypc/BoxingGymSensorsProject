// lib/screens/sample_data_card.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// The “insert sample data” card
class SampleDataCard extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onInsert;
  const SampleDataCard({
    super.key,
    required this.theme,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.cardColor,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Sample Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'Click below to insert sample matches for testing.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(4),
            Center(
              child: ElevatedButton(
                onPressed: onInsert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 6,
                  shadowColor: theme.shadowColor,
                  surfaceTintColor: theme.colorScheme.primaryContainer,
                  fixedSize: const Size(300, 40),
                ),
                child: const Text(
                  'Insert Sample Data',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
