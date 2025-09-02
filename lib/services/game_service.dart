import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_history.dart';
import '../config/supabase_config.dart';

class GameService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Vérifier si l'utilisateur peut jouer aujourd'hui
  Future<bool> canPlayToday(String userId, String gameType) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('daily_game_limits')
          .select('last_played_date')
          .eq('user_id', userId)
          .eq('game_type', gameType)
          .maybeSingle();

      if (response == null) {
        // L'utilisateur n'a jamais joué à ce jeu
        return true;
      }

      final lastPlayedDate = response['last_played_date'];
      return lastPlayedDate != today;
    } catch (e) {
      print('Error checking if user can play today: $e');
      return false;
    }
  }

  /// Enregistrer une partie jouée
  Future<void> recordGamePlay(
    String userId,
    String gameType,
    int pointsSpent,
    int pointsWon,
  ) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final isWinning = pointsWon > 0;

      // Enregistrer l'historique de la partie
      await _supabase.from('game_history').insert({
        'user_id': userId,
        'game_type': gameType,
        'points_spent': pointsSpent,
        'points_won': pointsWon,
        'played_at': DateTime.now().toIso8601String(),
        'is_winning': isWinning,
      });

      // Mettre à jour la limitation quotidienne
      await _supabase.from('daily_game_limits').upsert({
        'user_id': userId,
        'game_type': gameType,
        'last_played_date': today,
      });

      print(
        'Game play recorded successfully for user: $userId, game: $gameType',
      );
    } catch (e) {
      print('Error recording game play: $e');
      rethrow;
    }
  }

  /// Obtenir l'historique des parties d'un utilisateur
  Future<List<GameHistory>> getGameHistory(String userId) async {
    try {
      final response = await _supabase
          .from('game_history')
          .select()
          .eq('user_id', userId)
          .order('played_at', ascending: false)
          .limit(50);

      return response.map((json) => GameHistory.fromJson(json)).toList();
    } catch (e) {
      print('Error getting game history: $e');
      return [];
    }
  }

  /// Obtenir les statistiques de jeux d'un utilisateur
  Future<Map<String, dynamic>> getGameStats(String userId) async {
    try {
      final response = await _supabase
          .from('game_history')
          .select()
          .eq('user_id', userId);

      final games = response.map((json) => GameHistory.fromJson(json)).toList();

      int totalGames = games.length;
      int totalPointsSpent = games.fold(
        0,
        (sum, game) => sum + game.pointsSpent,
      );
      int totalPointsWon = games.fold(0, (sum, game) => sum + game.pointsWon);
      int winningGames = games.where((game) => game.isWinning).length;

      double winRate = totalGames > 0 ? (winningGames / totalGames) * 100 : 0;
      int netPoints = totalPointsWon - totalPointsSpent;

      return {
        'totalGames': totalGames,
        'totalPointsSpent': totalPointsSpent,
        'totalPointsWon': totalPointsWon,
        'winningGames': winningGames,
        'winRate': winRate,
        'netPoints': netPoints,
      };
    } catch (e) {
      print('Error getting game stats: $e');
      return {
        'totalGames': 0,
        'totalPointsSpent': 0,
        'totalPointsWon': 0,
        'winningGames': 0,
        'winRate': 0,
        'netPoints': 0,
      };
    }
  }

  /// Vérifier si l'utilisateur a assez de points pour jouer
  Future<bool> hasEnoughPoints(String userId, int requiredPoints) async {
    try {
      final response = await _supabase
          .from('users')
          .select('available_points')
          .eq('id', userId)
          .single();

      final availablePoints = response['available_points'] ?? 0;
      return availablePoints >= requiredPoints;
    } catch (e) {
      print('Error checking if user has enough points: $e');
      return false;
    }
  }

  /// Déduire les points du jeu et ajouter les gains
  Future<void> processGamePoints(
    String userId,
    int pointsSpent,
    int pointsWon,
  ) async {
    try {
      final netPoints = pointsWon - pointsSpent;

      // Récupérer les points actuels
      final currentResponse = await _supabase
          .from('users')
          .select('available_points')
          .eq('id', userId)
          .single();

      final currentPoints = currentResponse['available_points'] ?? 0;
      final newPoints = currentPoints + netPoints;

      await _supabase
          .from('users')
          .update({'available_points': newPoints})
          .eq('id', userId);

      print(
        'Game points processed successfully for user: $userId, net points: $netPoints',
      );
    } catch (e) {
      print('Error processing game points: $e');
      rethrow;
    }
  }

  /// Jouer à un jeu complet (vérification + déduction + enregistrement)
  Future<Map<String, dynamic>> playGame(
    String userId,
    String gameType,
    int pointsCost,
  ) async {
    try {
      // Vérifier si l'utilisateur peut jouer aujourd'hui
      final canPlay = await canPlayToday(userId, gameType);
      if (!canPlay) {
        return {
          'success': false,
          'message':
              'Vous avez déjà joué à ce jeu aujourd\'hui. Revenez demain !',
        };
      }

      // Vérifier si l'utilisateur a assez de points
      final hasPoints = await hasEnoughPoints(userId, pointsCost);
      if (!hasPoints) {
        return {
          'success': false,
          'message':
              'Vous n\'avez pas assez de points pour jouer (${pointsCost} points requis)',
        };
      }

      // Générer le gain selon le type de jeu
      int pointsWon = _generateGameReward(gameType);

      // Traiter les points
      await processGamePoints(userId, pointsCost, pointsWon);

      // Enregistrer la partie
      await recordGamePlay(userId, gameType, pointsCost, pointsWon);

      return {
        'success': true,
        'pointsWon': pointsWon,
        'message': 'Félicitations ! Vous avez gagné $pointsWon points !',
      };
    } catch (e) {
      print('Error playing game: $e');
      return {'success': false, 'message': 'Erreur lors du jeu: $e'};
    }
  }

  /// Générer une récompense selon le type de jeu
  int _generateGameReward(String gameType) {
    final random = DateTime.now().millisecondsSinceEpoch;

    switch (gameType.toLowerCase()) {
      case 'scratch_win':
        // Scratch & Win : 5-50 points
        return 5 + (random % 46);

      case 'spin_wheel':
        // Roue de la chance : 0-50 points avec probabilités
        final chance = random % 100;
        if (chance < 10) return 50; // 10% chance de 50 points
        if (chance < 25) return 25; // 15% chance de 25 points
        if (chance < 45) return 15; // 20% chance de 15 points
        if (chance < 70) return 10; // 25% chance de 10 points
        if (chance < 90) return 5; // 20% chance de 5 points
        return 0; // 10% chance de 0 points

      default:
        // Jeu par défaut : 5-25 points
        return 5 + (random % 21);
    }
  }

  /// Obtenir les jeux disponibles
  List<Map<String, dynamic>> getAvailableGames() {
    return [
      {
        'type': 'scratch_win',
        'name': 'Scratch & Win',
        'description': 'Grattez pour gagner des points',
        'cost': 10,
        'icon': 'brush',
        'color': 0xFFFF9800,
      },
      {
        'type': 'spin_wheel',
        'name': 'Roue de la Chance',
        'description': 'Tournez la roue pour gagner',
        'cost': 10,
        'icon': 'rotate_right',
        'color': 0xFF9C27B0,
      },
    ];
  }
}
