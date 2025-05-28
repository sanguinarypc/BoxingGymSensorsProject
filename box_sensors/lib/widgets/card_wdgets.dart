// lib/screens/card_wdgets.dart
// The “Export Database” card
// The “Insert Sample Data” card
// The “Import Database” card
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A generic card that takes a title, description and button text.
class _DataActionCard extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onPressed;
  final String title;
  final String description;
  final String buttonText;

  const _DataActionCard({
    required this.theme,
    required this.onPressed,
    required this.title,
    required this.description,
    required this.buttonText,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(4),
            Center(
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 6,
                  shadowColor: theme.shadowColor,
                  surfaceTintColor: theme.colorScheme.primaryContainer,
                  fixedSize: const Size(300, 40),
                ),
                child: Text(buttonText, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The “Export Database” card
class ExportDatabaseCard extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onInsert;

  const ExportDatabaseCard({
    super.key,
    required this.theme,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return _DataActionCard(
      theme: theme,
      onPressed: onInsert,
      title: 'Export Database',
      description: 'Export your database into a file for easier analysis.',
      buttonText: 'Export Database',
    );
  }
}



class ImportDatabaseCard extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onInsert;

  const ImportDatabaseCard({
    super.key,
    required this.theme,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return _DataActionCard(
      theme: theme,
      onPressed: onInsert,
      title: 'Import Database',
      description: 'Import your database file into the BoxSensors App.',
      buttonText: 'Import Database',
    );
  }
}



/// The “Insert Sample Data” card
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
    return _DataActionCard(
      theme: theme,
      onPressed: onInsert,
      title: 'Database Sample Data',
      description: 'Click below to insert sample matches for testing.',
      buttonText: 'Insert Sample Data',
    );
  }
}
