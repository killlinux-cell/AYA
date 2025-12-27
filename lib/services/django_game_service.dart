import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_history.dart';
import '../config/django_config.dart';
import 'django_auth_service.dart';

class DjangoGameService {
  static const String baseUrl = DjangoConfig.qrUrl;
  final DjangoAuthService _authService;

  DjangoGameService(this._authService);

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  Future<bool> canPlayToday(String userId, String gameType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games/available/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        // Django gère les limites quotidiennes côté serveur
        return true; // La vérification se fait lors du jeu
      }
    } catch (e) {
      print('Erreur lors de la vérification des jeux disponibles: $e');
    }
    return false;
  }

  Future<void> recordGamePlay(
    String userId,
    String gameType,
    int pointsSpent,
    int pointsWon,
  ) async {
    // Django gère automatiquement l'enregistrement lors du jeu
    print(
      'DjangoGameService: Enregistrement du jeu géré automatiquement par Django',
    );
  }

  Future<List<GameHistory>> getGameHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games/history/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> gamesData = data['results'] ?? data;

        return gamesData
            .map(
              (gameData) => GameHistory(
                id: gameData['id'] ?? '',
                userId: gameData['user'] ?? userId,
                gameType: gameData['game_type'] ?? '',
                pointsSpent: gameData['points_spent'] ?? 0,
                pointsWon: gameData['points_won'] ?? 0,
                playedAt: gameData['played_at'] != null
                    ? DateTime.parse(gameData['played_at'])
                    : DateTime.now(),
                isWinning: gameData['is_winning'] ?? false,
              ),
            )
            .toList();
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique des jeux: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> getGameStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'totalGames': data['total_games_played'] ?? 0,
          'totalPointsSpent': data['total_points_spent_on_games'] ?? 0,
          'totalPointsWon': data['total_points_won_from_games'] ?? 0,
          'winningGames': data['winning_games'] ?? 0,
          'winRate': data['win_rate'] ?? 0.0,
          'netPoints': data['net_points_from_games'] ?? 0,
        };
      }
    } catch (e) {
      print('Erreur lors de la récupération des statistiques de jeux: $e');
    }
    return {
      'totalGames': 0,
      'totalPointsSpent': 0,
      'totalPointsWon': 0,
      'winningGames': 0,
      'winRate': 0.0,
      'netPoints': 0,
    };
  }

  Future<bool> hasEnoughPoints(String userId, int requiredPoints) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final availablePoints = data['available_points'] ?? 0;
        print(
          '🔍 DjangoGameService: Checking points - Required: $requiredPoints, Available: $availablePoints',
        );
        return availablePoints >= requiredPoints;
      } else {
        print(
          '❌ DjangoGameService: Failed to get user profile - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ DjangoGameService: Error checking points: $e');
    }
    return false;
  }

  Future<bool> hasLoyaltyBonusQRCode(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games/loyalty-bonus/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['has_loyalty_bonus'] ?? false;
      }
    } catch (e) {
      print('Erreur lors de la vérification du bonus fidélité: $e');
    }
    return false;
  }

  Future<String?> getLoyaltyBonusQRCode(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games/loyalty-bonus/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['loyalty_bonus_qr_code'];
      }
    } catch (e) {
      print('Erreur lors de la récupération du QR code bonus fidélité: $e');
    }
    return null;
  }

  Future<void> processGamePoints(
    String userId,
    int pointsSpent,
    int pointsWon,
  ) async {
    // Django gère automatiquement le traitement des points lors du jeu
    print(
      'DjangoGameService: Traitement des points géré automatiquement par Django',
    );
  }

  Future<Map<String, dynamic>> playGame(
    String userId,
    String gameType,
    int pointsCost, {
    String? loyaltyBonusQRCode,
  }) async {
    try {
      final requestBody = {'game_type': gameType, 'points_cost': pointsCost};

      // Si un QR code loyalty_bonus est fourni, l'utiliser pour jouer gratuitement
      if (loyaltyBonusQRCode != null) {
        requestBody['loyalty_bonus_qr_code'] = loyaltyBonusQRCode;
        requestBody['points_cost'] = 0; // Jeu gratuit avec le QR code
      }

      final response = await http.post(
        Uri.parse('$baseUrl/games/play/'),
        headers: _authHeaders,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'pointsWon': data['points_won'] ?? 0,
          'pointsSpent': data['points_spent'] ?? pointsCost,
          'netPoints': data['net_points'] ?? 0,
          'isWinning': data['is_winning'] ?? false,
          'message': data['message'] ?? 'Jeu terminé',
          'usedLoyaltyBonus': loyaltyBonusQRCode != null,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors du jeu',
        };
      }
    } catch (e) {
      print('Erreur lors du jeu: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  List<Map<String, dynamic>> getAvailableGames() {
    return [
      {
        'type': 'scratch_win',
        'name': 'Scratch & Win',
        'description': 'Grattez pour gagner des points',
        'cost': 10,
        'icon': 'brush',
        'color': 0xFF488950,
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
