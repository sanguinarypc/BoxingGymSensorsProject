import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:box_sensors2/widgets/custom_text_form_field.dart';

/// The big “JSON settings” card
class SettingsFormCard extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController fsrSensitivityController;
  final TextEditingController fsrThresholdController;
  final TextEditingController roundsController;
  final TextEditingController roundTimeController;
  final TextEditingController breakTimeController;
  final TextEditingController secondsBeforeRoundBeginsController;
  final bool isLoading;
  final VoidCallback onSave;

  const SettingsFormCard({
    super.key,
    required this.theme,
    required this.fsrSensitivityController,
    required this.fsrThresholdController,
    required this.roundsController,
    required this.roundTimeController,
    required this.breakTimeController,
    required this.secondsBeforeRoundBeginsController,
    required this.isLoading,
    required this.onSave,
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Json settings for ESP32',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(16),

            CustomTextFormField(
              controller: fsrSensitivityController,
              label: 'FSR Sensitivity (500 to 3300)',
            ),
            const Gap(16),

            CustomTextFormField(
              controller: fsrThresholdController,
              label: 'FSR Threshold (50 to 1000)',
            ),
            const Gap(16),

            CustomTextFormField(
              controller: roundsController,
              label: 'Rounds (1 to 15)',
            ),
            const Gap(16),

            CustomTextFormField(
              controller: roundTimeController,
              label: 'Round time in minutes (1 to 20 minutes)',
            ),
            const Gap(16),

            CustomTextFormField(
              controller: breakTimeController,
              label: 'Break time in seconds (10 to 600 seconds)',
            ),
            const Gap(16),

            CustomTextFormField(
              controller: secondsBeforeRoundBeginsController,
              label: 'Seconds before Round Begins (5 to 30 seconds)',
            ),
            const Gap(4),

            ElevatedButton(
              onPressed: isLoading ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 6,
                shadowColor: theme.shadowColor,
                surfaceTintColor: theme.colorScheme.primaryContainer,
                fixedSize: const Size.fromHeight(40),
              ),
              child: const Text(
                'Save Json Settings',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
