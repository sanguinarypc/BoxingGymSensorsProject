import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Κλειδώνει ΜΟΝΟ τα κινητά σε πορτραίτο (shortestSide < 600dp).
/// Σε tablets/foldables/desktop αφήνει όλα τα orientations.
/// Δεν πειράζει καμία άλλη ροή της εφαρμογής σου.
class OrientationGate extends StatefulWidget {
  final Widget child;
  const OrientationGate({super.key, required this.child});

  @override
  State<OrientationGate> createState() => _OrientationGateState();
}

class _OrientationGateState extends State<OrientationGate> with WidgetsBindingObserver {
  bool? _lastIsPhone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Εφάρμοσε πολιτική αμέσως μετά το πρώτο frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Καλείται όταν αλλάζει μέγεθος/προσανατολισμός (fold/unfold, multi-window).
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _apply();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _apply() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    final isPhone = logicalSize.shortestSide < 600;

    if (_lastIsPhone == isPhone) return;
    _lastIsPhone = isPhone;

    if (isPhone) {
      // Κινητά => μόνο πορτραίτο.
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
    } else {
      // Μεγάλες οθόνες => ελεύθερος προσανατολισμός.
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }
}
