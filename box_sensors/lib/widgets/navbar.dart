// lib/widgets/navbar.dart
import 'package:box_sensors/widgets/exit_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:box_sensors/widgets/about_dialog_animation.dart';
import 'package:box_sensors/widgets/about_dialog_app.dart';
import 'package:box_sensors/Themes/theme_selection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:flutter/services.dart'; // For Clipboard
// import 'package:flutter/services.dart';

/// A simple widget that merges two icons into one.
class MergedIcon extends StatelessWidget {
  const MergedIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.sports_kabaddi,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          Positioned(
            top: 0,
            left: -10,
            child: Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

/// A navigation drawer widget that displays a menu with multiple options.
class NavBar extends StatelessWidget {
  final Function(int) onTabTapped;

  const NavBar({super.key, required this.onTabTapped});

  // A helper method to safely perform an action.
  void _safeAction(BuildContext context, VoidCallback action) {
    try {
      action();
    } catch (e) {
      debugPrint("Error performing navigation action: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      width: 260,
      backgroundColor: theme.brightness == Brightness.dark
          ? theme.colorScheme.surface
          : theme.colorScheme.inversePrimary,
      child: Column(
        children: [
          Container(
            height: 66,
            width: double.infinity,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Row(
              children: [
                Icon(
                  Icons.sports_mma,
                  color: theme.colorScheme.onPrimary,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Text(
                  'Box Sensors',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const ThemeSelection(),
          const Divider(),

          // ↓ wrap all the ListTiles below inside an Expanded→ListView
          Expanded(
            child: ListTileTheme(
              dense: true,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.bluetooth,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Connect',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        onTabTapped(0);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.sports_kabaddi,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Games',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        onTabTapped(1);
                      });
                    },
                  ),
                  ListTile(
                    leading: const MergedIcon(),
                    title: Text(
                      'Add Game',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        onTabTapped(2);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Settings',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        onTabTapped(3);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: theme.colorScheme.primary),
                    title: Text(
                      'About',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        AboutDialogApp.show(context);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.animation,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Animation',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        showAboutDialogAnimation(context);
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.monitor_heart_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Web Dashboard',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        Navigator.pop(context);
                        _showWebDashboardDialog(context);
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.exit_to_app,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Exit',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      _safeAction(context, () {
                        ExitConfirmation.show(context);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience method to show the [AboutDialogAnimation].
void showAboutDialogAnimation(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AboutDialogAnimation(),
  );
}

/// Dialog to show Web Dashboard info with Premium Design
void _showWebDashboardDialog(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  // Use theme colors for gradient
  final gradientStart = theme.colorScheme.surface;
  final gradientEnd = theme.colorScheme.surfaceContainerHighest;
  final accentColor = theme.colorScheme.primary;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur effect
      child: Dialog(
        backgroundColor: Colors.transparent, // Handle bg in Container
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            // Subtle gradient background based on theme
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientStart.withOpacity(0.95), // Slightly transparent
                gradientEnd.withOpacity(0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
              // Glow effect using primary color
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monitor_heart_outlined,
                  size: 48,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Title & Subtitle
              Text(
                'Web Dashboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'View live matches and analysis on your web browser by visiting:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 3. Link "Pill" Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        'https://boxing-dashboard.ndimitrakarakos.gr/',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Copy Button
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                          const ClipboardData(
                            text:
                                'https://boxing-dashboard.ndimitrakarakos.gr/',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Link copied to clipboard!'),
                            backgroundColor: accentColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(12),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme
                                .colorScheme
                                .tertiary, // Use tertiary for nice gradient
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final Uri url = Uri.parse(
                              'https://boxing-dashboard.ndimitrakarakos.gr/',
                            );
                            try {
                              if (!await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              )) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not launch browser'),
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) Navigator.pop(context);
                              }
                            } catch (e) {
                              // error
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.open_in_browser,
                                  color: theme.colorScheme.onPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Open in Browser',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
