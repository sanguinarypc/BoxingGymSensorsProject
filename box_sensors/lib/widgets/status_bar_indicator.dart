// lib/widgets/status_bar_indicator.dart
import 'package:flutter/material.dart';
import 'package:box_sensors/utils/device_config.dart';
import 'bluetooth_indicator.dart';

class StatusBarIndicator extends StatefulWidget {
  final bool isConnectedDevice1;
  final bool isConnectedDevice2;
  final bool isConnectedDevice3;

  const StatusBarIndicator({
    super.key,
    required this.isConnectedDevice1,
    required this.isConnectedDevice2,
    required this.isConnectedDevice3,
  });

  @override
  State<StatusBarIndicator> createState() => _StatusBarIndicatorState();
}

class _StatusBarIndicatorState extends State<StatusBarIndicator> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary;
    final fg = theme.colorScheme.onPrimary;

    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!.copyWith(
            color: fg,
            fontWeight: FontWeight.bold,
          ),
          child: IconTheme(
            data: IconThemeData(color: fg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BluetoothIndicator(
                  isConnected: widget.isConnectedDevice1,
                  deviceLabel: DeviceConfig.blueBoxer,
                ),
                BluetoothIndicator(
                  isConnected: widget.isConnectedDevice3,
                  deviceLabel: DeviceConfig.boxerServer,
                ),
                BluetoothIndicator(
                  isConnected: widget.isConnectedDevice2,
                  deviceLabel: DeviceConfig.redBoxer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}









// // lib/widgets/status_bar_indicator.dart
// import 'package:flutter/material.dart';
// import 'bluetooth_indicator.dart'; 

// class StatusBarIndicator extends StatefulWidget {
//   final bool isConnectedDevice1;
//   final bool isConnectedDevice2;
//   final bool isConnectedDevice3;

//   const StatusBarIndicator({
//     super.key,
//     required this.isConnectedDevice1,
//     required this.isConnectedDevice2,
//     required this.isConnectedDevice3,
//   });

//   @override
//   State<StatusBarIndicator> createState() => _StatusBarIndicatorState();
// }

// class _StatusBarIndicatorState extends State<StatusBarIndicator> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Container(
//       // Use the primary color as background.
//       decoration: BoxDecoration(
//         color: theme.colorScheme.primary,
//       ),
//       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: DefaultTextStyle(
//         // Use the theme's bodyMedium style with custom modifications.
//         style: theme.textTheme.bodyMedium!.copyWith(
//           color: theme.colorScheme.onPrimary,
//           fontWeight: FontWeight.bold,
//         ),
//         child: IconTheme(
//           data: IconThemeData(
//             color: theme.colorScheme.onPrimary,
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // Display Bluetooth indicator for first device.
//               BluetoothIndicator(
//                 isConnected: widget.isConnectedDevice1,
//                 deviceLabel: 'BlueBoxer',
//               ),
//               // Display Bluetooth indicator for third device.
//               BluetoothIndicator(
//                 isConnected: widget.isConnectedDevice3,
//                 deviceLabel: 'BoxerServer',
//               ),
//               // Display Bluetooth indicator for second device.
//               BluetoothIndicator(
//                 isConnected: widget.isConnectedDevice2,
//                 deviceLabel: 'RedBoxer',
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
