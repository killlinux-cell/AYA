import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'django_auth_service.dart';

class DjangoExchangeService {
  static const String baseUrl = DjangoConfig.qrUrl;
  final DjangoAuthService _authService;

  DjangoExchangeService(this._authService);

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  static Future<void> confirmExchange(String exchangeId) async {
    // Cette méthode statique est maintenue pour la compatibilité
    throw UnimplementedError('Utilisez confirmExchangeWithAuth à la place');
  }

  Future<void> confirmExchangeWithAuth(String exchangeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/exchanges/confirm/'),
        headers: _authHeaders,
        body: jsonEncode({'exchange_id': exchangeId}),
      );

      if (response.statusCode == 200) {
        print('Échange confirmé avec succès');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Erreur lors de la confirmation');
      }
    } catch (e) {
      print('Erreur lors de la confirmation de l\'échange: $e');
      throw Exception('Erreur lors de la confirmation de l\'échange');
    }
  }

  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    // Cette méthode statique est maintenue pour la compatibilité
    throw UnimplementedError('Utilisez getUserInfoWithAuth à la place');
  }

  Future<Map<String, dynamic>?> getUserInfoWithAuth(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'id': data['id'],
          'name': '${data['first_name']} ${data['last_name']}',
          'email': data['email'],
          'availablePoints': data['available_points'],
          'exchangedPoints': data['exchanged_points'],
        };
      }
    } catch (e) {
      print('Erreur lors de la récupération des informations utilisateur: $e');
    }
    return null;
  }

  static Future<String> createExchangeRequest({
    required String userId,
    required int points,
    required String exchangeCode,
  }) async {
    // Cette méthode statique est maintenue pour la compatibilité
    throw UnimplementedError(
      'Utilisez createExchangeRequestWithAuth à la place',
    );
  }

  Future<String> createExchangeRequestWithAuth({
    required String userId,
    required int points,
    required String exchangeCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/exchanges/create/'),
        headers: _authHeaders,
        body: jsonEncode({'points': points}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] ?? '';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Erreur lors de la création de la demande',
        );
      }
    } catch (e) {
      print('Erreur lors de la création de la demande d\'échange: $e');
      throw Exception('Erreur lors de la création de la demande d\'échange');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserExchangeHistory(
    String userId,
  ) async {
    // Cette méthode statique est maintenue pour la compatibilité
    throw UnimplementedError(
      'Utilisez getUserExchangeHistoryWithAuth à la place',
    );
  }

  Future<List<Map<String, dynamic>>> getUserExchangeHistoryWithAuth(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exchanges/list/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> exchangesData = data['results'] ?? data;

        return exchangesData
            .map(
              (exchangeData) => {
                'id': exchangeData['id'],
                'user_id': exchangeData['user'],
                'points': exchangeData['points'],
                'exchange_code': exchangeData['exchange_code'],
                'created_at': exchangeData['created_at'],
                'is_completed': exchangeData['is_completed'] ?? false,
                'completed_at': exchangeData['completed_at'],
              },
            )
            .toList();
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique des échanges: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> validateExchangeCode(
    String exchangeCode,
  ) async {
    // Cette méthode statique est maintenue pour la compatibilité
    throw UnimplementedError(
      'Utilisez validateExchangeCodeWithAuth à la place',
    );
  }

  Future<Map<String, dynamic>?> validateExchangeCodeWithAuth(
    String exchangeCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/exchanges/validate/'),
        headers: _authHeaders,
        body: jsonEncode({'exchange_code': exchangeCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_valid'] == true) {
          return data['exchange_request'];
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Code d\'échange invalide');
      }
    } catch (e) {
      print('Erreur lors de la validation du code d\'échange: $e');
      throw Exception('Erreur lors de la validation du code d\'échange');
    }
    return null;
  }
}
