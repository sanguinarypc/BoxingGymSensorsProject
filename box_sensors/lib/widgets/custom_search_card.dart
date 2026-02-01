// lib/widgets/custom_search_card.dart
import 'package:flutter/material.dart';

/// A Card wrapping your custom-search TextField.
class CustomSearchCard extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const CustomSearchCard({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: theme.cardColor,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 32,
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                isDense: true,
                isCollapsed: true,
                filled: true,
                fillColor: theme.cardColor,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                hintText: 'Custom search',
                hintStyle: TextStyle(
                  color: theme.colorScheme.primary
                      .withAlpha((0.6 * 255).toInt()),
                  fontSize: 12,
                ),
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
