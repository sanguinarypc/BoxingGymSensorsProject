// lib/widgets/display_row.dart
import 'package:flutter/material.dart';

class DisplayRow extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final double? fontSize; // Optional override for font size

  const DisplayRow({
    super.key,
    required this.title,
    this.actions = const [],
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use provided fontSize or fall back to theme default or 16
    final double titleFontSize =
        fontSize ?? theme.textTheme.titleMedium?.fontSize ?? 16;

    final TextStyle titleStyle = theme.textTheme.titleMedium?.copyWith(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        );

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.inversePrimary,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Title in the center
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: titleStyle,
            ),
          ),
          // Actions aligned to the right
          if (actions.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions.map(
                  (action) {
                    return IconTheme(
                      data: IconThemeData(
                        size: 24,
                        color: theme.colorScheme.onSurface,
                      ),
                      child: action,
                    );
                  },
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
