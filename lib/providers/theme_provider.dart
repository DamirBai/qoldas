import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadInitialTheme();
  }

  void setInitialMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> _loadInitialTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_default') ?? 'system';
    _themeMode = _stringToThemeMode(mode);
    notifyListeners();
  }

  Future<void> loadTheme(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_$userId') ?? 'system';
    _themeMode = _stringToThemeMode(mode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode, String userId) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_$userId', _themeMode.name);
    await prefs.setString('theme_default', _themeMode.name);
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark, String userId) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(mode, userId);
  }

  ThemeMode _stringToThemeMode(String? mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
