import '../models/user.dart' as app_user;
import '../models/game_data.dart';
import '../models/qr_code_data.dart';
import 'data_service.dart';

// Exemple d'implémentation Firebase (pour démonstration)
class FirebaseDataSource implements DataSource {
  // Note: Cette implémentation nécessiterait firebase_core et cloud_firestore
  // import 'package:cloud_firestore/cloud_firestore.dart';

  @override
  Future<app_user.User?> getUserData(String userId) async {
    try {
      // Exemple avec Firestore
      // final doc = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(userId)
      //     .get();

      // if (doc.exists) {
      //   return app_user.User.fromJson(doc.data()!);
      // }

      // Pour l'exemple, on retourne null
      print('FirebaseDataSource: getUserData appelé pour $userId');
      return null;
    } catch (e) {
      print(
        'Erreur Firebase lors de la récupération des données utilisateur: $e',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateUserPoints(String userId, int points) async {
    try {
      // Exemple avec Firestore
      // await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(userId)
      //     .update({
      //   'available_points': points,
      //   'updated_at': FieldValue.serverTimestamp(),
      // });

      print(
        'FirebaseDataSource: updateUserPoints appelé pour $userId avec $points points',
      );
    } catch (e) {
      print('Erreur Firebase lors de la mise à jour des points: $e');
      rethrow;
    }
  }

  @override
  Future<void> addGameResult(String userId, GameData gameData) async {
    try {
      // Exemple avec Firestore
      // await FirebaseFirestore.instance
      //     .collection('user_games')
      //     .add({
      //   'user_id': userId,
      //   'game_type': gameData.gameType,
      //   'points_earned': gameData.pointsEarned,
      //   'score': gameData.score,
      //   'played_at': gameData.playedAt,
      //   'game_details': gameData.gameDetails,
      // });

      print('FirebaseDataSource: addGameResult appelé pour $userId');
    } catch (e) {
      print('Erreur Firebase lors de l\'ajout du résultat de jeu: $e');
      rethrow;
    }
  }

  @override
  Future<List<GameData>> getUserGames(String userId) async {
    try {
      // Exemple avec Firestore
      // final querySnapshot = await FirebaseFirestore.instance
      //     .collection('user_games')
      //     .where('user_id', isEqualTo: userId)
      //     .orderBy('played_at', descending: true)
      //     .get();

      // return querySnapshot.docs
      //     .map((doc) => GameData.fromJson(doc.data()))
      //     .toList();

      print('FirebaseDataSource: getUserGames appelé pour $userId');
      return [];
    } catch (e) {
      print('Erreur Firebase lors de la récupération des jeux: $e');
      rethrow;
    }
  }

  @override
  Future<void> addQRCodeScan(String userId, QRCodeData qrData) async {
    try {
      // Exemple avec Firestore
      // await FirebaseFirestore.instance
      //     .collection('user_qr_codes')
      //     .add({
      //   'user_id': userId,
      //   'qr_code_id': qrData.qrCodeId,
      //   'points_earned': qrData.pointsEarned,
      //   'scanned_at': qrData.scannedAt,
      //   'location': qrData.location,
      //   'scan_details': qrData.scanDetails,
      // });

      print('FirebaseDataSource: addQRCodeScan appelé pour $userId');
    } catch (e) {
      print('Erreur Firebase lors de l\'ajout du scan QR: $e');
      rethrow;
    }
  }

  @override
  Future<List<QRCodeData>> getUserQRScans(String userId) async {
    try {
      // Exemple avec Firestore
      // final querySnapshot = await FirebaseFirestore.instance
      //     .collection('user_qr_codes')
      //     .where('user_id', isEqualTo: userId)
      //     .orderBy('scanned_at', descending: true)
      //     .get();

      // return querySnapshot.docs
      //     .map((doc) => QRCodeData.fromJson(doc.data()))
      //     .toList();

      print('FirebaseDataSource: getUserQRScans appelé pour $userId');
      return [];
    } catch (e) {
      print('Erreur Firebase lors de la récupération des scans QR: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final user = await getUserData(userId);
      final games = await getUserGames(userId);
      final qrScans = await getUserQRScans(userId);

      return {
        'total_points': user?.availablePoints ?? 0,
        'total_games_played': games.length,
        'total_qr_scans': qrScans.length,
        'total_points_earned':
            games.fold(0, (sum, game) => sum + game.pointsEarned) +
            qrScans.fold(0, (sum, scan) => sum + scan.pointsEarned),
        'last_game_played': games.isNotEmpty ? games.first.playedAt : null,
        'last_qr_scan': qrScans.isNotEmpty ? qrScans.first.scannedAt : null,
      };
    } catch (e) {
      print('Erreur Firebase lors de la récupération des statistiques: $e');
      rethrow;
    }
  }
}

