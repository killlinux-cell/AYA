import 'package:flutter/material.dart';

class AppFonts {
  // Helvetica pour les headers
  static const String helvetica = 'Helvetica';

  // Helvetica Now pour le body
  static const String helveticaNow = 'Helvetica Now';

  // Styles prédéfinis
  static const TextStyle headerStyle = TextStyle(
    fontFamily: helvetica,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyStyle = TextStyle(fontFamily: helveticaNow);

  // Styles spécifiques pour différents éléments
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: helvetica,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: helvetica,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: helveticaNow,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: helveticaNow,
    fontSize: 14,
  );

  static const TextStyle captionText = TextStyle(
    fontFamily: helveticaNow,
    fontSize: 12,
  );
}
