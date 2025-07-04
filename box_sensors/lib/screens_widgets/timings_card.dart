// lib/screens_widgets/timings_card.dart
import 'package:flutter/material.dart';
import 'package:box_sensors/widgets/custom_text_form_field.dart';

class TimingsCard extends StatelessWidget {
  final TextEditingController roundTimeCtrl;
  final TextEditingController breakTimeCtrl;
  final String? Function(String?)? roundTimeValidator;
  final String? Function(String?)? breakTimeValidator;

  const TimingsCard({
    super.key,
    required this.roundTimeCtrl,
    required this.breakTimeCtrl,
    this.roundTimeValidator,
    this.breakTimeValidator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timings', // style: theme.textTheme.titleMedium
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: roundTimeCtrl,
              label: 'Round time in minutes (1 to 20 minutes)',
              keyboardType: TextInputType.number,
              validator: roundTimeValidator,
            ),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: breakTimeCtrl,
              label: 'Break time in seconds (10 to 600 seconds)',
              keyboardType: TextInputType.number,
              validator: breakTimeValidator,
            ),
          ],
        ),
      ),
    );
  }
}
