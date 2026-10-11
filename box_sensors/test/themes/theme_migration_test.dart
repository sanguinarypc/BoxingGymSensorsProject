import 'package:box_sensors/Themes/theme_provider.dart';
import 'package:box_sensors/Themes/theme_selection.dart';
import 'package:box_sensors/screens_widgets/match_list_item.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/services/riverpod_imports.dart';
import 'package:box_sensors/widgets/my_app.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart' as legacy;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ThemeProvider> pumpApp(WidgetTester tester, Widget home) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final provider = ThemeProvider();
  await provider.initTheme();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [themeProviderProvider.overrideWith((ref) => provider)],
      child: MyApp(overrideHome: home),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final mode in ThemeMode.values) {
    test(
      'loads existing ${mode.name} preference and saved color scheme',
      () async {
        SharedPreferences.setMockInitialValues({
          'themeMode': mode.name,
          'flexScheme': 'blue',
        });
        final provider = ThemeProvider();
        addTearDown(provider.dispose);
        await provider.initTheme();
        expect(provider.themeMode, mode);
        expect(provider.currentScheme, FlexScheme.blue);
      },
    );
  }

  test('unknown saved preferences retain the existing defaults', () async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 'unknown',
      'flexScheme': 'unknown',
    });
    final provider = ThemeProvider();
    addTearDown(provider.dispose);
    await provider.initTheme();
    expect(provider.themeMode, ThemeMode.system);
    expect(provider.currentScheme, FlexScheme.deepPurple);
  });

  testWidgets('theme controls preserve order, switching, and persistence', (
    tester,
  ) async {
    final provider = await pumpApp(
      tester,
      const Scaffold(body: ThemeSelection()),
    );
    final buttons = tester
        .widgetList<FlexThemeModeOptionButton>(
          find.byType(FlexThemeModeOptionButton),
        )
        .toList();
    expect(buttons.map((button) => button.label), ['SYSTEM', 'LIGHT', 'DARK']);
    expect(buttons.first.selected, isTrue);

    for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
      final option = find.byWidgetPredicate(
        (widget) =>
            widget is FlexThemeModeOptionButton &&
            widget.label == mode.name.toUpperCase(),
      );
      await tester.tap(
        find.descendant(of: option, matching: find.byType(InkWell)),
      );
      await tester.pumpAndSettle();
      expect(provider.themeMode, mode);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), mode.name);
      final selected = tester
          .widgetList<FlexThemeModeOptionButton>(
            find.byType(FlexThemeModeOptionButton),
          )
          .singleWhere((button) => button.selected);
      expect(selected.label, mode.name.toUpperCase());
    }

    final before = Theme.of(tester.element(find.byType(ThemeSelection)))
        .colorScheme
        .primary;
    await tester.tap(find.text('blue').first);
    await tester.pumpAndSettle();
    expect(provider.currentScheme, FlexScheme.blue);
    final after = Theme.of(tester.element(find.byType(ThemeSelection)))
        .colorScheme
        .primary;
    expect(after, isNot(before));

    final restored = ThemeProvider();
    addTearDown(restored.dispose);
    await restored.initTheme();
    expect(restored.themeMode, ThemeMode.system);
    expect(restored.currentScheme, FlexScheme.blue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system brightness, typography and legacy theme stay in sync', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    const probe = Key('theme-probe');
    final provider = await pumpApp(
      tester,
      const Scaffold(body: SizedBox(key: probe)),
    );

    for (final brightness in [Brightness.light, Brightness.dark]) {
      dispatcher.platformBrightnessTestValue = brightness;
      await tester.pumpAndSettle();
      final context = tester.element(find.byKey(probe));
      final theme = Theme.of(context);
      final legacyTheme = legacy.Theme.of(context);
      expect(theme.brightness, brightness);
      expect(legacyTheme.brightness, brightness);
      expect(legacyTheme.colorScheme.primary, theme.colorScheme.primary);
      expect(
        legacy.MaterialLocalizations.of(context).okButtonLabel,
        isNotEmpty,
      );
      expect(theme.textTheme.bodySmall?.fontSize, 12);
      expect(theme.textTheme.bodyMedium?.fontSize, 14);
      expect(theme.textTheme.bodyLarge?.fontSize, 16);
      expect(theme.textTheme.headlineMedium?.fontSize, 20);
      expect(theme.textTheme.headlineSmall?.fontSize, 18);
      expect(theme.textTheme.titleMedium?.fontWeight, FontWeight.w600);
      expect(theme.appBarTheme.backgroundColor, Colors.transparent);
      expect(theme.appBarTheme.elevation, 0);
      expect(
        theme.scaffoldBackgroundColor,
        brightness == Brightness.light ? Colors.grey[300] : Colors.grey[900],
      );
    }

    provider.setThemeMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byKey(probe))).brightness,
      Brightness.light,
    );
    provider.toggleThemeMode();
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byKey(probe))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing match swipe actions render in both themes', (
    tester,
  ) async {
    final provider = await pumpApp(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: MatchListItem(
            match: const {'id': 'migration-test', 'matchName': 'Test match'},
            dbHelper: DatabaseHelper(),
            onRefresh: () {},
          ),
        ),
      ),
    );
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      provider.setThemeMode(mode);
      await tester.pumpAndSettle();
      await tester.drag(find.text('Test match'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('Events').hitTestable(), findsOneWidget);
      expect(find.text('Edit').hitTestable(), findsOneWidget);
      expect(find.text('Delete').hitTestable(), findsOneWidget);
      final context = tester.element(find.byType(SlidableAction).first);
      expect(legacy.Theme.of(context).brightness, Theme.of(context).brightness);
      expect(tester.takeException(), isNull);
      final actionContext = tester.element(find.byType(SlidableAction).first);
      Slidable.of(actionContext)!.close();
      await tester.pumpAndSettle();
    }
  });
}
