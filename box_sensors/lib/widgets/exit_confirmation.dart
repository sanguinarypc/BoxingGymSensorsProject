// lib/widgets/exit_confirmation.dart
import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _ExitAction { exit, minimizeKeepAlive, minimizeCloseBT, cancel }

class ExitConfirmation {
  static const MethodChannel _channel = MethodChannel('app.exit.channel');

  static Future<void> show(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Gradient colors
    final gradientStart = colorScheme.surface;
    final gradientEnd = colorScheme.surfaceContainerHighest;
    final accentColor = colorScheme.primary;

    final choice = await showDialog<_ExitAction>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                // Premium Gradient Background
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientStart.withValues(alpha: 0.95),
                    gradientEnd.withValues(alpha: 0.98),
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
                    color: accentColor.withValues(alpha: 0.1),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Glowing Icon Header
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
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        size: 40,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Title & Subtitle
                    Text(
                      'Exit Application',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how you want to leave the app.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 3. Option Cards
                    Column(
                      children: [
                        _buildOptionCard(
                          ctx,
                          icon: Icons.minimize_rounded,
                          title: 'Minimize App',
                          subtitle: 'Keep Bluetooth connected',
                          color: colorScheme.primary,
                          action: _ExitAction.minimizeKeepAlive,
                          isPrimary: true,
                        ),
                        const SizedBox(height: 12),
                        _buildOptionCard(
                          ctx,
                          icon: Icons.bluetooth_disabled_rounded,
                          title: 'Minimize & Disconnect',
                          subtitle: 'Close Bluetooth connection',
                          color: colorScheme.secondary,
                          action: _ExitAction.minimizeCloseBT,
                        ),
                        const SizedBox(height: 12),
                        _buildOptionCard(
                          ctx,
                          icon: Icons.exit_to_app_rounded,
                          title: 'Close Application',
                          subtitle: 'Fully terminate the app',
                          color: colorScheme.error,
                          action: _ExitAction.exit,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 4. Cancel Button
                    TextButton(
                      onPressed: () =>
                          Navigator.of(ctx).pop(_ExitAction.cancel),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    switch (choice) {
      case _ExitAction.minimizeKeepAlive:
        await _channel.invokeMethod('minimizeApp');
        break;
      case _ExitAction.minimizeCloseBT:
        await _channel.invokeMethod('minimizeAppNoBT');
        break;
      case _ExitAction.exit:
        await _channel.invokeMethod('exitApp');
        break;
      case _ExitAction.cancel:
      default:
        break;
    }
  }

  static Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required _ExitAction action,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(action),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? color.withValues(alpha: 0.5)
                  : (isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05)),
              width: isPrimary ? 1.5 : 1,
            ),
            color: isPrimary
                ? color.withValues(alpha: 0.05)
                : (isDark
                      ? Colors.black.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
