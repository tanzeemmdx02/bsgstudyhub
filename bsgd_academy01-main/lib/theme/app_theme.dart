import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryNavy = Color(0xFF0A192F);
  static const Color navySurface = Color(0xFF112240);
  static const Color royalBlue = Color(0xFF1E40AF);
  static const Color royalBlueHover = Color(0xFF1D4ED8);
  static const Color academicGold = Color(0xFFD4AF37);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFEF4444);
  static const Color accentAmber = Color(0xFFF59E0B);

  // Light Palette
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Dark Palette
  static const Color bgDark = Color(0xFF070F1E);
  static const Color surfaceDark = Color(0xFF0D1B33);
  static const Color borderDark = Color(0xFF1E2E4A);
  static const Color textLight = Color(0xFFF1F5F9);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    colorScheme: const ColorScheme.light(
      primary: royalBlue,
      secondary: academicGold,
      surface: surfaceLight,
      error: accentRose,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceLight,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryNavy),
      titleTextStyle: TextStyle(
        color: primaryNavy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderLight),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: royalBlueHover,
      secondary: academicGold,
      surface: surfaceDark,
      error: accentRose,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderDark),
      ),
    ),
  );
}