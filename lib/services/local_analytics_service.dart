import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_history.dart';

class LocalAnalyticsService {
  static const String _gameHistoryKey = 'game_history';
  static const String _qrCodesKey = 'user_qr_codes';

  /// Obtenir les statistiques complètes d'un utilisateur
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Statistiques des QR codes scannés
      final qrStats = await getQRCodeStats(userId);

      // Statistiques des jeux
      final gameStats = await getGameStats(userId);

      // Statistiques des échanges
      final exchangeStats = await getExchangeStats(userId);

      // Informations utilisateur
      final userInfo = await getUserInfo(userId);

      return {
        'user': userInfo,
        'qrCodes': qrStats,
        'games': gameStats,
        'exchanges': exchangeStats,
        'summary': _generateSummary(qrStats, gameStats, exchangeStats),
      };
    } catch (e) {
      print('LocalAnalyticsService: Error getting user stats: $e');
      return {};
    }
  }

  /// Obtenir les statistiques des QR codes scannés
  Future<Map<String, dynamic>> getQRCodeStats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qrCodeIds = prefs.getStringList(_qrCodesKey) ?? [];

      int totalScanned = qrCodeIds.length;
      int totalPoints = totalScanned * 25; // Points moyens par QR code
      int uniqueCodes = totalScanned;

      // Répartition par points (simulée)
      Map<int, int> pointsDistribution = {
        10: (totalScanned * 0.3).round(),
        25: (totalScanned * 0.4).round(),
        50: (totalScanned * 0.2).round(),
        100: (totalScanned * 0.1).round(),
      };

      return {
        'totalScanned': totalScanned,
        'totalPoints': totalPoints,
        'uniqueCodes': uniqueCodes,
        'pointsDistribution': pointsDistribution,
        'averagePointsPerScan': totalScanned > 0
            ? totalPoints / totalScanned
            : 0,
      };
    } catch (e) {
      print('LocalAnalyticsService: Error getting QR code stats: $e');
      return {
        'totalScanned': 0,
        'totalPoints': 0,
        'uniqueCodes': 0,
        'pointsDistribution': {},
        'averagePointsPerScan': 0,
      };
    }
  }

  /// Obtenir les statistiques des jeux
  Future<Map<String, dynamic>> getGameStats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStrings = prefs.getStringList(_gameHistoryKey) ?? [];

      final games = <GameHistory>[];
      for (final historyString in historyStrings) {
        try {
          final parts = historyString.split('|');
          if (parts.length >= 6) {
            games.add(
              GameHistory(
                id: parts[0],
                userId: parts[1],
                gameType: parts[2],
                pointsSpent: int.tryParse(parts[3]) ?? 0,
                pointsWon: int.tryParse(parts[4]) ?? 0,
                playedAt: DateTime.tryParse(parts[5]) ?? DateTime.now(),
                isWinning: parts.length > 6 ? parts[6] == 'true' : false,
              ),
            );
          }
        } catch (e) {
          print('LocalAnalyticsService: Error parsing game history entry: $e');
        }
      }

      // Filtrer par utilisateur
      final userGames = games.where((game) => game.userId == userId).toList();

      int totalGames = userGames.length;
      int totalPointsSpent = userGames.fold(
        0,
        (sum, game) => sum + game.pointsSpent,
      );
      int totalPointsWon = userGames.fold(
        0,
        (sum, game) => sum + game.pointsWon,
      );
      int winningGames = userGames.where((game) => game.isWinning).length;

      double winRate = totalGames > 0 ? (winningGames / totalGames) * 100 : 0;
      int netPoints = totalPointsWon - totalPointsSpent;

      // Répartition par type de jeu
      Map<String, int> gameTypeDistribution = {};
      for (var game in userGames) {
        gameTypeDistribution[game.gameType] =
            (gameTypeDistribution[game.gameType] ?? 0) + 1;
      }

      return {
        'totalGames': totalGames,
        'totalPointsSpent': totalPointsSpent,
        'totalPointsWon': totalPointsWon,
        'winningGames': winningGames,
        'winRate': winRate,
        'netPoints': netPoints,
        'gameTypeDistribution': gameTypeDistribution,
        'averagePointsWon': totalGames > 0 ? totalPointsWon / totalGames : 0,
      };
    } catch (e) {
      print('LocalAnalyticsService: Error getting game stats: $e');
      return {
        'totalGames': 0,
        'totalPointsSpent': 0,
        'totalPointsWon': 0,
        'winningGames': 0,
        'winRate': 0,
        'netPoints': 0,
        'gameTypeDistribution': {},
        'averagePointsWon': 0,
      };
    }
  }

  /// Obtenir les statistiques des échanges
  Future<Map<String, dynamic>> getExchangeStats(String userId) async {
    try {
      // Pour la démo, retourner des statistiques fictives
      return {
        'totalExchanges': 3,
        'totalPointsExchanged': 150,
        'completedExchanges': 2,
        'completionRate': 66.7,
        'averagePointsPerExchange': 50,
      };
    } catch (e) {
      print('LocalAnalyticsService: Error getting exchange stats: $e');
      return {
        'totalExchanges': 0,
        'totalPointsExchanged': 0,
        'completedExchanges': 0,
        'completionRate': 0,
        'averagePointsPerExchange': 0,
      };
    }
  }

  /// Obtenir les informations utilisateur
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      // Pour la démo, retourner des informations fictives
      return {
        'id': userId,
        'email': 'demo@example.com',
        'firstName': 'Utilisateur',
        'lastName': 'Démo',
        'availablePoints': 100,
        'exchangedPoints': 50,
        'collectedQRCodes': 5,
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('LocalAnalyticsService: Error getting user info: $e');
      return {};
    }
  }

  /// Générer un résumé des statistiques
  Map<String, dynamic> _generateSummary(
    Map<String, dynamic> qrStats,
    Map<String, dynamic> gameStats,
    Map<String, dynamic> exchangeStats,
  ) {
    final totalPointsEarned =
        (qrStats['totalPoints'] ?? 0) + (gameStats['netPoints'] ?? 0);
    final totalPointsSpent =
        (gameStats['totalPointsSpent'] ?? 0) +
        (exchangeStats['totalPointsExchanged'] ?? 0);
    final currentBalance =
        (qrStats['totalPoints'] ?? 0) +
        (gameStats['netPoints'] ?? 0) -
        (exchangeStats['totalPointsExchanged'] ?? 0);

    return {
      'totalPointsEarned': totalPointsEarned,
      'totalPointsSpent': totalPointsSpent,
      'currentBalance': currentBalance,
      'totalActivities':
          (qrStats['totalScanned'] ?? 0) +
          (gameStats['totalGames'] ?? 0) +
          (exchangeStats['totalExchanges'] ?? 0),
      'engagementScore': _calculateEngagementScore(
        qrStats,
        gameStats,
        exchangeStats,
      ),
    };
  }

  /// Calculer un score d'engagement
  double _calculateEngagementScore(
    Map<String, dynamic> qrStats,
    Map<String, dynamic> gameStats,
    Map<String, dynamic> exchangeStats,
  ) {
    final qrScore = (qrStats['totalScanned'] ?? 0) * 10;
    final gameScore = (gameStats['totalGames'] ?? 0) * 15;
    final exchangeScore = (exchangeStats['completedExchanges'] ?? 0) * 25;

    return (qrScore + gameScore + exchangeScore) / 100.0;
  }

  /// Obtenir l'historique des jeux d'un utilisateur
  Future<List<GameHistory>> getGameHistory(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStrings = prefs.getStringList(_gameHistoryKey) ?? [];

      final history = <GameHistory>[];
      for (final historyString in historyStrings) {
        try {
          final parts = historyString.split('|');
          if (parts.length >= 6) {
            history.add(
              GameHistory(
                id: parts[0],
                userId: parts[1],
                gameType: parts[2],
                pointsSpent: int.tryParse(parts[3]) ?? 0,
                pointsWon: int.tryParse(parts[4]) ?? 0,
                playedAt: DateTime.tryParse(parts[5]) ?? DateTime.now(),
                isWinning: parts.length > 6 ? parts[6] == 'true' : false,
              ),
            );
          }
        } catch (e) {
          print('LocalAnalyticsService: Error parsing game history entry: $e');
        }
      }

      // Filtrer par utilisateur et trier par date
      return history.where((game) => game.userId == userId).toList()
        ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    } catch (e) {
      print('LocalAnalyticsService: Error getting game history: $e');
      return [];
    }
  }

  /// Obtenir les statistiques globales (admin)
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      // Pour la démo, retourner des statistiques fictives
      return {
        'users': {'totalUsers': 100, 'activeUsers': 75, 'activityRate': 75.0},
        'qrCodes': {
          'totalScans': 500,
          'recentScans': 150,
          'averageScansPerDay': 5.0,
        },
        'games': {
          'totalGames': 200,
          'totalPointsWon': 5000,
          'gameTypeDistribution': {'scratch_win': 120, 'spin_wheel': 80},
          'averagePointsPerGame': 25.0,
        },
        'exchanges': {
          'totalExchanges': 50,
          'completedExchanges': 40,
          'totalPointsExchanged': 2000,
          'completionRate': 80.0,
          'averagePointsPerExchange': 40.0,
        },
      };
    } catch (e) {
      print('LocalAnalyticsService: Error getting global stats: $e');
      return {};
    }
  }
}
