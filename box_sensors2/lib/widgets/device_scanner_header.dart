// lib/widgets/device_scanner_header.dart
import 'package:flutter/material.dart';
import 'package:box_sensors2/widgets/display_row.dart';
import 'package:box_sensors2/widgets/animated_bluetooth_scan_indicator.dart';

/// Header row with title and animated scan indicator.
class DeviceScannerHeader extends StatelessWidget {
  final bool isScanning;
  const DeviceScannerHeader({super.key, required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return DisplayRow(
      title: 'Device Scanner',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AnimatedBluetoothScanIndicator(
            isScanning: isScanning,
            size: 20,
          ),
        ),
      ],
    );
  }
}
