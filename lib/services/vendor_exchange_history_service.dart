import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'vendor_auth_service.dart';

class VendorExchangeHistoryService {
  static const String baseUrl = '${DjangoConfig.baseUrl}/api';
  final VendorAuthService _vendorAuthService;

  VendorExchangeHistoryService(this._vendorAuthService);

  // Headers pour les requêtes authentifiées (utilise le token vendeur)
  Map<String, String> get _authHeaders =>
      _vendorAuthService.getAuthHeaders();

  /// Déduplique les échanges (le backend peut créer 2 enregistrements par validation)
  List<VendorExchange> _deduplicateExchanges(List<VendorExchange> exchanges) {
    if (exchanges.isEmpty) return exchanges;

    final seen = <String>{};
    final result = <VendorExchange>[];

    // Trier par date décroissante pour garder le plus récent en cas de doublon
    final sorted = List<VendorExchange>.from(exchanges)
      ..sort((a, b) => (b.completedAt ?? b.createdAt)
          .compareTo(a.completedAt ?? a.createdAt));

    for (final e in sorted) {
      // Fenêtre de 30 secondes : même user + points + créé à <30s = doublon
      final timeSlot = e.createdAt.millisecondsSinceEpoch ~/ 30000;
      final key = '${e.userId}_${e.points}_$timeSlot';

      if (!seen.contains(key)) {
        seen.add(key);
        result.add(e);
      }
    }

    // Remettre en ordre chronologique (plus récent en premier)
    result.sort((a, b) => (b.completedAt ?? b.createdAt)
        .compareTo(a.completedAt ?? a.createdAt));

    if (result.length < exchanges.length) {
      print(
        '📌 Déduplication: ${exchanges.length} → ${result.length} échanges',
      );
    }
    return result;
  }

  /// Récupérer l'historique des échanges d'un vendeur
  Future<List<VendorExchange>> getExchangeHistory() async {
    try {
      await _vendorAuthService.initialize();
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

        var exchanges = exchangesData
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

        // Déduplication : le backend peut créer 2 enregistrements pour le même échange
        exchanges = _deduplicateExchanges(exchanges);

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
      await _vendorAuthService.initialize();
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

  /// Récupérer les statistiques des échanges (depuis l'API vendeur filtrée)
  Future<VendorExchangeStats> getExchangeStats() async {
    try {
      await _vendorAuthService.initialize();
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/exchange-history/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final stats = data['stats'] as Map<String, dynamic>?;
        if (stats != null) {
          return VendorExchangeStats(
            totalExchanges: (stats['total_exchanges'] as num?)?.toInt() ?? 0,
            totalPoints: (stats['total_points'] as num?)?.toInt() ?? 0,
            todayExchanges: (stats['today_exchanges'] as num?)?.toInt() ?? 0,
            thisWeekExchanges: (stats['week_exchanges'] as num?)?.toInt() ?? 0,
            uniqueClients: (stats['unique_clients'] as num?)?.toInt() ?? 0,
          );
        }
      }

      // Fallback local si ancienne API
      final exchanges = await getExchangeHistory();
      final clientIds = exchanges.map((e) => e.userId).toSet();
      return VendorExchangeStats(
        totalExchanges: exchanges.length,
        totalPoints: exchanges.fold(0, (sum, e) => sum + e.points),
        todayExchanges: exchanges.where((e) {
          final d = e.completedAt ?? e.createdAt;
          final now = DateTime.now();
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).length,
        thisWeekExchanges: exchanges.where((e) {
          final d = e.completedAt ?? e.createdAt;
          return d.isAfter(DateTime.now().subtract(const Duration(days: 7)));
        }).length,
        uniqueClients: clientIds.length,
      );
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return VendorExchangeStats(
        totalExchanges: 0,
        totalPoints: 0,
        todayExchanges: 0,
        thisWeekExchanges: 0,
        uniqueClients: 0,
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
  final int uniqueClients;

  VendorExchangeStats({
    required this.totalExchanges,
    required this.totalPoints,
    required this.todayExchanges,
    required this.thisWeekExchanges,
    this.uniqueClients = 0,
  });
}
