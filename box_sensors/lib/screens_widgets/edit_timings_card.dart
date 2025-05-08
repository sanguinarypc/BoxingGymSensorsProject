import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:box_sensors/widgets/custom_text_form_field.dart';

class EditTimingsCard extends StatelessWidget {
  final TextEditingController roundTimeCtrl;
  final TextEditingController breakTimeCtrl;
  final TextEditingController finishedAtRoundCtrl;
  final TextEditingController totalTimeCtrl;

  final String? Function(String?) roundTimeValidator;
  final String? Function(String?) breakTimeValidator;
  final String? Function(String?) finishedAtRoundValidator;
  final String? Function(String?) totalTimeValidator;

  const EditTimingsCard({
    super.key,
    required this.roundTimeCtrl,
    required this.breakTimeCtrl,
    required this.finishedAtRoundCtrl,
    required this.totalTimeCtrl,
    required this.roundTimeValidator,
    required this.breakTimeValidator,
    required this.finishedAtRoundValidator,
    required this.totalTimeValidator,
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
              label: 'Round Time (min)',
              keyboardType: TextInputType.number,
              validator: roundTimeValidator,
            ),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: breakTimeCtrl,
              label: 'Break Time (sec)',
              keyboardType: TextInputType.number,
              validator: breakTimeValidator,
            ),
            const SizedBox(height: 16),
            CustomTextFormField(
              controller: finishedAtRoundCtrl,
              label: 'Finished at Round',
              keyboardType: TextInputType.number,
              validator: finishedAtRoundValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: totalTimeCtrl,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.colorScheme.surface,
                labelText: 'Total Time (MM:SS)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [CustomTimeInputFormatter()],
              validator: totalTimeValidator,
            ),
          ],
        ),
      ),
    );
  }
}

/// formats raw digits as MM:SS
class CustomTimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    String formatted = digits;
    if (digits.length >= 3) {
      formatted = '${digits.substring(0, 2)}:${digits.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
