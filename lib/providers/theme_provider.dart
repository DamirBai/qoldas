import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadInitialTheme();
  }

  // 🌤 Светлая тема — мягкий голубой фон и пастельные акценты
  // Внутри ThemeProvider
ThemeData get lightTheme => ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF4F9FF), // ещё светлее и мягче
  primaryColor: const Color(0xFFE4D7F5),
  cardColor: Colors.white,
  iconTheme: const IconThemeData(color: Color(0xFF495057)),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF343A40)),
    bodyMedium: TextStyle(color: Color(0xFF6C757D)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFF4F9FF),
    selectedItemColor: Color(0xFFB298DC),
    unselectedItemColor: Color(0xFF6C757D),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE4D7F5),
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF4F9FF),
    iconTheme: IconThemeData(color: Color(0xFF343A40)),
    titleTextStyle: TextStyle(color: Color(0xFF343A40), fontSize: 20),
    elevation: 0,
  ),
);

ThemeData get darkTheme => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF171C26),
  primaryColor: const Color(0xFFBFA6E0),
  cardColor: const Color(0xFF222633),
  iconTheme: const IconThemeData(color: Colors.white),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Color(0xFFCCCCCC)),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF171C26),
    selectedItemColor: Color(0xFFBFA6E0),
    unselectedItemColor: Color(0xFF888888),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.08),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF171C26),
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    elevation: 0,
  ),
);


  // --------------------------- ЛОГИКА ---------------------------

  void setInitialMode(ThemeMode mode) {
    _themeMode = mode;
    _setSystemUIOverlayStyle(mode);
    notifyListeners();
  }

  Future<void> _loadInitialTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_default') ?? 'system';
    _themeMode = _stringToThemeMode(mode);
    _setSystemUIOverlayStyle(_themeMode);
    notifyListeners();
  }

  Future<void> loadTheme(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_$userId') ?? 'system';
    _themeMode = _stringToThemeMode(mode);
    _setSystemUIOverlayStyle(_themeMode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode, String userId) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_$userId', _themeMode.name);
    await prefs.setString('theme_default', _themeMode.name);
    _setSystemUIOverlayStyle(mode);
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

  void _setSystemUIOverlayStyle(ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }
}
