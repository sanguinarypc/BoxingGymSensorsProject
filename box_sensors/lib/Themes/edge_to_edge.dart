import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Τυλίγει παιδί και επιβάλλει ΜΟΝΟ τη φωτεινότητα εικονιδίων
/// στις μπάρες συστήματος (status + navigation).
class EdgeToEdge extends StatelessWidget {
  final Brightness iconBrightness;
  final Widget child;

  const EdgeToEdge({
    super.key,
    required this.iconBrightness,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final style = SystemUiOverlayStyle(
      statusBarIconBrightness: iconBrightness,
      systemNavigationBarIconBrightness: iconBrightness,
      // iOS hint: αντίθετο από τα εικονίδια
      statusBarBrightness:
          iconBrightness == Brightness.light ? Brightness.dark : Brightness.light,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style,
      child: child,
    );
  }
}
