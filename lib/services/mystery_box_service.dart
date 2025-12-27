import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'django_auth_service.dart';

class MysteryBoxService {
  static const String baseUrl = DjangoConfig.qrUrl;
  final DjangoAuthService _authService;

  MysteryBoxService(this._authService);

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  /// Ouvrir une Mystery Box et révéler le contenu
  Future<MysteryBoxResult> openMysteryBox(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mystery-box/open/'),
        headers: _authHeaders,
        body: jsonEncode({'qr_code': qrCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MysteryBoxResult(
          success: true,
          prizeType: data['prize_type'] ?? 'unknown',
          prizeValue: data['prize_value'] ?? 0,
          prizeDescription: data['prize_description'] ?? '',
          message: data['message'] ?? 'Mystery Box ouverte avec succès !',
          isSpecialPrize: data['is_special_prize'] ?? false,
        );
      } else {
        final errorData = jsonDecode(response.body);
        return MysteryBoxResult(
          success: false,
          error:
              errorData['error'] ??
              'Erreur lors de l\'ouverture de la Mystery Box',
        );
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture de la Mystery Box: $e');
      return MysteryBoxResult(success: false, error: 'Erreur de connexion');
    }
  }

  /// Vérifier si l'utilisateur a des Mystery Box disponibles
  Future<bool> hasMysteryBoxAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mystery-box/available/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['has_mystery_box'] ?? false;
      }
    } catch (e) {
      print('Erreur lors de la vérification des Mystery Box: $e');
    }
    return false;
  }

  /// Récupérer l'historique des Mystery Box ouvertes
  Future<List<MysteryBoxHistory>> getMysteryBoxHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mystery-box/history/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> historyData = data['results'] ?? data;

        return historyData
            .map(
              (item) => MysteryBoxHistory(
                id: item['id'] ?? '',
                qrCode: item['qr_code'] ?? '',
                prizeType: item['prize_type'] ?? '',
                prizeValue: item['prize_value'] ?? 0,
                prizeDescription: item['prize_description'] ?? '',
                openedAt: item['opened_at'] != null
                    ? DateTime.parse(item['opened_at'])
                    : DateTime.now(),
                isSpecialPrize: item['is_special_prize'] ?? false,
              ),
            )
            .toList();
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: $e');
    }
    return [];
  }

  /// Obtenir les statistiques des Mystery Box
  Future<MysteryBoxStats> getMysteryBoxStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mystery-box/stats/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MysteryBoxStats(
          totalOpened: data['total_opened'] ?? 0,
          totalValue: data['total_value'] ?? 0,
          specialPrizes: data['special_prizes'] ?? 0,
          averageValue: data['average_value'] ?? 0.0,
          lastOpened: data['last_opened'] != null
              ? DateTime.parse(data['last_opened'])
              : null,
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
    }
    return MysteryBoxStats(
      totalOpened: 0,
      totalValue: 0,
      specialPrizes: 0,
      averageValue: 0.0,
      lastOpened: null,
    );
  }
}

/// Résultat de l'ouverture d'une Mystery Box
class MysteryBoxResult {
  final bool success;
  final String? prizeType;
  final int prizeValue;
  final String? prizeDescription;
  final String? message;
  final String? error;
  final bool isSpecialPrize;

  MysteryBoxResult({
    required this.success,
    this.prizeType,
    this.prizeValue = 0,
    this.prizeDescription,
    this.message,
    this.error,
    this.isSpecialPrize = false,
  });
}

/// Historique des Mystery Box ouvertes
class MysteryBoxHistory {
  final String id;
  final String qrCode;
  final String prizeType;
  final int prizeValue;
  final String prizeDescription;
  final DateTime openedAt;
  final bool isSpecialPrize;

  MysteryBoxHistory({
    required this.id,
    required this.qrCode,
    required this.prizeType,
    required this.prizeValue,
    required this.prizeDescription,
    required this.openedAt,
    required this.isSpecialPrize,
  });
}

/// Statistiques des Mystery Box
class MysteryBoxStats {
  final int totalOpened;
  final int totalValue;
  final int specialPrizes;
  final double averageValue;
  final DateTime? lastOpened;

  MysteryBoxStats({
    required this.totalOpened,
    required this.totalValue,
    required this.specialPrizes,
    required this.averageValue,
    this.lastOpened,
  });
}
