import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_user;
import '../models/qr_code.dart';
import 'dart:math';

class LocalUserService {
  static const String _userDataKey = 'user_data';
  static const String _qrCodesKey = 'user_qr_codes';

  // Obtenir les données utilisateur complètes
  Future<app_user.User?> getUserData(String userId) async {
    try {
      // Pour la démo, retourner un utilisateur fictif
      return app_user.User(
        id: userId,
        email: 'demo@example.com',
        name: 'Utilisateur Démo',
        availablePoints: 100,
        exchangedPoints: 50,
        collectedQRCodes: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now(),
        personalQRCode: 'DEMO_QR_123456',
      );
    } catch (e) {
      print('LocalUserService: Error getting user data: $e');
      return null;
    }
  }

  // Générer un QR code personnel unique pour l'utilisateur
  Future<String> generatePersonalQRCode(String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(9999);
      final personalCode =
          'USER_${userId.substring(0, 8)}_${timestamp}_$random';

      print('LocalUserService: Personal QR code generated: $personalCode');
      return personalCode;
    } catch (e) {
      print('LocalUserService: Error generating personal QR code: $e');
      rethrow;
    }
  }

  // Obtenir le QR code personnel de l'utilisateur
  Future<String?> getPersonalQRCode(String userId) async {
    try {
      // Pour la démo, retourner un QR code fictif
      return 'DEMO_QR_123456';
    } catch (e) {
      print('LocalUserService: Error getting personal QR code: $e');
      return null;
    }
  }

  // Vérifier l'identité d'un utilisateur via son QR code personnel
  Future<app_user.User?> verifyUserByQRCode(String personalQRCode) async {
    try {
      // Pour la démo, retourner un utilisateur fictif
      if (personalQRCode.startsWith('DEMO_QR_')) {
        return app_user.User(
          id: 'demo_user_123',
          email: 'demo@example.com',
          name: 'Utilisateur Démo',
          availablePoints: 100,
          exchangedPoints: 50,
          collectedQRCodes: 5,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastLoginAt: DateTime.now(),
          personalQRCode: personalQRCode,
        );
      }
      return null;
    } catch (e) {
      print('LocalUserService: Error verifying user by QR code: $e');
      return null;
    }
  }

  // Mettre à jour les points de l'utilisateur
  Future<void> updateUserPoints(
    String userId,
    int availablePoints,
    int exchangedPoints,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = {
        'available_points': availablePoints,
        'exchanged_points': exchangedPoints,
      };
      await prefs.setString(_userDataKey, userData.toString());
      print('LocalUserService: User points updated');
    } catch (e) {
      print('LocalUserService: Error updating user points: $e');
      rethrow;
    }
  }

  // Ajouter un code QR collecté
  Future<void> addQRCode(String userId, QRCode qrCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingQRCodes = prefs.getStringList(_qrCodesKey) ?? [];
      existingQRCodes.add(qrCode.id);
      await prefs.setStringList(_qrCodesKey, existingQRCodes);

      // Mettre à jour les statistiques de l'utilisateur
      final userData = await getUserData(userId);
      if (userData != null) {
        await updateUserPoints(
          userId,
          userData.availablePoints + qrCode.points,
          userData.exchangedPoints,
        );
      }

      print('LocalUserService: QR code added successfully');
    } catch (e) {
      print('LocalUserService: Error adding QR code: $e');
      rethrow;
    }
  }

  // Obtenir tous les codes QR collectés par l'utilisateur
  Future<List<QRCode>> getUserQRCodes(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qrCodeIds = prefs.getStringList(_qrCodesKey) ?? [];

      // Créer des QR codes fictifs pour la démo
      return qrCodeIds
          .map(
            (id) => QRCode(
              id: id,
              code: 'DEMO_QR_$id',
              points: Random().nextInt(50) + 10,
              collectedAt: DateTime.now().subtract(
                Duration(days: Random().nextInt(30)),
              ),
              description: 'Code QR de démonstration',
            ),
          )
          .toList();
    } catch (e) {
      print('LocalUserService: Error getting user QR codes: $e');
      return [];
    }
  }

  // Vérifier si un code QR a déjà été collecté
  Future<bool> hasQRCode(String userId, String qrCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingQRCodes = prefs.getStringList(_qrCodesKey) ?? [];
      return existingQRCodes.contains(qrCode);
    } catch (e) {
      print('LocalUserService: Error checking QR code: $e');
      return false;
    }
  }
}
