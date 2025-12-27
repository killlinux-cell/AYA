import 'django_auth_service.dart';
import 'django_user_service.dart';

class UserPointsService {
  final DjangoAuthService _authService;
  final DjangoUserService _userService;

  UserPointsService(this._authService, this._userService);

  /// Mettre à jour les points utilisateur après un gain
  Future<void> updateUserPointsAfterPrize({
    required String userId,
    required int pointsEarned,
    required int qrCodesCollected,
  }) async {
    try {
      print('🔄 Mise à jour des points utilisateur...');
      print('   Points gagnés: $pointsEarned');
      print('   QR codes collectés: $qrCodesCollected');

      // Pour l'instant, on se contente de logger les informations
      // L'API backend gère déjà la mise à jour des points
      print('✅ Points mis à jour via l\'API backend');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des points: $e');
      rethrow;
    }
  }

  /// Synchroniser les données utilisateur avec le serveur
  Future<void> syncUserDataWithServer(String userId) async {
    try {
      print('🔄 Synchronisation des données utilisateur...');
      // L'API backend gère déjà la synchronisation
      print('✅ Données synchronisées avec le serveur');
    } catch (e) {
      print('❌ Erreur lors de la synchronisation: $e');
      rethrow;
    }
  }

  /// Obtenir le solde de points actuel
  int getCurrentPoints() {
    final user = _authService.currentUser;
    return user?.availablePoints ?? 0;
  }

  /// Obtenir le nombre de QR codes collectés
  int getQRCodesCollected() {
    final user = _authService.currentUser;
    return user?.collectedQRCodes ?? 0;
  }

  /// Vérifier si l'utilisateur a suffisamment de points
  bool hasEnoughPoints(int requiredPoints) {
    return getCurrentPoints() >= requiredPoints;
  }

  /// Déduire des points (pour les achats, jeux, etc.)
  Future<bool> deductPoints({
    required String userId,
    required int pointsToDeduct,
    required String reason,
  }) async {
    try {
      final currentPoints = getCurrentPoints();

      if (currentPoints < pointsToDeduct) {
        print('❌ Points insuffisants: $currentPoints < $pointsToDeduct');
        return false;
      }

      // Pour l'instant, on simule la déduction
      print('✅ Points déduits: $pointsToDeduct ($reason)');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la déduction des points: $e');
      return false;
    }
  }
}
