import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ExchangeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Confirmer un échange
  static Future<void> confirmExchange(String exchangeId) async {
    try {
      await _supabase
          .from('exchange_requests')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', exchangeId);

      print('ExchangeService: Exchange confirmed: $exchangeId');
    } catch (e) {
      print('ExchangeService: Error confirming exchange: $e');
      rethrow;
    }
  }

  // Obtenir les informations d'un utilisateur
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', userId)
          .single();

      if (response != null) {
        return {
          'id': response['id'],
          'name': '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim(),
          'email': response['email'],
          'availablePoints': response['available_points'] ?? 0,
          'exchangedPoints': response['exchanged_points'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      print('ExchangeService: Error getting user info: $e');
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
      final response = await _supabase
          .from('exchange_requests')
          .insert({
            'user_id': userId,
            'points': points,
            'exchange_code': exchangeCode,
            'created_at': DateTime.now().toIso8601String(),
            'is_completed': false,
          })
          .select()
          .single();

      print('ExchangeService: Exchange request created: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('ExchangeService: Error creating exchange request: $e');
      rethrow;
    }
  }

  // Obtenir l'historique des échanges d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserExchangeHistory(String userId) async {
    try {
      final response = await _supabase
          .from('exchange_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('ExchangeService: Error getting exchange history: $e');
      return [];
    }
  }

  // Vérifier si un code d'échange existe et est valide
  static Future<Map<String, dynamic>?> validateExchangeCode(String exchangeCode) async {
    try {
      final response = await _supabase
          .from('exchange_requests')
          .select()
          .eq('exchange_code', exchangeCode)
          .eq('is_completed', false)
          .single();

      if (response != null) {
        return {
          'id': response['id'],
          'userId': response['user_id'],
          'points': response['points'],
          'exchangeCode': response['exchange_code'],
          'createdAt': response['created_at'],
        };
      }
      return null;
    } catch (e) {
      print('ExchangeService: Error validating exchange code: $e');
      return null;
    }
  }
}
