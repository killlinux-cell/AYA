import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../models/game_data.dart';
import '../models/qr_code_data.dart';
import 'data_service.dart';

class SupabaseDataSource implements DataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<app_user.User?> getUserData(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return app_user.User.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserPoints(String userId, int points) async {
    try {
      await _supabase
          .from('users')
          .update({
            'available_points': points,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      print('Erreur lors de la mise à jour des points: $e');
      rethrow;
    }
  }

  @override
  Future<void> addGameResult(String userId, GameData gameData) async {
    try {
      await _supabase.from('user_games').insert({
        'user_id': userId,
        'game_type': gameData.gameType,
        'points_earned': gameData.pointsEarned,
        'score': gameData.score,
        'played_at': gameData.playedAt.toIso8601String(),
        'game_details': gameData.gameDetails,
      });

      // Mettre à jour les points de l'utilisateur
      final currentUser = await getUserData(userId);
      if (currentUser != null) {
        final newPoints = currentUser.availablePoints + gameData.pointsEarned;
        await updateUserPoints(userId, newPoints);
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du résultat de jeu: $e');
      rethrow;
    }
  }

  @override
  Future<List<GameData>> getUserGames(String userId) async {
    try {
      final response = await _supabase
          .from('user_games')
          .select()
          .eq('user_id', userId)
          .order('played_at', ascending: false);

      return (response as List).map((game) => GameData.fromJson(game)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des jeux: $e');
      rethrow;
    }
  }

  @override
  Future<void> addQRCodeScan(String userId, QRCodeData qrData) async {
    try {
      await _supabase.from('user_qr_codes').insert({
        'user_id': userId,
        'qr_code_id': qrData.qrCodeId,
        'points_earned': qrData.pointsEarned,
        'scanned_at': qrData.scannedAt.toIso8601String(),
        'location': qrData.location,
        'scan_details': qrData.scanDetails,
      });

      // Mettre à jour les points de l'utilisateur
      final currentUser = await getUserData(userId);
      if (currentUser != null) {
        final newPoints = currentUser.availablePoints + qrData.pointsEarned;
        await updateUserPoints(userId, newPoints);
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du scan QR: $e');
      rethrow;
    }
  }

  @override
  Future<List<QRCodeData>> getUserQRScans(String userId) async {
    try {
      final response = await _supabase
          .from('user_qr_codes')
          .select()
          .eq('user_id', userId)
          .order('scanned_at', ascending: false);

      return (response as List)
          .map((scan) => QRCodeData.fromJson(scan))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des scans QR: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final user = await getUserData(userId);
      final games = await getUserGames(userId);
      final qrScans = await getUserQRScans(userId);

      if (user == null) {
        throw Exception('Utilisateur non trouvé');
      }

      return {
        'total_points': user.availablePoints,
        'total_games_played': games.length,
        'total_qr_scans': qrScans.length,
        'total_points_earned':
            games.fold(0, (sum, game) => sum + game.pointsEarned) +
            qrScans.fold(0, (sum, scan) => sum + scan.pointsEarned),
        'last_game_played': games.isNotEmpty ? games.first.playedAt : null,
        'last_qr_scan': qrScans.isNotEmpty ? qrScans.first.scannedAt : null,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      rethrow;
    }
  }
}

