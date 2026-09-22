import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    cardColor: const Color(0xFFFFFFFF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFEB164F),
      surface: Color(0xFFFFFFFF),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardColor: const Color(0xFF1E293B),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFEB164F),
      surface: Color(0xFF1E293B),
    ),
  );
}
