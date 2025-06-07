import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'ta':
        return 'தமிழ்';
      case 'hi':
        return 'हिन्दी';
      case 'te':
        return 'తెలుగు';
      case 'ml':
        return 'മലയാളം';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'en':
      default:
        return 'English';
    }
  }

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('ta'), // Tamil
    Locale('te'), // Telugu
    Locale('ml'), // Malayalam
    Locale('kn'), // Kannada
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'ml': 'മലയാളം',
    'kn': 'ಕನ್ನಡ',
  };

  // Language display order for UI
  static const List<String> languageOrder = [
    'en', // English
    'hi', // Hindi
    'ta', // Tamil
    'te', // Telugu
    'ml', // Malayalam
    'kn', // Kannada
  ];

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('language_code') ?? 'en';
      _currentLocale = Locale(savedLanguageCode);
      notifyListeners();
    } catch (e) {
      // Default to English if there's an error
      _currentLocale = const Locale('en');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      notifyListeners();

      // Save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', languageCode);
      } catch (e) {
        debugPrint('Error saving language preference: $e');
      }
    }
  }

  bool isCurrentLanguage(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }
}
