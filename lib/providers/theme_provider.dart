import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  final Color _customPrimaryColor = const Color(0xFF222B6F);
  bool _isDark = false;
  bool get isDark => _isDark;

  MaterialColor _createMaterialColor(Color color) {
    final swatch = <int, Color>{
      50: color.withOpacity(0.1),
      100: color.withOpacity(0.2),
      200: color.withOpacity(0.3),
      300: color.withOpacity(0.4),
      400: color.withOpacity(0.5),
      500: color.withOpacity(0.6),
      600: color.withOpacity(0.7),
      700: color.withOpacity(0.8),
      800: color.withOpacity(0.9),
      900: color,
    };

    return MaterialColor(color.value, swatch);
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: _createMaterialColor(_customPrimaryColor),
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      backgroundColor: _customPrimaryColor,
      foregroundColor: Colors.white,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: _createMaterialColor(_customPrimaryColor),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
  );

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
