import 'package:flutter/material.dart';

/// Couleurs de la marque Aya+
class AppColors {
  // Couleurs privées pour éviter l'instanciation
  AppColors._();

  /// Vert primaire de la marque Aya+
  static const Color primaryGreen = Color(0xFF488950);
  static const Color primaryGreenLight = Color(0xFF60A066);
  static const Color primaryGreenDark = Color(0xFF3A6F41);

  /// Couleurs d'accent
  static const Color accentRed = Color(0xFFa93236);
  static const Color accentRedLight = Color(0xFFC54A4E);
  static const Color accentRedDark = Color(0xFF8B282B);

  static const Color accentYellow = Color(0xFFf2ce11);
  static const Color accentYellowLight = Color(0xFFF4D63A);
  static const Color accentYellowDark = Color(0xFFD4B50E);

  /// Couleurs de base
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Couleurs système
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);

  /// Couleurs pour les états
  static const Color success = primaryGreen;
  static const Color warning = accentYellow;
  static const Color error = accentRed;
  static const Color info = Color(0xFF17A2B8);

  /// Couleurs pour les cartes et conteneurs
  static const Color cardBackground = white;
  static const Color divider = Color(0xFFE9ECEF);

  /// Couleurs pour les boutons
  static const Color buttonPrimary = primaryGreen;
  static const Color buttonPrimaryHover = primaryGreenLight;
  static const Color buttonSecondary = Color(0xFF6C757D);
  static const Color buttonSuccess = primaryGreen;
  static const Color buttonWarning = accentYellow;
  static const Color buttonDanger = accentRed;

  /// Couleurs pour les icônes
  static const Color iconPrimary = textPrimary;
  static const Color iconSecondary = textSecondary;
  static const Color iconSuccess = primaryGreen;
  static const Color iconWarning = accentYellow;
  static const Color iconDanger = accentRed;

  /// Couleurs pour les bordures
  static const Color borderPrimary = Color(0xFFDEE2E6);
  static const Color borderFocus = primaryGreen;
  static const Color borderError = accentRed;

  /// Couleurs pour les ombres
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
}
