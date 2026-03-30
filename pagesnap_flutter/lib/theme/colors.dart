import 'package:flutter/material.dart';

class AppTheme {
  // Paper-white palette — warm off-white like aged book paper
  static const Color background       = Color(0xFFF7F2EA); // warm parchment
  static const Color surface          = Color(0xFFEEE8DC); // slightly deeper paper
  static const Color surfaceHighlight = Color(0xFFE4DDD0); // pressed / hover state
  static const Color primary          = Color(0xFF1D4ED8); // blue-700 (readable on light)
  static const Color accent           = Color(0xFFB45309); // amber-700 (readable on light)
  static const Color text             = Color(0xFF1C1917); // stone-900
  static const Color textDim          = Color(0xFF78716C); // stone-500
  static const Color border           = Color(0xFFCFC8BB); // warm gray divider

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surface,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text),
        bodyLarge: TextStyle(color: text),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: text,
        iconTheme: IconThemeData(color: text),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1C1917),
        contentTextStyle: TextStyle(color: Color(0xFFF7F2EA)),
      ),
    );
  }
}
