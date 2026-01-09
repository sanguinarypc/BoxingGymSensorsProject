import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Φτιάχνει ένα ελάχιστο app με FlexThemeData και AppBar,
/// ΧΩΡΙΣ να ορίζει systemOverlayStyle που προκαλεί τα deprecated paths.
Widget buildAppWithScheme({
  required FlexScheme scheme,
  required ThemeMode mode,
  Color? appBarBg,
}) {
  // Light theme όπως στο app σου (χωρίς systemOverlayStyle).
  final baseLight = FlexThemeData.light(
    useMaterial3: true,
    scheme: scheme,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
      navigationRailLabelType: NavigationRailLabelType.all,
      elevatedButtonRadius: 16,
      elevatedButtonElevation: 4,
    ),
  ).copyWith(
    scaffoldBackgroundColor: Colors.grey[300],
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, // μόνο bg/elevation
      elevation: 0,
      // ❌ ΔΕΝ ορίζουμε systemOverlayStyle εδώ
    ),
  );

  // Dark theme όπως στο app σου (χωρίς systemOverlayStyle).
  final baseDark = FlexThemeData.dark(
    useMaterial3: true,
    scheme: scheme,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
      navigationRailLabelType: NavigationRailLabelType.all,
      elevatedButtonRadius: 16,
      elevatedButtonElevation: 4,
    ),
  ).copyWith(
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[850],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // ❌ ΔΕΝ ορίζουμε systemOverlayStyle εδώ
    ),
  );

  return MaterialApp(
    theme: baseLight,
    darkTheme: baseDark,
    themeMode: mode,
    home: Scaffold(
      appBar: AppBar(
        // μπορείς προαιρετικά να δώσεις διαφορετικό φόντο για δοκιμές
        backgroundColor: appBarBg,
        title: const Text('Probe'),
      ),
      body: const SizedBox.shrink(),
    ),
  );
}

void main() {
  testWidgets('Δεν ορίζεται AppBarTheme.systemOverlayStyle (Light)',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildAppWithScheme(
      scheme: FlexScheme.shadZinc, // “δύσκολο” scheme
      mode: ThemeMode.light,
    ));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(AppBar));
    final appBarTheme = Theme.of(ctx).appBarTheme;

    // ✅ Θέλουμε null για να μην προκαλείται το Flutter PlatformPlugin path
    expect(appBarTheme.systemOverlayStyle, isNull);
  });

  testWidgets('Δεν ορίζεται AppBarTheme.systemOverlayStyle (Dark)',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildAppWithScheme(
      scheme: FlexScheme.deepPurple,
      mode: ThemeMode.dark,
    ));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(AppBar));
    final appBarTheme = Theme.of(ctx).appBarTheme;
    expect(appBarTheme.systemOverlayStyle, isNull);
  });

  testWidgets('Smoke test για μερικά schemes (Light/Dark)',
      (WidgetTester tester) async {
    final schemes = <FlexScheme>[
      FlexScheme.deepPurple,
      FlexScheme.shadZinc,
      FlexScheme.materialBaseline,
    ];

    for (final s in schemes) {
      await tester.pumpWidget(buildAppWithScheme(
        scheme: s,
        mode: ThemeMode.light,
      ));
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);

      await tester.pumpWidget(buildAppWithScheme(
        scheme: s,
        mode: ThemeMode.dark,
      ));
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    }
  });
}
