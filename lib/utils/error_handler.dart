/// Gestionnaire d'erreurs sécurisé pour l'application Aya+
///
/// Ce fichier contient des utilitaires pour gérer les erreurs de manière sécurisée
/// sans exposer d'informations sensibles sur le backend.

class ErrorHandler {
  /// Gère les erreurs de connexion de manière sécurisée
  static String handleConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Détecter les erreurs de connexion réseau
    if (errorString.contains('socketexception') ||
        errorString.contains('clientexception') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection failed') ||
        errorString.contains('connection refused') ||
        errorString.contains('timeout') ||
        errorString.contains('no internet') ||
        errorString.contains('network unreachable')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }

    // Détecter les erreurs de timeout
    if (errorString.contains('timeout')) {
      return 'Le serveur met trop de temps à répondre. Veuillez réessayer.';
    }

    // Détecter les erreurs de certificat SSL
    if (errorString.contains('certificate') ||
        errorString.contains('ssl') ||
        errorString.contains('handshake')) {
      return 'Erreur de sécurité de connexion. Veuillez réessayer.';
    }

    // Détecter les erreurs de format de données
    if (errorString.contains('format') ||
        errorString.contains('json') ||
        errorString.contains('parse')) {
      return 'Erreur de traitement des données. Veuillez réessayer.';
    }

    // Pour toutes les autres erreurs, retourner un message générique
    return 'Erreur de connexion. Vérifiez votre connexion internet et réessayez.';
  }

  /// Gère les erreurs d'authentification de manière sécurisée
  static String handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Détecter les erreurs de connexion réseau
    if (errorString.contains('socketexception') ||
        errorString.contains('clientexception') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection failed')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }

    // Détecter les erreurs d'authentification spécifiques
    if (errorString.contains('invalid credentials') ||
        errorString.contains('invalid email') ||
        errorString.contains('invalid password')) {
      return 'Email ou mot de passe incorrect.';
    }

    if (errorString.contains('user not found') ||
        errorString.contains('user does not exist')) {
      return 'Aucun compte trouvé avec cet email.';
    }

    if (errorString.contains('account disabled') ||
        errorString.contains('account locked')) {
      return 'Votre compte est temporairement désactivé. Contactez le support.';
    }

    if (errorString.contains('email not verified') ||
        errorString.contains('email not confirmed')) {
      return 'Veuillez vérifier votre email avant de vous connecter.';
    }

    // Pour les autres erreurs d'authentification
    return 'Erreur de connexion. Vérifiez vos identifiants et réessayez.';
  }

  /// Gère les erreurs de validation de manière sécurisée
  static String handleValidationError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Détecter les erreurs de connexion réseau
    if (errorString.contains('socketexception') ||
        errorString.contains('clientexception') ||
        errorString.contains('network is unreachable')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }

    // Détecter les erreurs de validation spécifiques
    if (errorString.contains('email already exists') ||
        errorString.contains('email already registered')) {
      return 'Un compte existe déjà avec cet email.';
    }

    if (errorString.contains('password too short') ||
        errorString.contains('password too weak')) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }

    if (errorString.contains('invalid email format') ||
        errorString.contains('email format')) {
      return 'Format d\'email invalide.';
    }

    if (errorString.contains('name required') ||
        errorString.contains('first name required') ||
        errorString.contains('last name required')) {
      return 'Veuillez remplir tous les champs obligatoires.';
    }

    // Pour les autres erreurs de validation
    return 'Veuillez vérifier les informations saisies et réessayer.';
  }

  /// Gère les erreurs de grand prix de manière sécurisée
  static String handleGrandPrixError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Détecter les erreurs de connexion réseau
    if (errorString.contains('socketexception') ||
        errorString.contains('clientexception') ||
        errorString.contains('network is unreachable')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }

    // Détecter les erreurs spécifiques aux grands prix
    if (errorString.contains('no active grand prix') ||
        errorString.contains('no grand prix available')) {
      return 'Aucun grand prix actif actuellement.';
    }

    if (errorString.contains('insufficient points') ||
        errorString.contains('not enough points')) {
      return 'Points insuffisants pour participer.';
    }

    if (errorString.contains('already participated') ||
        errorString.contains('already joined')) {
      return 'Vous avez déjà participé à ce grand prix.';
    }

    if (errorString.contains('grand prix ended') ||
        errorString.contains('grand prix finished')) {
      return 'Ce grand prix est terminé.';
    }

    if (errorString.contains('vip status required') ||
        errorString.contains('vip membership required')) {
      return 'Statut VIP requis pour participer.';
    }

    // Pour les autres erreurs de grand prix
    return 'Erreur lors de la participation. Veuillez réessayer.';
  }
}
