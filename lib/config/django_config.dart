class DjangoConfig {
  // URL de base du backend Django
  // ÉMULATEUR ANDROID: utilisez 10.0.2.2
  // APPAREIL PHYSIQUE: utilisez votre IP locale (ex: 192.168.1.57)
  // PRODUCTION: https://monuniversaya.com
  static const String baseUrl = 'https://monuniversaya.com';

  // URLs spécifiques
  static const String authUrl = '$baseUrl/api/auth';
  static const String qrUrl = '$baseUrl/api';

  // Endpoints d'authentification
  static const String loginEndpoint = '$authUrl/login/';
  static const String registerEndpoint = '$authUrl/register/';
  static const String profileEndpoint = '$authUrl/profile/';
  static const String refreshTokenEndpoint = '$authUrl/token/refresh/';
  static const String logoutEndpoint = '$authUrl/logout/';
  static const String deleteAccountEndpoint = '$authUrl/delete-account/';

  // Endpoints QR codes et jeux
  static const String qrValidateEndpoint = '$qrUrl/validate/';
  static const String userQRCodesEndpoint = '$qrUrl/user-codes/';
  static const String gamePlayEndpoint = '$qrUrl/games/play/';
  static const String gameHistoryEndpoint = '$qrUrl/games/history/';
  static const String availableGamesEndpoint = '$qrUrl/games/available/';

  // Endpoints échanges
  static const String exchangeCreateEndpoint = '$qrUrl/exchanges/create/';
  static const String exchangeListEndpoint = '$qrUrl/exchanges/list/';
  static const String exchangeValidateEndpoint = '$qrUrl/exchanges/validate/';
  static const String exchangeConfirmEndpoint = '$qrUrl/exchanges/confirm/';

  // Endpoints statistiques
  static const String userStatsEndpoint = '$qrUrl/stats/';

  // Configuration pour la production
  static const bool isDevelopment = false;

  // Timeout pour les requêtes HTTP (en secondes)
  static const int requestTimeout = 30;

  // Headers par défaut
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Messages d'erreur par défaut
  static const String networkErrorMessage =
      'Erreur de connexion. Vérifiez votre connexion internet.';
  static const String serverErrorMessage =
      'Erreur du serveur. Veuillez réessayer plus tard.';
  static const String unauthorizedErrorMessage =
      'Session expirée. Veuillez vous reconnecter.';
}
