import 'package:flutter/material.dart';

class Footer extends StatefulWidget {
  final ValueChanged<int> onTabTapped;
  final int currentIndex;

  const Footer({
    super.key,
    required this.onTabTapped,
    required this.currentIndex,
  });

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        // Set the default label text style for the navigation bar.
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            // When selected, use a larger font size and bold weight.
            return theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
          }
          // Unselected state.
          return theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
        }),
      ),
      child: NavigationBar(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: widget.onTabTapped,
        // Adjust the animation duration as needed.
        animationDuration: const Duration(milliseconds: 2500),
        height: 60,
        backgroundColor: theme.colorScheme.inversePrimary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.bluetooth),
            label: 'Connect',
          ),
          const NavigationDestination(
            icon: Icon(Icons.sports_kabaddi),
            label: 'Games',
          ),
          NavigationDestination(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Base icon.
                  Icon(Icons.sports_kabaddi, size: 24),
                  // Additional icon positioned relative to the base icon.
                  Positioned(
                    top: 0,
                    left: -10,
                    child: Icon(Icons.add, size: 18),
                  ),
                ],
              ),
            ),
            label: 'Add Game',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
