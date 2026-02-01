// lib/widgets/about_dialog_animation.dart
import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

/// A reusable dialog widget that shows an animated "About" screen for the Box Sensors app.
class AboutDialogAnimation extends StatelessWidget {
  const AboutDialogAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Gradient colors for background
    final gradientStart = colorScheme.surface;
    final gradientEnd = colorScheme.surfaceContainerHighest;
    final accentColor = colorScheme.primary;

    const colorizeColors = [
      Colors.purple,
      Colors.blue,
      Colors.yellow,
      Colors.red,
    ];
    const colorizeTextStyle = TextStyle(
      fontSize: 32.0,
      fontFamily: 'Horizon',
      fontWeight: FontWeight.bold,
    );

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            // Premium Gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientStart.withValues(alpha: 0.90),
                gradientEnd.withValues(alpha: 0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
              // Subtle glow
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.sports_mma, color: accentColor, size: 60),
              ),
              const SizedBox(height: 32),

              // Animated Text Area
              SizedBox(
                height: 120, // Enough height for text
                width: 280,
                child: DefaultTextStyle(
                  style: const TextStyle(fontSize: 30.0, fontFamily: 'Horizon'),
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
                          textStyle: colorizeTextStyle.copyWith(fontSize: 24),
                          colors: colorizeColors,
                          speed: const Duration(milliseconds: 500),
                        ),
                        ColorizeAnimatedText(
                          'Nick Dimitrakarakos',
                          textStyle: colorizeTextStyle.copyWith(fontSize: 26),
                          colors: colorizeColors,
                          speed: const Duration(milliseconds: 500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      isRepeatingAnimation: true,
                      onTap: () {},
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Close Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
