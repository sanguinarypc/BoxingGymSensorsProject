// lib/widgets/adaptive_safe_bottom.dart
import 'package:flutter/material.dart';

/// Puts bottom-aligned content above the system nav bar (Android 3-button)
/// without changing the look on gesture mode or older Android.
/// IMPORTANT: Do NOT add system inset twice.
class AdaptiveSafeBottom extends StatelessWidget {
  const AdaptiveSafeBottom({
    super.key,
    required this.child,
    this.minBottom = 12.0,    // visual padding you want below content
    this.horizontal = 16.0,
    this.backgroundColor,
    this.elevation = 0.0,
  });

  final Widget child;
  final double minBottom;     // ONLY decorative padding we add
  final double horizontal;
  final Color? backgroundColor;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    // SafeArea will add the real system inset.
    // We only add the decorative minBottom (NOT the viewPadding again).
    return Material(
      color: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true, // adds system nav bar inset when 3-button is enabled
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, minBottom),
          child: child,
        ),
      ),
    );
  }
}



// import 'dart:math' as math;
// import 'package:flutter/material.dart';

// /// Ensures bottom-aligned content sits above the system navigation bar
// /// (Android 15+) while looking identical on older versions.
// class AdaptiveSafeBottom extends StatelessWidget {
//   const AdaptiveSafeBottom({
//     super.key,
//     required this.child,
//     this.minBottom = 12.0,          // keep your spacing
//     this.horizontal = 16.0,
//     this.backgroundColor,
//     this.elevation = 0.0,
//   });

//   final Widget child;
//   final double minBottom;
//   final double horizontal;
//   final Color? backgroundColor;
//   final double elevation;

//   @override
//   Widget build(BuildContext context) {
//     final mq = MediaQuery.of(context);
//     final bottomInset = math.max(mq.viewPadding.bottom, minBottom);

//     return Material(
//       color: backgroundColor ?? Colors.transparent,
//       elevation: elevation,
//       child: SafeArea(
//         top: false,
//         left: false,
//         right: false,
//         bottom: true,
//         child: Padding(
//           padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, bottomInset),
//           child: child,
//         ),
//       ),
//     );
//   }
// }
