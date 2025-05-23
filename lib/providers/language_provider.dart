import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'ru';

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadInitial();
  }

  void setInitialLanguage(String lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('lang_default') ?? 'ru';
    notifyListeners();
  }

  Future<void> loadLanguage(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('lang_$userId') ?? 'ru';
    notifyListeners();
  }

  Future<void> setLanguage(String lang, String userId) async {
    _currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_$userId', lang);
    await prefs.setString('lang_default', lang);
    notifyListeners();
  }
}
