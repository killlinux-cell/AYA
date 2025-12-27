import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class LocalExchangeService {
  static const String _exchangeRequestsKey = 'exchange_requests';

  // Confirmer un échange
  static Future<void> confirmExchange(String exchangeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exchangeRequests = prefs.getStringList(_exchangeRequestsKey) ?? [];

      // Trouver et marquer l'échange comme complété
      final updatedRequests = exchangeRequests.map((request) {
        if (request.startsWith('$exchangeId|')) {
          return request.replaceAll('|false', '|true');
        }
        return request;
      }).toList();

      await prefs.setStringList(_exchangeRequestsKey, updatedRequests);
      print('LocalExchangeService: Exchange confirmed: $exchangeId');
    } catch (e) {
      print('LocalExchangeService: Error confirming exchange: $e');
      rethrow;
    }
  }

  // Obtenir les informations d'un utilisateur
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      // Pour la démo, retourner des informations fictives
      return {
        'id': userId,
        'name': 'Utilisateur Démo',
        'email': 'demo@example.com',
        'availablePoints': 100,
        'exchangedPoints': 50,
      };
    } catch (e) {
      print('LocalExchangeService: Error getting user info: $e');
      return null;
    }
  }

  // Créer une demande d'échange
  static Future<String> createExchangeRequest({
    required String userId,
    required int points,
    required String exchangeCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exchangeId = DateTime.now().millisecondsSinceEpoch.toString();

      final exchangeRequest =
          '$exchangeId|$userId|$points|$exchangeCode|${DateTime.now().toIso8601String()}|false';

      final existingRequests = prefs.getStringList(_exchangeRequestsKey) ?? [];
      existingRequests.add(exchangeRequest);
      await prefs.setStringList(_exchangeRequestsKey, existingRequests);

      print('LocalExchangeService: Exchange request created: $exchangeId');
      return exchangeId;
    } catch (e) {
      print('LocalExchangeService: Error creating exchange request: $e');
      rethrow;
    }
  }

  // Obtenir l'historique des échanges d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserExchangeHistory(
    String userId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exchangeRequests = prefs.getStringList(_exchangeRequestsKey) ?? [];

      final history = <Map<String, dynamic>>[];
      for (final request in exchangeRequests) {
        final parts = request.split('|');
        if (parts.length >= 6 && parts[1] == userId) {
          history.add({
            'id': parts[0],
            'user_id': parts[1],
            'points': int.tryParse(parts[2]) ?? 0,
            'exchange_code': parts[3],
            'created_at': parts[4],
            'is_completed': parts[5] == 'true',
          });
        }
      }

      // Trier par date de création (plus récent en premier)
      history.sort((a, b) => b['created_at'].compareTo(a['created_at']));

      return history;
    } catch (e) {
      print('LocalExchangeService: Error getting exchange history: $e');
      return [];
    }
  }

  // Vérifier si un code d'échange existe et est valide
  static Future<Map<String, dynamic>?> validateExchangeCode(
    String exchangeCode,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exchangeRequests = prefs.getStringList(_exchangeRequestsKey) ?? [];

      for (final request in exchangeRequests) {
        final parts = request.split('|');
        if (parts.length >= 6 &&
            parts[3] == exchangeCode &&
            parts[5] == 'false') {
          return {
            'id': parts[0],
            'userId': parts[1],
            'points': int.tryParse(parts[2]) ?? 0,
            'exchangeCode': parts[3],
            'createdAt': parts[4],
          };
        }
      }

      return null;
    } catch (e) {
      print('LocalExchangeService: Error validating exchange code: $e');
      return null;
    }
  }

  // Générer un code d'échange aléatoire pour les tests
  static String generateRandomExchangeCode() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
    return 'EXCH_$code';
  }
}
