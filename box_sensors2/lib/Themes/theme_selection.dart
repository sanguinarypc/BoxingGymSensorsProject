// theme_selection.dart
import 'package:flutter/material.dart';
import 'package:box_sensors2/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class ThemeSelection extends ConsumerWidget {
  const ThemeSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderProvider);
    final theme = Theme.of(context);
    return Column(
      children: [
        // FlexThemeModeSwitch with centered title above icons.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row #1: Title text.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0),
              // Row #2: The FlexThemeModeSwitch.
              FlexThemeModeSwitch(
                hasTitle: false,
                labelAbove: true,
                showSystemMode: true,
                buttonOrder: FlexThemeModeButtonOrder.systemLightDark,
                themeMode: themeProvider.themeMode,
                onThemeModeChanged: (mode) {
                  themeProvider.setThemeMode(mode);
                },
                flexSchemeData: (FlexColor.schemes[themeProvider.currentScheme] ??
                    FlexColor.schemes[FlexScheme.deepPurple])!,
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row with icon, label, and selected scheme name.
              Row(
                children: [
                  Icon(Icons.color_lens, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Theme:',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    themeProvider.currentScheme.toString().split('.').last,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0),
              // A GridView showing all FlexScheme values.
              SizedBox(
                height: 140,
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  children: FlexScheme.values.map((scheme) {
                    final schemeData = FlexColor.schemes[scheme] ??
                        FlexColor.schemes[FlexScheme.deepPurple]!;
                    return GestureDetector(
                      onTap: () => themeProvider.setScheme(scheme),
                      child: Container(
                        alignment: Alignment.center,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ColorBox(color: schemeData.light.primary),
                                const SizedBox(width: 4),
                                _ColorBox(color: schemeData.light.secondary),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ColorBox(color: schemeData.dark.primary),
                                const SizedBox(width: 4),
                                _ColorBox(color: schemeData.dark.secondary),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                scheme.toString().split('.').last,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorBox extends StatelessWidget {
  final Color color;
  const _ColorBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
