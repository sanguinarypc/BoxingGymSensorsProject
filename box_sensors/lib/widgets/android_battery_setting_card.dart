// lib/widgets/android_battery_setting_card.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gap/gap.dart';

class AndroidBatterySettingCard extends StatefulWidget {
  const AndroidBatterySettingCard({super.key});

  @override
  State<AndroidBatterySettingCard> createState() =>
      _AndroidBatterySettingCardState();
}

class _AndroidBatterySettingCardState extends State<AndroidBatterySettingCard> {
  /// Requests the “Ignore Battery Optimizations” permission once.
  Future<void> requestAllPermissionsOnce() async {
    await [Permission.ignoreBatteryOptimizations].request();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Android Battery Optimizations Setting',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'The dialogue appears only if the option "allow" (Recommended for better battery life) is selected.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(8),
            ElevatedButton(
              onPressed: () async {
                await requestAllPermissionsOnce();

                // guard the *local* BuildContext after the async gap
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Requested battery-optimization exemption permission.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 6,
                shadowColor: theme.shadowColor,
                surfaceTintColor: theme.colorScheme.primaryContainer,
                fixedSize: const Size.fromHeight(40),
              ),
              child: const Text(
                'Battery Optimizations Setting',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
