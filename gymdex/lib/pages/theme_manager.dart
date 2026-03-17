import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  // Singleton para acceder desde cualquier lugar
  static final ThemeManager instance = ThemeManager._init();
  ThemeManager._init();

  static const String _themeKey = 'theme_mode';
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Lee la preferencia, si no existe, por defecto es 'false' (light mode)
    final isDark = prefs.getBool(_themeKey) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    // Guarda la preferencia
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}
