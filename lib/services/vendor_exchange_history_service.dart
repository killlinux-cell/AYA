import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'django_auth_service.dart';

class VendorExchangeHistoryService {
  static const String baseUrl = '${DjangoConfig.baseUrl}/api';
  final DjangoAuthService _authService;

  VendorExchangeHistoryService(this._authService);

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  /// Récupérer l'historique des échanges d'un vendeur
  Future<List<VendorExchange>> getExchangeHistory() async {
    try {
      print(
        '🔄 VendorExchangeHistoryService: Récupération de l\'historique des échanges...',
      );
      print('🌐 URL: $baseUrl/vendor/exchange-history/');
      print('🔑 Headers: $_authHeaders');

      final response = await http.get(
        Uri.parse('$baseUrl/vendor/exchange-history/'),
        headers: _authHeaders,
      );

      print(
        '📡 VendorExchangeHistoryService: Status Code: ${response.statusCode}',
      );
      print('📄 VendorExchangeHistoryService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> exchangesData = data['results'] ?? data;
        final List<dynamic> pendingTokensData = data['pending_tokens'] ?? [];

        print(
          '📊 VendorExchangeHistoryService: Nombre d\'échanges reçus: ${exchangesData.length}',
        );
        print(
          '📋 VendorExchangeHistoryService: Nombre de tokens en attente: ${pendingTokensData.length}',
        );

        final exchanges = exchangesData
            .map(
              (exchangeData) => VendorExchange(
                id: exchangeData['id'] ?? '',
                userId: exchangeData['user_id'] ?? '',
                userName: exchangeData['user_name'] ?? '',
                userEmail: exchangeData['user_email'] ?? '',
                points: exchangeData['points'] ?? 0,
                exchangeCode: exchangeData['exchange_code'] ?? '',
                status: exchangeData['status'] ?? '',
                createdAt:
                    DateTime.tryParse(exchangeData['created_at'] ?? '') ??
                    DateTime.now(),
                approvedAt: exchangeData['approved_at'] != null
                    ? DateTime.tryParse(exchangeData['approved_at'])
                    : null,
                completedAt: exchangeData['completed_at'] != null
                    ? DateTime.tryParse(exchangeData['completed_at'])
                    : null,
                notes: exchangeData['notes'] ?? '',
              ),
            )
            .toList();

        print(
          '✅ VendorExchangeHistoryService: Historique récupéré avec succès: ${exchanges.length} échanges',
        );
        for (final exchange in exchanges) {
          print(
            '   - ${exchange.userName}: ${exchange.points} points (${exchange.status})',
          );
        }

        return exchanges;
      } else {
        print(
          '❌ VendorExchangeHistoryService: Erreur HTTP ${response.statusCode}',
        );
        print('📄 VendorExchangeHistoryService: Réponse: ${response.body}');
        return [];
      }
    } catch (e) {
      print(
        '❌ VendorExchangeHistoryService: Erreur lors de la récupération de l\'historique: $e',
      );
      return [];
    }
  }

  /// Récupérer les tokens d'échange en attente
  Future<List<VendorExchange>> getPendingTokens() async {
    try {
      print(
        '🔄 VendorExchangeHistoryService: Récupération des tokens en attente...',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/vendor/exchange-history/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> pendingTokensData = data['pending_tokens'] ?? [];

        print(
          '📋 VendorExchangeHistoryService: Nombre de tokens en attente: ${pendingTokensData.length}',
        );

        final pendingTokens = pendingTokensData
            .map(
              (tokenData) => VendorExchange(
                id: tokenData['id'] ?? '',
                userId: tokenData['user_id'] ?? '',
                userName: tokenData['user_name'] ?? '',
                userEmail: tokenData['user_email'] ?? '',
                points: tokenData['points'] ?? 0,
                exchangeCode: tokenData['exchange_code'] ?? '',
                status: tokenData['status'] ?? '',
                createdAt:
                    DateTime.tryParse(tokenData['created_at'] ?? '') ??
                    DateTime.now(),
                approvedAt: null,
                completedAt: null,
                notes: tokenData['notes'] ?? '',
              ),
            )
            .toList();

        return pendingTokens;
      } else {
        print(
          '❌ VendorExchangeHistoryService: Erreur HTTP ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print(
        '❌ VendorExchangeHistoryService: Erreur lors de la récupération des tokens en attente: $e',
      );
      return [];
    }
  }

  /// Confirmer un échange
  Future<bool> confirmExchange(String exchangeId) async {
    try {
      print(
        '🔄 VendorExchangeHistoryService: Confirmation de l\'échange $exchangeId...',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/vendor/exchange-confirm/'),
        headers: _authHeaders,
        body: jsonEncode({'exchange_id': exchangeId}),
      );

      print(
        '📡 VendorExchangeHistoryService: Status Code: ${response.statusCode}',
      );
      print('📄 VendorExchangeHistoryService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ VendorExchangeHistoryService: Échange confirmé avec succès');
        return true;
      } else {
        print(
          '❌ VendorExchangeHistoryService: Erreur lors de la confirmation: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print(
        '❌ VendorExchangeHistoryService: Erreur lors de la confirmation: $e',
      );
      return false;
    }
  }

  /// Récupérer les statistiques des échanges
  Future<VendorExchangeStats> getExchangeStats() async {
    try {
      final exchanges = await getExchangeHistory();

      final totalExchanges = exchanges.length;
      final totalPoints = exchanges.fold(
        0,
        (sum, exchange) => sum + exchange.points,
      );
      final todayExchanges = exchanges.where((exchange) {
        final now = DateTime.now();
        final exchangeDate = exchange.completedAt ?? exchange.createdAt;
        return exchangeDate.year == now.year &&
            exchangeDate.month == now.month &&
            exchangeDate.day == now.day;
      }).length;

      final thisWeekExchanges = exchanges.where((exchange) {
        final now = DateTime.now();
        final exchangeDate = exchange.completedAt ?? exchange.createdAt;
        final weekAgo = now.subtract(const Duration(days: 7));
        return exchangeDate.isAfter(weekAgo);
      }).length;

      return VendorExchangeStats(
        totalExchanges: totalExchanges,
        totalPoints: totalPoints,
        todayExchanges: todayExchanges,
        thisWeekExchanges: thisWeekExchanges,
      );
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return VendorExchangeStats(
        totalExchanges: 0,
        totalPoints: 0,
        todayExchanges: 0,
        thisWeekExchanges: 0,
      );
    }
  }
}

/// Modèle pour un échange de vendeur
class VendorExchange {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final int points;
  final String exchangeCode;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final String notes;

  VendorExchange({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.points,
    required this.exchangeCode,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.completedAt,
    required this.notes,
  });

  bool get isCompleted => status == 'completed';

  String get formattedDate {
    final date = completedAt ?? createdAt;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get formattedTime {
    final date = completedAt ?? createdAt;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Modèle pour les statistiques des échanges
class VendorExchangeStats {
  final int totalExchanges;
  final int totalPoints;
  final int todayExchanges;
  final int thisWeekExchanges;

  VendorExchangeStats({
    required this.totalExchanges,
    required this.totalPoints,
    required this.todayExchanges,
    required this.thisWeekExchanges,
  });
}
