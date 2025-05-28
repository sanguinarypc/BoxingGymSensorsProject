// lib/widgets/about_dialog_animation.dart
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

/// A reusable dialog widget that shows an animated "About" screen for the Box Sensors app.
class AboutDialogAnimation extends StatelessWidget {
  const AboutDialogAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const colorizeColors = [
      Colors.purple,
      Colors.blue,
      Colors.yellow,
      Colors.red,
    ];
    const colorizeTextStyle = TextStyle(
      fontSize: 32.0,
      fontFamily: 'Horizon',
    );

    return AlertDialog(
      // App icon at the top
      title: Center(
        child: CircleAvatar(
          radius: 42,
          backgroundColor: Colors.transparent,
          child: Icon(
            Icons.sports_mma,
            color: colorScheme.primary,
            size: 80,
          ),
        ),
      ),
      // Animated title and developer name
      content: SizedBox(
        height: 100,
        width: 260,
        child: Center(
          child: AnimatedTextKit(
            animatedTexts: [
              ColorizeAnimatedText(
                'Box Sensors',
                textStyle: colorizeTextStyle,
                colors: colorizeColors,
                speed: const Duration(milliseconds: 700),
              ),
              ColorizeAnimatedText(
                'Developed by',
                textStyle: colorizeTextStyle,
                colors: colorizeColors,
                speed: const Duration(milliseconds: 500),
              ),
              ColorizeAnimatedText(
                '          Nick Dimitrakarakos',
                textStyle: colorizeTextStyle,
                colors: colorizeColors,
                speed: const Duration(milliseconds: 500),
              ),
            ],
            isRepeatingAnimation: true,
            onTap: () => debugPrint('About dialog tapped'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
