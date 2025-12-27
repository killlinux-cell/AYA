import 'package:flutter/material.dart';
import 'fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.helveticaNow,

      // Configuration des couleurs
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF488950),
        brightness: Brightness.light,
      ),

      // Configuration de l'AppBar
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.helvetica,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: Color(0xFF488950),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Configuration des cartes
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Configuration des boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: AppFonts.helveticaNow,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Configuration des textes
      textTheme: const TextTheme(
        // Headers
        headlineLarge: TextStyle(
          fontFamily: AppFonts.helvetica,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppFonts.helvetica,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.helvetica,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),

        // Titres
        titleLarge: TextStyle(
          fontFamily: AppFonts.helvetica,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.helvetica,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        titleSmall: TextStyle(
          fontFamily: AppFonts.helvetica,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),

        // Corps de texte
        bodyLarge: TextStyle(fontFamily: AppFonts.helveticaNow, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: AppFonts.helveticaNow, fontSize: 14),
        bodySmall: TextStyle(fontFamily: AppFonts.helveticaNow, fontSize: 12),

        // Labels
        labelLarge: TextStyle(
          fontFamily: AppFonts.helveticaNow,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFonts.helveticaNow,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: TextStyle(
          fontFamily: AppFonts.helveticaNow,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
