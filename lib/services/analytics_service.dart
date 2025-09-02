import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_history.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      print('Error getting user stats: $e');
      return {};
    }
  }

  /// Obtenir les statistiques des QR codes scannés
  Future<Map<String, dynamic>> getQRCodeStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_qr_codes')
          .select('''
            qr_code_id,
            scanned_at,
            qr_codes!inner(points, description)
          ''')
          .eq('user_id', userId);

      final qrCodes = response as List;

      int totalScanned = qrCodes.length;
      int totalPoints = qrCodes.fold(
        0,
        (sum, qr) => sum + ((qr['qr_codes']['points'] ?? 0) as int),
      );
      int uniqueCodes = qrCodes.map((qr) => qr['qr_code_id']).toSet().length;

      // Répartition par points
      Map<int, int> pointsDistribution = {};
      for (var qr in qrCodes) {
        final points = qr['qr_codes']['points'] ?? 0;
        pointsDistribution[points] = (pointsDistribution[points] ?? 0) + 1;
      }

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
      print('Error getting QR code stats: $e');
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

      // Répartition par type de jeu
      Map<String, int> gameTypeDistribution = {};
      for (var game in games) {
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
      print('Error getting game stats: $e');
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
      final response = await _supabase
          .from('exchange_requests')
          .select()
          .eq('user_id', userId);

      final exchanges = response as List;

      int totalExchanges = exchanges.length;
      int totalPointsExchanged = exchanges.fold(
        0,
        (sum, exchange) => sum + ((exchange['points_to_exchange'] ?? 0) as int),
      );
      int completedExchanges = exchanges
          .where((exchange) => exchange['status'] == 'completed')
          .length;

      double completionRate = totalExchanges > 0
          ? (completedExchanges / totalExchanges) * 100
          : 0;

      return {
        'totalExchanges': totalExchanges,
        'totalPointsExchanged': totalPointsExchanged,
        'completedExchanges': completedExchanges,
        'completionRate': completionRate,
        'averagePointsPerExchange': totalExchanges > 0
            ? totalPointsExchanged / totalExchanges
            : 0,
      };
    } catch (e) {
      print('Error getting exchange stats: $e');
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
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return {
        'id': response['id'],
        'email': response['email'],
        'firstName': response['first_name'],
        'lastName': response['last_name'],
        'availablePoints': response['available_points'],
        'exchangedPoints': response['exchanged_points'],
        'collectedQRCodes': response['collected_qr_codes'],
        'createdAt': response['created_at'],
        'lastLoginAt': response['last_login_at'],
      };
    } catch (e) {
      print('Error getting user info: $e');
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

  /// Obtenir les statistiques globales (admin)
  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      // Statistiques des utilisateurs
      final userStats = await _getUserStats();

      // Statistiques des QR codes
      final qrCodeStats = await _getQRCodeStats();

      // Statistiques des jeux
      final gameStats = await _getGameStats();

      // Statistiques des échanges
      final exchangeStats = await _getExchangeStats();

      return {
        'users': userStats,
        'qrCodes': qrCodeStats,
        'games': gameStats,
        'exchanges': exchangeStats,
      };
    } catch (e) {
      print('Error getting global stats: $e');
      return {};
    }
  }

  /// Statistiques des utilisateurs
  Future<Map<String, dynamic>> _getUserStats() async {
    try {
      final response = await _supabase
          .from('users')
          .select('created_at, last_login_at');

      final users = response as List;
      final totalUsers = users.length;
      final activeUsers = users.where((user) {
        final lastLogin = user['last_login_at'];
        if (lastLogin == null) return false;
        final lastLoginDate = DateTime.parse(lastLogin);
        final now = DateTime.now();
        return now.difference(lastLoginDate).inDays <= 30;
      }).length;

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'activityRate': totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  /// Statistiques globales des QR codes
  Future<Map<String, dynamic>> _getQRCodeStats() async {
    try {
      final response = await _supabase
          .from('user_qr_codes')
          .select('scanned_at');

      final scans = response as List;
      final totalScans = scans.length;

      // Scans par jour (derniers 30 jours)
      final now = DateTime.now();
      final recentScans = scans.where((scan) {
        final scanDate = DateTime.parse(scan['scanned_at']);
        return now.difference(scanDate).inDays <= 30;
      }).length;

      return {
        'totalScans': totalScans,
        'recentScans': recentScans,
        'averageScansPerDay': 30 > 0 ? recentScans / 30 : 0,
      };
    } catch (e) {
      print('Error getting QR code stats: $e');
      return {};
    }
  }

  /// Statistiques globales des jeux
  Future<Map<String, dynamic>> _getGameStats() async {
    try {
      final response = await _supabase
          .from('game_history')
          .select('game_type, points_won, played_at');

      final games = response as List;
      final totalGames = games.length;
      final totalPointsWon = games.fold(
        0,
        (sum, game) => sum + ((game['points_won'] ?? 0) as int),
      );

      // Répartition par type de jeu
      Map<String, int> gameTypeDistribution = {};
      for (var game in games) {
        final gameType = game['game_type'];
        gameTypeDistribution[gameType] =
            (gameTypeDistribution[gameType] ?? 0) + 1;
      }

      return {
        'totalGames': totalGames,
        'totalPointsWon': totalPointsWon,
        'gameTypeDistribution': gameTypeDistribution,
        'averagePointsPerGame': totalGames > 0
            ? totalPointsWon / totalGames
            : 0,
      };
    } catch (e) {
      print('Error getting game stats: $e');
      return {};
    }
  }

  /// Statistiques globales des échanges
  Future<Map<String, dynamic>> _getExchangeStats() async {
    try {
      final response = await _supabase
          .from('exchange_requests')
          .select('status, points_to_exchange, created_at');

      final exchanges = response as List;
      final totalExchanges = exchanges.length;
      final completedExchanges = exchanges
          .where((exchange) => exchange['status'] == 'completed')
          .length;
      final totalPointsExchanged = exchanges.fold(
        0,
        (sum, exchange) => sum + ((exchange['points_to_exchange'] ?? 0) as int),
      );

      return {
        'totalExchanges': totalExchanges,
        'completedExchanges': completedExchanges,
        'totalPointsExchanged': totalPointsExchanged,
        'completionRate': totalExchanges > 0
            ? (completedExchanges / totalExchanges) * 100
            : 0,
        'averagePointsPerExchange': totalExchanges > 0
            ? totalPointsExchanged / totalExchanges
            : 0,
      };
    } catch (e) {
      print('Error getting exchange stats: $e');
      return {};
    }
  }
}
