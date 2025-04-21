import 'package:flutter/material.dart';

class BluetoothIndicator extends StatelessWidget {
  final bool isConnected;
  final String deviceLabel;

  const BluetoothIndicator({
    super.key,
    required this.isConnected,
    required this.deviceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Row(
        children: [
          // The circle indicates connection status.
          Container(
            padding: const EdgeInsets.all(2), // Adjust border thickness as needed.
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black, // Background color of the circle.
            ),
            child: Icon(
              Icons.circle,
              color: isConnected ? Colors.green : Colors.red,
              size: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            deviceLabel,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
