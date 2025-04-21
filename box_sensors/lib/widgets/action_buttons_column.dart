// lib/widgets/action_buttons_column.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// The bottom three rows: Scan, Connect All, Disconnect All.
class ActionButtonsColumn extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScan;
  final ValueNotifier<int> connectedCountNotifier;
  final int maxCount;
  final VoidCallback onConnectAll;
  final VoidCallback onDisconnectAll;

  const ActionButtonsColumn({
    super.key,
    required this.isScanning,
    required this.onScan,
    required this.connectedCountNotifier,
    required this.maxCount,
    required this.onConnectAll,
    required this.onDisconnectAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: onScan,
              icon:
                  Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
              label: const Text('Scan for Devices'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 6,
                shadowColor: theme.shadowColor,
                surfaceTintColor:
                    theme.colorScheme.primaryContainer,
                fixedSize: const Size(300, 40),
              ),
            ),
          ],
        ),
        const Gap(0.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: connectedCountNotifier,
              builder: (context, count, _) {
                return ElevatedButton.icon(
                  onPressed:
                      count < maxCount ? onConnectAll : null,
                  icon: SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.smartphone,
                          size: 28,
                          color: theme.colorScheme.onPrimary,
                        ),
                        Positioned(
                          top: 2,
                          right: -2,
                          child: Icon(
                            Icons.bluetooth_connected,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  label:
                      const Text('Connect all Boxer Devices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 6,
                    shadowColor: theme.shadowColor,
                    surfaceTintColor:
                        theme.colorScheme.primaryContainer,
                    fixedSize: const Size(300, 40),
                  ),
                );
              },
            ),
          ],
        ),
        const Gap(0.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: connectedCountNotifier,
              builder: (context, count, _) {
                return ElevatedButton.icon(
                  onPressed:
                      count > 0 ? onDisconnectAll : null,
                  icon: Icon(
                    Icons.bluetooth_disabled,
                    color: theme.colorScheme.onPrimary,
                  ),
                  label: const Text('Disconnect All Devices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 6,
                    shadowColor: theme.shadowColor,
                    surfaceTintColor:
                        theme.colorScheme.primaryContainer,
                    fixedSize: const Size(300, 40),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
