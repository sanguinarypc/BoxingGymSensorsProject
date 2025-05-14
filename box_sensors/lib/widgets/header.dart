// lib/widgets/header.dart
import 'package:flutter/material.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final TextStyle? titleStyle;

  const Header({
    super.key,
    required this.title,
    this.actions,
    this.titleStyle,
  });

  // Default text style if none is provided.
  static const TextStyle defaultAppBarTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use provided titleStyle or fallback to default, and override the color.
    final dynamicTitleStyle = (titleStyle ?? defaultAppBarTitleStyle).copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return AppBar(
      centerTitle: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 4,
      shadowColor: theme.shadowColor,
      // Leading menu button uses a Builder to obtain a context that is below the AppBar.
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      automaticallyImplyLeading: false,
      actions: actions,
      // Title is a Row with an icon and text.
      title: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_mma,
            size: 40,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 2),
          Text(title, style: dynamicTitleStyle),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(40);
}
