import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import '../utils/error_handler.dart';
import 'django_auth_service.dart';

class GrandPrixService {
  static const String baseUrl = DjangoConfig.authUrl;
  final DjangoAuthService _authService;

  GrandPrixService(this._authService);

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  /// Récupérer le grand prix actuel
  Future<GrandPrix?> getCurrentGrandPrix() async {
    try {
      print('🔄 GrandPrixService: Récupération du grand prix actuel...');
      print('🌐 URL: $baseUrl/grand-prix/current/');
      print('🔑 Headers: $_authHeaders');

      // Vérifier si l'utilisateur est authentifié
      if (_authService.accessToken == null) {
        print('❌ GrandPrixService: Utilisateur non authentifié');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/grand-prix/current/'),
        headers: _authHeaders,
      );

      print('📡 GrandPrixService: Status Code: ${response.statusCode}');
      print('📄 GrandPrixService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 GrandPrixService: Données reçues: $data');
        if (data['success'] == true && data['grand_prix'] != null) {
          final grandPrix = GrandPrix.fromJson(data['grand_prix']);
          print(
            '✅ GrandPrixService: Grand prix trouvé: ${grandPrix.name} (Actif: ${grandPrix.isActive})',
          );
          return grandPrix;
        } else {
          print('⚠️ GrandPrixService: Aucun grand prix dans la réponse');
        }
      } else if (response.statusCode == 404) {
        print('ℹ️ GrandPrixService: Aucun grand prix actif actuellement');
        return null;
      } else if (response.statusCode == 401) {
        print('❌ GrandPrixService: Non autorisé - Token invalide ou expiré');
        return null;
      } else {
        print(
          '❌ GrandPrixService: Erreur API: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération du grand prix: $e');
      // Ne pas exposer les détails de l'erreur à l'utilisateur
    }
    return null;
  }

  /// Participer au grand prix actuel
  Future<GrandPrixParticipationResult> participateInGrandPrix() async {
    try {
      print('🔄 GrandPrixService: Participation au grand prix...');
      print('🌐 URL: $baseUrl/grand-prix/participate/');
      print('🔑 Headers: $_authHeaders');

      final response = await http.post(
        Uri.parse('$baseUrl/grand-prix/participate/'),
        headers: _authHeaders,
        body: jsonEncode({}), // Pas de données à envoyer
      );

      print('📡 GrandPrixService: Status Code: ${response.statusCode}');
      print('📄 GrandPrixService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return GrandPrixParticipationResult(
            success: true,
            message:
                data['message'] ?? 'Participation enregistrée avec succès !',
            participation: data['participation'],
            userPoints: data['user_points'],
          );
        }
      } else {
        final data = jsonDecode(response.body);
        return GrandPrixParticipationResult(
          success: false,
          error: data['error'] ?? 'Erreur lors de la participation',
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la participation: $e');
      return GrandPrixParticipationResult(
        success: false,
        error: ErrorHandler.handleGrandPrixError(e),
      );
    }
    return GrandPrixParticipationResult(
      success: false,
      error: 'Erreur inconnue',
    );
  }

  /// Récupérer l'historique des participations de l'utilisateur
  Future<List<GrandPrixParticipation>> getUserParticipations() async {
    try {
      print('🔄 GrandPrixService: Récupération des participations...');
      print('🌐 URL: $baseUrl/grand-prix/my-participations/');
      print('🔑 Headers: $_authHeaders');

      final response = await http.get(
        Uri.parse('$baseUrl/grand-prix/my-participations/'),
        headers: _authHeaders,
      );

      print('📡 GrandPrixService: Status Code: ${response.statusCode}');
      print('📄 GrandPrixService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['participations'] != null) {
          final List<dynamic> participationsData = data['participations'];
          return participationsData
              .map(
                (participation) =>
                    GrandPrixParticipation.fromJson(participation),
              )
              .toList();
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des participations: $e');
      // Ne pas exposer les détails de l'erreur à l'utilisateur
    }
    return [];
  }
}

/// Modèle pour un grand prix
class GrandPrix {
  final String id;
  final String name;
  final String description;
  final int participationCost;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime drawDate;
  final bool hasParticipated;
  final List<GrandPrixPrize> prizes;

  GrandPrix({
    required this.id,
    required this.name,
    required this.description,
    required this.participationCost,
    required this.startDate,
    required this.endDate,
    required this.drawDate,
    required this.hasParticipated,
    required this.prizes,
  });

  factory GrandPrix.fromJson(Map<String, dynamic> json) {
    return GrandPrix(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      participationCost: json['participation_cost'] ?? 0,
      startDate: DateTime.parse(json['start_date']).toLocal(),
      endDate: DateTime.parse(json['end_date']).toLocal(),
      drawDate: DateTime.parse(json['draw_date']).toLocal(),
      hasParticipated: json['has_participated'] ?? false,
      prizes:
          (json['prizes'] as List<dynamic>?)
              ?.map((prize) => GrandPrixPrize.fromJson(prize))
              .toList() ??
          [],
    );
  }

  /// Vérifier si le grand prix est actif
  bool get isActive {
    final now = DateTime.now();
    print('🔍 GrandPrix.isActive:');
    print('   - now: $now');
    print('   - startDate: $startDate');
    print('   - endDate: $endDate');
    print('   - now.isAfter(startDate): ${now.isAfter(startDate)}');
    print('   - now.isBefore(endDate): ${now.isBefore(endDate)}');

    // Vérifier que les dates sont valides
    if (startDate.isAfter(endDate)) {
      print('   - ❌ Erreur: startDate est après endDate');
      return false;
    }

    final isActive = now.isAfter(startDate) && now.isBefore(endDate);
    print('   - isActive: $isActive');
    return isActive;
  }

  /// Vérifier si le grand prix est à venir
  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  /// Vérifier si le grand prix est terminé
  bool get isFinished {
    return DateTime.now().isAfter(endDate);
  }
}

/// Modèle pour une récompense de grand prix
class GrandPrixPrize {
  final int position;
  final String name;
  final String description;
  final double? value;

  GrandPrixPrize({
    required this.position,
    required this.name,
    required this.description,
    this.value,
  });

  factory GrandPrixPrize.fromJson(Map<String, dynamic> json) {
    return GrandPrixPrize(
      position: json['position'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      value: json['value']?.toDouble(),
    );
  }

  /// Obtenir le nom de la position
  String get positionName {
    switch (position) {
      case 1:
        return '1er prix';
      case 2:
        return '2ème prix';
      case 3:
        return '3ème prix';
      default:
        return '${position}ème prix';
    }
  }
}

/// Modèle pour une participation à un grand prix
class GrandPrixParticipation {
  final String id;
  final String grandPrixName;
  final int pointsSpent;
  final bool isWinner;
  final GrandPrixPrize? prizeWon;
  final DateTime participatedAt;
  final DateTime? notifiedAt;

  GrandPrixParticipation({
    required this.id,
    required this.grandPrixName,
    required this.pointsSpent,
    required this.isWinner,
    this.prizeWon,
    required this.participatedAt,
    this.notifiedAt,
  });

  factory GrandPrixParticipation.fromJson(Map<String, dynamic> json) {
    return GrandPrixParticipation(
      id: json['id'] ?? '',
      grandPrixName: json['grand_prix_name'] ?? '',
      pointsSpent: json['points_spent'] ?? 0,
      isWinner: json['is_winner'] ?? false,
      prizeWon: json['prize_won'] != null
          ? GrandPrixPrize.fromJson(json['prize_won'])
          : null,
      participatedAt: DateTime.parse(json['participated_at']),
      notifiedAt: json['notified_at'] != null
          ? DateTime.parse(json['notified_at'])
          : null,
    );
  }
}

/// Résultat d'une participation à un grand prix
class GrandPrixParticipationResult {
  final bool success;
  final String? message;
  final String? error;
  final Map<String, dynamic>? participation;
  final int? userPoints;

  GrandPrixParticipationResult({
    required this.success,
    this.message,
    this.error,
    this.participation,
    this.userPoints,
  });
}
