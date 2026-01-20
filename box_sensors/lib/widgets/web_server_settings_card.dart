import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:box_sensors/widgets/custom_text_form_field.dart';

class WebServerSettingsCard extends StatelessWidget {
  final ThemeData theme;
  final TextEditingController webServerUrlController;
  final bool isLoading;
  final VoidCallback onSave;

  const WebServerSettingsCard({
    super.key,
    required this.theme,
    required this.webServerUrlController,
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
              'Dashboard Web Server',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(16),
            CustomTextFormField(
              controller: webServerUrlController,
              label: 'Dashboard Web Server URL',
            ),
            const Gap(16), // Consistent spacing
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
                'Save Web Server Setting',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
