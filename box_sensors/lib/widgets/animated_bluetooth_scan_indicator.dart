// lib/widgets/animated_bluetooth_scan_indicator.dart
import 'package:flutter/material.dart';
/// A widget that shows an animated pulsating circle.
/// When [isScanning] is true, the circle pulsates (scales in and out).
/// When [isScanning] is false, the circle remains static.
class AnimatedBluetoothScanIndicator extends StatefulWidget {
  /// True if Bluetooth scanning is in progress.
  final bool isScanning;

  /// The base size (diameter) of the circle icon.
  final double size;

  const AnimatedBluetoothScanIndicator({
    super.key,
    required this.isScanning,
    this.size = 14,
  });

  @override
  State<AnimatedBluetoothScanIndicator> createState() =>
      _AnimatedBluetoothScanIndicatorState();
}

class _AnimatedBluetoothScanIndicatorState
    extends State<AnimatedBluetoothScanIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Create an AnimationController with a duration of 1 second.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Create a Tween that scales from 0.8 to 1.2 and animate it.
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // If scanning is active at the start, begin the repeating animation.
    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBluetoothScanIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare new scanning state with the old value.
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        // If scanning is enabled, repeat the animation.
        _controller.repeat(reverse: true);
      } else {
        // If scanning is disabled, stop and reset the animation.
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    // Dispose the animation controller to free up resources.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isScanning) {
      // When not scanning, render nothing.
      return const SizedBox.shrink();
    }

    // Only reached when isScanning == true:
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: Icon(Icons.circle, color: Colors.green, size: widget.size),
          ),
        );
      },
    );
  }
}
