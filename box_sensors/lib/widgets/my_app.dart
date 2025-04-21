// lib/widgets/my_app.dart
// ignore_for_file: deprecated_member_use, textScaleFactor
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/connect_home.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderProvider);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    final navBarColor = isDark ? Colors.black : Colors.white;

    final isInversionScheme = [
      FlexScheme.blackWhite,
      FlexScheme.sepia,
      FlexScheme.greys,
      FlexScheme.shadGray,
      FlexScheme.shadNeutral,
      FlexScheme.shadSlate,
      FlexScheme.shadStone,
      FlexScheme.shadZinc,
    ].contains(themeProvider.currentScheme);

    final overlayStyle = isInversionScheme
        ? (isDark
            ? SystemUiOverlayStyle(
                statusBarColor: Colors.white,
                statusBarIconBrightness: Brightness.dark,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle(
                statusBarColor: Colors.black,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarColor: Colors.black,
                systemNavigationBarIconBrightness: Brightness.light,
              ))
        : SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: iconBrightness,
            systemNavigationBarColor: navBarColor,
            systemNavigationBarIconBrightness: iconBrightness,
          );

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Box Sensors',
      themeMode: themeProvider.themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: child!,
      ),
      theme: FlexThemeData.light(
        useMaterial3: true,
        scheme: themeProvider.currentScheme,
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
          bodyMedium:
              Typography.blackMountainView.bodyMedium?.copyWith(fontSize: 14),
          bodySmall:
              Typography.blackMountainView.bodySmall?.copyWith(fontSize: 12),
          bodyLarge:
              Typography.blackMountainView.bodyLarge?.copyWith(fontSize: 16),
          headlineMedium: Typography.blackMountainView.headlineMedium
              ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
          headlineSmall: Typography.blackMountainView.headlineSmall
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          titleMedium: Typography.blackMountainView.titleMedium
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: overlayStyle,
        ),
      ),
      darkTheme: FlexThemeData.dark(
        useMaterial3: true,
        scheme: themeProvider.currentScheme,
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
          bodyMedium:
              Typography.whiteMountainView.bodyMedium?.copyWith(fontSize: 14),
          bodySmall:
              Typography.whiteMountainView.bodySmall?.copyWith(fontSize: 12),
          bodyLarge:
              Typography.whiteMountainView.bodyLarge?.copyWith(fontSize: 16),
          headlineMedium: Typography.whiteMountainView.headlineMedium
              ?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
          headlineSmall: Typography.whiteMountainView.headlineSmall
              ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          titleMedium: Typography.whiteMountainView.titleMedium
              ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: overlayStyle,
        ),
      ),
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: const ConnectHome(), // No parameter needed now.
      ),
    );
  }
}

