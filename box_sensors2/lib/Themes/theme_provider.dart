import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  FlexScheme _currentScheme = FlexScheme.deepPurple; // default scheme

  // Getter to expose the current scheme
  FlexScheme get currentScheme => _currentScheme;

  // Setter to change the scheme and notify listeners
  void setScheme(FlexScheme newScheme) {
    _currentScheme = newScheme;
    notifyListeners();
    // 2) Save the new scheme in SharedPreferences
    saveScheme(newScheme);
  }

  void toggleThemeMode() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    // Also save after toggling
    saveThemeMode(themeMode);
  }

  // Minimal method for FlexThemeModeSwitch
  void setThemeMode(ThemeMode newMode) {
    themeMode = newMode;
    notifyListeners();
    // 3) Save the new theme mode
    saveThemeMode(newMode);
  }

  /// 4) Call this once early in `main()` to load user’s saved theme
  Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved scheme (e.g. "deepPurple", "blue", etc.)
    final savedSchemeString = prefs.getString('flexScheme') ?? 'deepPurple';
    // Convert that string to a FlexScheme (fallback to deepPurple if not found)
    final possibleScheme = FlexScheme.values.firstWhere(
      (scheme) => scheme.toString().split('.').last == savedSchemeString,
      orElse: () => FlexScheme.deepPurple,
    );
    _currentScheme = possibleScheme;

    // Load saved theme mode (e.g. "system", "light", "dark")
    final savedThemeMode = prefs.getString('themeMode') ?? 'system';
    switch (savedThemeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  /// Save the user’s chosen scheme as a string
  Future<void> saveScheme(FlexScheme scheme) async {
    final prefs = await SharedPreferences.getInstance();
    final schemeString = scheme.toString().split('.').last;
    await prefs.setString('flexScheme', schemeString);
  }

  /// Save the user’s chosen theme mode
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString = 'system';
    if (mode == ThemeMode.light) modeString = 'light';
    if (mode == ThemeMode.dark) modeString = 'dark';
    await prefs.setString('themeMode', modeString);
  }
}
