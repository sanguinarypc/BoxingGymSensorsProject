// test/system_icons_overlay_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

SystemUiOverlayStyle _overlayFromIcons(Brightness icons) => SystemUiOverlayStyle(
  statusBarIconBrightness: icons,
  systemNavigationBarIconBrightness: icons,
  statusBarBrightness: icons == Brightness.light ? Brightness.dark : Brightness.light,
);

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final bright = l1 > l2 ? l1 : l2;
  final dark = l1 > l2 ? l2 : l1;
  return (bright + 0.05) / (dark + 0.05);
}

Brightness _iconsForTopBackground(Color topBg, {bool invert = false}) {
  final whiteOn = _contrastRatio(Colors.white, topBg);
  final blackOn = _contrastRatio(Colors.black, topBg);
  var icons = (whiteOn >= blackOn) ? Brightness.light : Brightness.dark;
  if (invert) icons = (icons == Brightness.light) ? Brightness.dark : Brightness.light;
  return icons;
}

class _OverlayProbe extends StatelessWidget {
  final Color topBackground;
  final bool invert;

  const _OverlayProbe({
    required this.topBackground,
    required this.invert,
  });

  @override
  Widget build(BuildContext context) {
    final icons = _iconsForTopBackground(topBackground, invert: invert);

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      appBarTheme: AppBarTheme(
        backgroundColor: topBackground,
        systemOverlayStyle: _overlayFromIcons(icons),
      ),
    );

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Probe')),
      ),
    );
  }
}

void main() {
  testWidgets('Ανοιχτό top background -> ΜΑΥΡΑ system icons',
      (WidgetTester tester) async {
    const top = Color(0xFFF5F5F5);
    await tester.pumpWidget(const _OverlayProbe(topBackground: top, invert: false));

    final ctx = tester.element(find.byType(AppBar));
    final appBarTheme = Theme.of(ctx).appBarTheme;
    final style = appBarTheme.systemOverlayStyle;

    expect(style, isNotNull);
    expect(style!.statusBarIconBrightness, Brightness.dark);
  });

  testWidgets('Σκούρο top background -> ΛΕΥΚΑ system icons',
      (WidgetTester tester) async {
    const top = Color(0xFF121212);
    await tester.pumpWidget(const _OverlayProbe(topBackground: top, invert: false));

    final ctx = tester.element(find.byType(AppBar));
    final appBarTheme = Theme.of(ctx).appBarTheme;
    final style = appBarTheme.systemOverlayStyle;

    expect(style, isNotNull);
    expect(style!.statusBarIconBrightness, Brightness.light);
  });

  testWidgets('Invert flag αναστρέφει την επιλογή', (WidgetTester tester) async {
    const top = Color(0xFFF5F5F5);
    await tester.pumpWidget(const _OverlayProbe(topBackground: top, invert: true));

    final ctx = tester.element(find.byType(AppBar));
    final appBarTheme = Theme.of(ctx).appBarTheme;
    final style = appBarTheme.systemOverlayStyle;

    expect(style, isNotNull);
    expect(style!.statusBarIconBrightness, Brightness.light);
  });
}
