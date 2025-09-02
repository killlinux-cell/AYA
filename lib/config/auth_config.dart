class AuthConfig {
  // Configuration de la session
  static const int sessionTimeoutMinutes = 60 * 24 * 7; // 7 jours
  static const bool autoRefreshToken = true;
  static const bool persistSession = true;

  // Configuration des redirections avec votre domaine
  static const String emailConfirmationRedirectUrl =
      'http://orapide.shop/auth/callback';
  static const String passwordResetRedirectUrl =
      'http://orapide.shop/auth/reset';
  static const String passwordResetAlternativeUrl =
      'http://orapide.shop/auth/reset';

  // Messages d'erreur
  static const String emailNotConfirmedMessage =
      'Veuillez confirmer votre email avant de vous connecter.';
  static const String invalidCredentialsMessage =
      'Email ou mot de passe incorrect.';
  static const String networkErrorMessage =
      'Erreur de connexion. Vérifiez votre connexion internet.';

  // Configuration des tentatives de connexion
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
}
