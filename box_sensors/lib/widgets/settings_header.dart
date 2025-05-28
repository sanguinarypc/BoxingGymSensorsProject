
// lib/screens/settings_header.dart
import 'package:flutter/material.dart';
import 'package:box_sensors/widgets/display_row.dart';

/// Top bar with title + back button
class SettingsHeader extends StatelessWidget {
  final VoidCallback onBack;
  const SettingsHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DisplayRow(
      title: 'Settings',
      actions: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: onBack,
        ),
      ],
    );
  }
}
