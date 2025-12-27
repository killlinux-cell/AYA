import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/qr_code.dart';

class ApiService {
  // Configuration de l'API (à adapter selon votre backend)
  static const String baseUrl = 'https://votre-api-backend.com/api';
  static const String apiKey = 'votre-api-key'; // À configurer

  // Headers pour les requêtes API
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
    'Accept': 'application/json',
  };

  // 1. Stocker les données de jeu
  static Future<bool> storeGameData({
    required String userId,
    required String gameType,
    required int pointsWon,
    required int cost,
    required Map<String, dynamic> gameDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/games/store'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'game_type': gameType,
          'points_won': pointsWon,
          'cost': cost,
          'game_details': gameDetails,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('ApiService: Game data stored successfully');
        return true;
      } else {
        print('ApiService: Failed to store game data: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('ApiService: Error storing game data: $e');
      return false;
    }
  }

  // 2. Stocker les données de points
  static Future<bool> storePointsData({
    required String userId,
    required int availablePoints,
    required int exchangedPoints,
    required String action, // 'earned', 'spent', 'exchanged'
    required Map<String, dynamic> details,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/points/store'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'available_points': availablePoints,
          'exchanged_points': exchangedPoints,
          'action': action,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('ApiService: Points data stored successfully');
        return true;
      } else {
        print(
          'ApiService: Failed to store points data: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('ApiService: Error storing points data: $e');
      return false;
    }
  }

  // 3. Stocker les données de QR codes scannés
  static Future<bool> storeQRCodeData({
    required String userId,
    required QRCode qrCode,
    required Map<String, dynamic> scanDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/qrcodes/store'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'qr_code_id': qrCode.id,
          'qr_code': qrCode.code,
          'points_earned': qrCode.points,
          'collected_at': qrCode.collectedAt.toIso8601String(),
          'description': qrCode.description,
          'scan_details': scanDetails,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('ApiService: QR code data stored successfully');
        return true;
      } else {
        print(
          'ApiService: Failed to store QR code data: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('ApiService: Error storing QR code data: $e');
      return false;
    }
  }

  // 4. Récupérer l'historique des jeux d'un utilisateur
  static Future<List<Map<String, dynamic>>> getGameHistory(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games/history/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['games'] ?? []);
      } else {
        print('ApiService: Failed to get game history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('ApiService: Error getting game history: $e');
      return [];
    }
  }

  // 5. Récupérer l'historique des points d'un utilisateur
  static Future<List<Map<String, dynamic>>> getPointsHistory(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/points/history/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['points'] ?? []);
      } else {
        print(
          'ApiService: Failed to get points history: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('ApiService: Error getting points history: $e');
      return [];
    }
  }

  // 6. Récupérer l'historique des QR codes d'un utilisateur
  static Future<List<Map<String, dynamic>>> getQRCodeHistory(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/qrcodes/history/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['qrcodes'] ?? []);
      } else {
        print(
          'ApiService: Failed to get QR code history: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('ApiService: Error getting QR code history: $e');
      return [];
    }
  }

  // 7. Obtenir les statistiques globales
  static Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats/global'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('ApiService: Failed to get global stats: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('ApiService: Error getting global stats: $e');
      return {};
    }
  }

  // 8. Obtenir les statistiques d'un utilisateur
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats/user/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('ApiService: Failed to get user stats: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('ApiService: Error getting user stats: $e');
      return {};
    }
  }

  // 9. Synchroniser les données avec l'API
  static Future<bool> syncDataWithAPI({
    required String userId,
    required List<Map<String, dynamic>> gameData,
    required List<Map<String, dynamic>> pointsData,
    required List<Map<String, dynamic>> qrCodeData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'game_data': gameData,
          'points_data': pointsData,
          'qr_code_data': qrCodeData,
          'sync_timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('ApiService: Data synced successfully');
        return true;
      } else {
        print('ApiService: Failed to sync data: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('ApiService: Error syncing data: $e');
      return false;
    }
  }

  // 10. Vérifier la connectivité de l'API
  static Future<bool> checkApiConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('ApiService: API connectivity check failed: $e');
      return false;
    }
  }
}
