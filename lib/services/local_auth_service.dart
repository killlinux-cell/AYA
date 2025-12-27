import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_user;

class LocalAuthService {
  static const String _userKey = 'current_user';
  static const String _isAuthenticatedKey = 'is_authenticated';

  // Obtenir l'utilisateur actuel
  app_user.User? get currentUser {
    // Pour la démo, retourner un utilisateur fictif
    return app_user.User(
      id: 'demo_user_123',
      email: 'demo@example.com',
      name: 'Utilisateur Démo',
      availablePoints: 100,
      exchangedPoints: 50,
      collectedQRCodes: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
      personalQRCode: 'DEMO_QR_123456',
    );
  }

  // Vérifier si l'utilisateur est connecté
  bool get isAuthenticated {
    return true; // Pour la démo, toujours connecté
  }

  // Connexion
  Future<bool> signIn({required String email, required String password}) async {
    // Simulation d'une connexion réussie
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // Inscription
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // Simulation d'une inscription réussie
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // Déconnexion
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isAuthenticatedKey, false);
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    // Simulation d'un envoi d'email
    await Future.delayed(const Duration(seconds: 1));
  }

  // Mettre à jour le mot de passe
  Future<bool> updatePassword(String newPassword) async {
    // Simulation d'une mise à jour réussie
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // Écouter les changements d'authentification (stream vide pour la démo)
  Stream<Map<String, dynamic>> get authStateChanges {
    return Stream.empty();
  }

  // Vérifier si l'email est confirmé
  bool get isEmailConfirmed => true;

  // Rafraîchir la session
  Future<void> refreshSession() async {
    // Pas d'action nécessaire pour la démo
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
  }) async {
    // Simulation d'une mise à jour réussie
    await Future.delayed(const Duration(seconds: 1));
  }

  // Mettre à jour l'email de l'utilisateur
  Future<void> updateUserEmail(String newEmail) async {
    // Simulation d'une mise à jour réussie
    await Future.delayed(const Duration(seconds: 1));
  }

  // Mettre à jour le mot de passe de l'utilisateur
  Future<void> updateUserPassword(String newPassword) async {
    // Simulation d'une mise à jour réussie
    await Future.delayed(const Duration(seconds: 1));
  }

  // Réinitialisation du mot de passe (méthode interne)
  Future<bool> resetPasswordInternal(String email) async {
    // Simulation d'un envoi d'email
    await Future.delayed(const Duration(seconds: 1));
    print('Password reset email simulated for: $email');
    return true;
  }

  // Mettre à jour le mot de passe avec un code de réinitialisation
  Future<bool> updatePasswordWithCode(String code, String newPassword) async {
    // Simulation d'une mise à jour réussie
    await Future.delayed(const Duration(seconds: 1));
    print('Password updated with code $code locally to: $newPassword');
    return true;
  }

  // Vérifier si un code de réinitialisation est valide
  Future<bool> isResetCodeValid(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return code == 'valid_reset_code'; // Pour la démo
  }
}
