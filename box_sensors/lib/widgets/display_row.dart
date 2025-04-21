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




// import 'package:flutter/material.dart';

// class DisplayRow extends StatelessWidget {
//   final String title;
//   final List<Widget> actions;
//   final double? fontSize; // Optional override for font size

//   const DisplayRow({
//     super.key,
//     required this.title,
//     this.actions = const [],
//     this.fontSize,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     // Use provided fontSize or fall back to theme default or 16
//     final double titleFontSize =
//         fontSize ?? theme.textTheme.titleMedium?.fontSize ?? 16;

//     final TextStyle titleStyle = theme.textTheme.titleMedium?.copyWith(
//           fontSize: titleFontSize,
//           fontWeight: FontWeight.bold,
//           color: theme.colorScheme.onSurface,
//         ) ??
//         TextStyle(
//           fontSize: titleFontSize,
//           fontWeight: FontWeight.bold,
//           color: Colors.black,
//         );

//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.inversePrimary,
//         border: Border(
//           bottom: BorderSide(
//             color: theme.colorScheme.outline,
//             width: 1,
//           ),
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Title in the center
//           Center(
//             child: Text(
//               title,
//               textAlign: TextAlign.center,
//               style: titleStyle,
//             ),
//           ),
//           // Actions aligned to the right
//           if (actions.isNotEmpty)
//             Positioned(
//               right: 0,
//               top: 0,
//               bottom: 0,
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: actions.map(
//                   (action) {
//                     return IconTheme(
//                       data: IconThemeData(
//                         size: 24,
//                         color: theme.colorScheme.onSurface,
//                       ),
//                       child: action,
//                     );
//                   },
//                 ).toList(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }










// import 'package:flutter/material.dart';

// class DisplayRow extends StatefulWidget {
//   final String title;
//   final List<Widget> actions;
//   final double? fontSize; // Optional parameter for font size

//   const DisplayRow({
//     super.key,
//     required this.title,
//     this.actions = const [],
//     this.fontSize, // Default is null; you can override it
//   });

//   @override
//   State<DisplayRow> createState() => _DisplayRowState();
// }

// class _DisplayRowState extends State<DisplayRow> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     // Use the provided fontSize or fall back to the theme's titleMedium fontSize if available, otherwise 10.
//     final double effectiveFontSize = widget.fontSize ??
//         (theme.textTheme.titleMedium?.fontSize ?? 16);
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.inversePrimary,
//         border: Border(
//           bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
//         ),
//       ),
//       padding: EdgeInsets.zero,
//       child: Stack(
//         children: [
//           Center(
//             child: Text(
//               widget.title,
//               textAlign: TextAlign.center,
//               style: theme.textTheme.titleMedium?.copyWith(
//                     fontSize: effectiveFontSize,
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.onSurface,
//                   ) ??
//                   TextStyle(
//                     fontSize: effectiveFontSize,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//             ),
//           ),
//           Positioned(
//             right: 0,
//             top: 0,
//             bottom: 0,
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: widget.actions.map((action) {
//                 return IconTheme(
//                   data: IconThemeData(
//                     size: 24,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                   child: action,
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }












// import 'package:flutter/material.dart';

// class DisplayRow extends StatefulWidget {
//   final String title;
//   final List<Widget> actions;

//   const DisplayRow({super.key, required this.title, this.actions = const []});

//   @override
//   State<DisplayRow> createState() => _DisplayRowState();
// }

// class _DisplayRowState extends State<DisplayRow> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: theme.colorScheme.inversePrimary,
//         border: Border(
//           bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
//         ),
//       ),
//       padding: EdgeInsets.zero,
//       child: Stack(
//         children: [
//           Center(
//             child: Text(
//               widget.title,
//               textAlign: TextAlign.center,
//               style:
//                   theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.onSurface,
//                   ) ??
//                   const TextStyle(
//                     fontSize: 10, // it was 16
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//             ),
//           ),
//           Positioned(
//             right: 0,
//             top: 0,
//             bottom: 0,
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children:
//                   widget.actions.map((action) {
//                     return IconTheme(
//                       data: IconThemeData(
//                         size: 24,
//                         color: theme.colorScheme.onSurface,
//                       ),
//                       child: action,
//                     );
//                   }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
