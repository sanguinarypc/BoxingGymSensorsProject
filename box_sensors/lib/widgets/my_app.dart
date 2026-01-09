// lib/widgets/my_app.dart
import 'package:flutter/material.dart';
// ⚠️ services.dart ΔΕΝ χρειάζεται πια, το αφαιρούμε
import 'package:box_sensors/services/riverpod_imports.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/screens/connect_home_screen.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:box_sensors/utils/system_ui.dart'; // δίνει SystemUi (iOS-only)
import 'package:box_sensors/Themes/theme_flags.dart'; // kInversionSchemes

class MyApp extends ConsumerWidget {
  /// Προαιρετικό home override για tests (ώστε να μην ακουμπάμε plugins).
  final Widget? overrideHome;

  const MyApp({super.key, this.overrideHome});

  // ---- WCAG contrast helpers ----
  double _contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final bright = l1 > l2 ? l1 : l2;
    final dark = l1 > l2 ? l2 : l1;
    return (bright + 0.05) / (dark + 0.05);
  }

  // Επιλέγει αυτόματα λευκά/μαύρα για τα ΕΙΚΟΝΙΔΙΑ status/nav (το κρατάμε
  // μόνο για iOS, όπου χρησιμοποιούμε SafeSystemOverlay).
  Brightness _iconsForTheme(ThemeData theme, FlexScheme scheme) {
    final Color topBg =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    final whiteOn = _contrastRatio(Colors.white, topBg);
    final blackOn = _contrastRatio(Colors.black, topBg);
    var icons = (whiteOn >= blackOn) ? Brightness.light : Brightness.dark;

    if (kInversionSchemes.contains(scheme)) {
      icons = (icons == Brightness.light) ? Brightness.dark : Brightness.light;
    }
    return icons;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderProvider);
    final scheme = themeProvider.currentScheme;

    // ----------------- LIGHT THEME -----------------
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
      textTheme: Typography.blackMountainView.copyWith(
        bodyMedium: Typography.blackMountainView.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: Typography.blackMountainView.bodySmall?.copyWith(fontSize: 12),
        bodyLarge: Typography.blackMountainView.bodyLarge?.copyWith(fontSize: 16),
        headlineMedium: Typography.blackMountainView.headlineMedium?.copyWith(
            fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: Typography.blackMountainView.headlineSmall?.copyWith(
            fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: Typography.blackMountainView.titleMedium?.copyWith(
            fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

    // ----------------- DARK THEME ------------------
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
      textTheme: Typography.whiteMountainView.copyWith(
        bodyMedium: Typography.whiteMountainView.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: Typography.whiteMountainView.bodySmall?.copyWith(fontSize: 12),
        bodyLarge: Typography.whiteMountainView.bodyLarge?.copyWith(fontSize: 16),
        headlineMedium: Typography.whiteMountainView.headlineMedium?.copyWith(
            fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: Typography.whiteMountainView.headlineSmall?.copyWith(
            fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: Typography.whiteMountainView.titleMedium?.copyWith(
            fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

    // ❌ Μην περνάς systemOverlayStyle στο AppBar (να ΜΗΝ δημιουργείται AnnotatedRegion)
    final lightTheme = baseLight.copyWith(
      appBarTheme: baseLight.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        
      ),
    );
    final darkTheme = baseDark.copyWith(
      appBarTheme: baseDark.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Box Sensors',
      themeMode: themeProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,

      // Text-scaling + edge-to-edge
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final isPhone = mq.size.shortestSide < 600;

        final clamped = mq.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.2,
        );
        final scaler = isPhone ? TextScaler.noScaling : clamped;

        // ✅ Στο ANDROID δεν κάνουμε τίποτα (το κάνει το MainActivity με enableEdgeToEdge).
        // ✅ Στο iOS μπορούμε να κρατήσουμε το helper για την φωτεινότητα εικονιδίων.
        // μόνο για iOS, όπου χρησιμοποιούμε SystemUi).
        final platform = Theme.of(context).platform;
        if (platform == TargetPlatform.iOS) {
          final iconBrightness = _iconsForTheme(Theme.of(context), scheme);
          // iOS μόνο – στο Android το κάνει το Jetpack στο MainActivity
          SystemUi.configure(
            statusIcons: iconBrightness,
            navIcons: iconBrightness,
          );
        }

        return MediaQuery(
          data: mq.copyWith(textScaler: scaler),
          child: child ?? const SizedBox.shrink(),
        );
      },

      home: overrideHome ?? const ConnectHomeScreen(),
    );
  }
}