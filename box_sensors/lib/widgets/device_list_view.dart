// lib/widgets/device_list_view.dart

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Your list of discovered & target devices, styled exactly as before.
class DeviceListView extends StatelessWidget {
  final List<String> devices;
  final Map<String, int> rssiValues;
  final double Function(int) calculateDistance;
  final Color Function(int) getRSSIColor;
  final void Function(String) onConnect;
  final Map<String, ValueNotifier<bool>> connectionNotifiers;
  final bool Function(String) isDeviceConnected;
  final void Function(String) onDisconnect;

  const DeviceListView({
    super.key,
    required this.devices,
    required this.rssiValues,
    required this.calculateDistance,
    required this.getRSSIColor,
    required this.onConnect,
    required this.connectionNotifiers,
    required this.isDeviceConnected,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final deviceName = devices[index];
              final rssi = rssiValues[deviceName] ?? -60;
              final distance = calculateDistance(rssi);
              final textColor = deviceName == 'RedBoxer'
                  ? Colors.red
                  : deviceName == 'BlueBoxer'
                      ? Colors.blue
                      : deviceName == 'BoxerServer'
                          ? Colors.green
                          : theme.textTheme.bodyMedium?.color;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  color: theme.cardColor,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => onConnect(deviceName),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.bluetooth,
                                        color: theme.colorScheme.primary),
                                    const Gap(8.0),
                                    Expanded(
                                      child: Text(
                                        deviceName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: textColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(8.0),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: getRSSIColor(rssi),
                                      radius: 16,
                                      child: Text(
                                        '$rssi',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Gap(2.0),
                                    Text.rich(
                                      TextSpan(
                                        text: 'dBm\nDistance:',
                                        style:
                                            DefaultTextStyle.of(context).style
                                                .copyWith(fontSize: 10),
                                        children: [
                                          TextSpan(
                                            text:
                                                ' ${distance.toStringAsFixed(2)} meter(s)',
                                            style:
                                                DefaultTextStyle.of(context)
                                                    .style
                                                    .copyWith(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (connectionNotifiers
                                .containsKey(deviceName))
                              ValueListenableBuilder<bool>(
                                valueListenable: connectionNotifiers[
                                    deviceName]!,
                                builder: (context, isConn, child) {
                                  if (!isConn ||
                                      !isDeviceConnected(deviceName)) {
                                    return const SizedBox.shrink();
                                  }
                                  return ElevatedButton(
                                    onPressed: () =>
                                        onDisconnect(deviceName),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      elevation: 6,
                                      shadowColor: theme.shadowColor,
                                      surfaceTintColor: theme
                                          .colorScheme.primaryContainer,
                                      fixedSize: const Size(110, 48),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bluetooth,
                                            color:
                                                theme.colorScheme.onPrimary,
                                            size: 20),
                                        const Gap(1),
                                        Text(
                                          'Disconnect',
                                          maxLines: 1,
                                          overflow: TextOverflow.visible,
                                          style: TextStyle(
                                              color: theme
                                                  .colorScheme.onPrimary),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: devices.length,
          ),
        ),
      ],
    );
  }
}
