import 'package:flutter/material.dart';

class CommonButtons {
  /// Builds a “round control” button with fixed or responsive sizing.
  static Widget buildRoundControlButton(
    BuildContext context,
    String label,
    VoidCallback? onPressed,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate button width as 40% of screen width.
    final buttonWidth = screenWidth * 0.4;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(buttonWidth, 40),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 6,
        shadowColor: theme.shadowColor,
        surfaceTintColor: theme.colorScheme.primaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  /// Builds a “settings control” button with fixed or responsive sizing.
  static Widget buildSettingsControlButton(
    BuildContext context,
    String label,
    VoidCallback? onPressed,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate button width as 45% of screen width.
    final buttonWidth = screenWidth * 0.45;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(buttonWidth, 44),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 6,
        shadowColor: theme.shadowColor,
        surfaceTintColor: theme.colorScheme.primaryContainer,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
