import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class AppTheme {
  // Ana renkler
  static const Color primaryColor = Color(0xFF0070BA);
  static const Color accentColor = Color(0xFF48B2E8);
  static const Color secondaryColor = Color(0xFF26C6DA);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardShadowColor = Color(0xFFDDDDDD);
  static const Color textPrimaryColor = Color(0xFF222222);
  static const Color textSecondaryColor = Color(0xFF6F6F6F);
  
  // Gradient renkleri
  static List<Color> blueGradient = [
    primaryColor,
    accentColor,
  ];
  
  static List<Color> greenGradient = [
    const Color(0xFF4CAF50),
    const Color(0xFF8BC34A),
  ];
  
  static List<Color> purpleGradient = [
    const Color(0xFF9C27B0),
    const Color(0xFF7B1FA2),
  ];
  
  static List<Color> amberGradient = [
    const Color(0xFFFFB300),
    const Color(0xFFFFA000),
  ];
  
  // Light tema
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: primaryColor),
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shadowColor: cardShadowColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: textPrimaryColor,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textPrimaryColor,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: textSecondaryColor,
        fontSize: 12,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: accentColor,
    ),
  );

  // Metin renkleri
  static const Color textLightColor = Color(0xFFFAFAFA); // Beyaz

  // Durum renkleri
  static const Color successColor = Color(0xFF48BB78); // Yeşil
  static const Color errorColor = Color(0xFFE53E3E); // Kırmızı
  static const Color warningColor = Color(0xFFECC94B); // Sarı
  static const Color infoColor = Color(0xFF4299E1); // Mavi

  // Arka plan varyasyonları
  static const Color backgroundVariant1 = Color(0xFFEBF4FF); // Açık mavi
  static const Color backgroundVariant2 = Color(0xFFFFF9EB); // Açık amber

  // Kart renkleri
  static const Color cardColor = Color(0xFFFFFFFF); // Beyaz

  // Temaları oluştur
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      tertiary: accentColor,
      background: const Color(0xFF1A202C),
      error: errorColor,
      surface: const Color(0xFF2D3748),
    ),
    scaffoldBackgroundColor: const Color(0xFF1A202C),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D3748),
      foregroundColor: textLightColor,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        color: textLightColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.poppins(
        color: textLightColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: GoogleFonts.poppins(color: textLightColor, fontSize: 16),
    ),
  );
}

// Renk tonu koyulaştırma uzantısı
extension ColorExtension on Color {
  Color darker(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * value).round(),
      (green * value).round(),
      (blue * value).round(),
    );
  }

  Color lighter(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 + percent / 100;
    return Color.fromARGB(
      alpha,
      math.min(255, (red * value).round()),
      math.min(255, (green * value).round()),
      math.min(255, (blue * value).round()),
    );
  }
}
