import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceHighlight = Color(0xFF334155);
  static const Color primary = Color(0xFF3B82F6);
  static const Color accent = Color(0xFFF59E0B);
  static const Color text = Color(0xFFF8FAFC);
  static const Color textDim = Color(0x99F8FAFC); // 60% opacity
  static const Color border = Color(0x1AF8FAFC);  // 10% opacity

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        background: background,
        surface: surface,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text),
        bodyLarge: TextStyle(color: text),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
      ),
    );
  }
}
