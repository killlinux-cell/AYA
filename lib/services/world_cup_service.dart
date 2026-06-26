import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import '../models/world_cup_models.dart';
import 'django_auth_service.dart';

class WorldCupService {
  final DjangoAuthService _authService;

  WorldCupService(this._authService);

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authService.accessToken != null)
          'Authorization': 'Bearer ${_authService.accessToken}',
      };

  /// Matchs à pronostiquer
  Future<List<WorldCupMatch>> getMatches() async {
    try {
      final response = await http.get(
        Uri.parse(DjangoConfig.worldCupMatchesEndpoint),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['matches'] ?? data['results'] ?? data;
        if (list is List) {
          return list
              .map((e) => WorldCupMatch.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      if (kDebugMode && (response.statusCode == 404 || response.statusCode == 403)) {
        return _demoMatches();
      }
    } catch (e) {
      if (kDebugMode) return _demoMatches();
    }
    return [];
  }

  /// Classement général
  Future<List<WorldCupRankingEntry>> getRankings() async {
    try {
      final response = await http.get(
        Uri.parse(DjangoConfig.worldCupRankingsEndpoint),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['rankings'] ?? data['results'] ?? data;
        if (list is List) {
          return list
              .map(
                (e) => WorldCupRankingEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
      }

      if (kDebugMode && (response.statusCode == 404 || response.statusCode == 403)) {
        return _demoRankings();
      }
    } catch (e) {
      if (kDebugMode) return _demoRankings();
    }
    return [];
  }

  /// Enregistrer un pronostic
  Future<WorldCupPredictionResult> submitPrediction({
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    if (_authService.accessToken == null) {
      return WorldCupPredictionResult.error('Connectez-vous pour pronostiquer');
    }

    try {
      final response = await http.post(
        Uri.parse(DjangoConfig.worldCupPredictionsEndpoint),
        headers: _authHeaders,
        body: jsonEncode({
          'match_id': matchId,
          'home_score': homeScore,
          'away_score': awayScore,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prediction = data['prediction'] ?? data;
        return WorldCupPredictionResult.success(
          message: data['message'] ?? 'Pronostic enregistré !',
          prediction: WorldCupPrediction.fromJson(
            prediction is Map<String, dynamic> ? prediction : data,
          ),
        );
      }

      final errorData = jsonDecode(response.body);
      return WorldCupPredictionResult.error(
        errorData['error'] ?? errorData['detail'] ?? 'Erreur lors de l\'envoi',
      );
    } catch (e) {
      if (kDebugMode) {
        return WorldCupPredictionResult.success(
          message: 'Pronostic enregistré (mode démo)',
          prediction: WorldCupPrediction(
            matchId: matchId,
            homeScore: homeScore,
            awayScore: awayScore,
            createdAt: DateTime.now(),
          ),
        );
      }
      return WorldCupPredictionResult.error('Erreur de connexion');
    }
  }

  List<WorldCupMatch> _demoMatches() {
    final now = DateTime.now();
    return [
      WorldCupMatch(
        id: 'demo-1',
        homeTeam: 'Côte d\'Ivoire',
        awayTeam: 'Maroc',
        homeTeamCode: 'CIV',
        awayTeamCode: 'MAR',
        kickoffAt: now.add(const Duration(days: 2, hours: 20)),
        stage: 'Phase de groupes',
        groupName: 'Groupe A',
        predictionsOpen: true,
      ),
      WorldCupMatch(
        id: 'demo-2',
        homeTeam: 'France',
        awayTeam: 'Brésil',
        homeTeamCode: 'FRA',
        awayTeamCode: 'BRA',
        kickoffAt: now.add(const Duration(days: 5, hours: 21)),
        stage: 'Phase de groupes',
        groupName: 'Groupe B',
        predictionsOpen: true,
      ),
      WorldCupMatch(
        id: 'demo-3',
        homeTeam: 'Sénégal',
        awayTeam: 'Allemagne',
        homeTeamCode: 'SEN',
        awayTeamCode: 'GER',
        kickoffAt: now.subtract(const Duration(days: 1)),
        stage: 'Phase de groupes',
        groupName: 'Groupe C',
        isFinished: true,
        homeScore: 2,
        awayScore: 1,
        predictionsOpen: false,
        userPrediction: WorldCupPrediction(
          matchId: 'demo-3',
          homeScore: 1,
          awayScore: 1,
          pointsEarned: 3,
        ),
      ),
    ];
  }

  List<WorldCupRankingEntry> _demoRankings() {
    return [
      WorldCupRankingEntry(
        rank: 1,
        userId: '1',
        displayName: 'Amadou K.',
        totalPoints: 42,
        exactScores: 3,
        correctOutcomes: 8,
      ),
      WorldCupRankingEntry(
        rank: 2,
        userId: '2',
        displayName: 'Fatou D.',
        totalPoints: 38,
        exactScores: 2,
        correctOutcomes: 9,
      ),
      WorldCupRankingEntry(
        rank: 3,
        userId: _authService.currentUser?.id ?? 'me',
        displayName: _authService.currentUser?.name ?? 'Vous',
        totalPoints: 35,
        exactScores: 2,
        correctOutcomes: 7,
        isCurrentUser: true,
      ),
    ];
  }
}

class WorldCupPredictionResult {
  final bool success;
  final String? message;
  final String? error;
  final WorldCupPrediction? prediction;

  WorldCupPredictionResult._({
    required this.success,
    this.message,
    this.error,
    this.prediction,
  });

  factory WorldCupPredictionResult.success({
    required String message,
    WorldCupPrediction? prediction,
  }) {
    return WorldCupPredictionResult._(
      success: true,
      message: message,
      prediction: prediction,
    );
  }

  factory WorldCupPredictionResult.error(String error) {
    return WorldCupPredictionResult._(success: false, error: error);
  }
}
