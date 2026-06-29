class WorldCupMatch {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamCode;
  final String? awayTeamCode;
  final DateTime kickoffAt;
  final String stage;
  final String? groupName;
  final int? homeScore;
  final int? awayScore;
  final bool isFinished;
  final bool predictionsOpen;
  final WorldCupPrediction? userPrediction;

  WorldCupMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamCode,
    this.awayTeamCode,
    required this.kickoffAt,
    required this.stage,
    this.groupName,
    this.homeScore,
    this.awayScore,
    this.isFinished = false,
    this.predictionsOpen = true,
    this.userPrediction,
  });

  factory WorldCupMatch.fromJson(Map<String, dynamic> json) {
    return WorldCupMatch(
      id: json['id']?.toString() ?? '',
      homeTeam: json['home_team'] ?? json['home_team_name'] ?? 'Équipe A',
      awayTeam: json['away_team'] ?? json['away_team_name'] ?? 'Équipe B',
      homeTeamCode: json['home_team_code'],
      awayTeamCode: json['away_team_code'],
      kickoffAt: _parseKickoffAt(json['kickoff_at']),
      stage: json['stage'] ?? json['phase'] ?? 'Groupe',
      groupName: json['group'] ?? json['group_name'],
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      isFinished: json['is_finished'] == true || json['status'] == 'finished',
      predictionsOpen:
          json['predictions_open'] != false && json['status'] != 'finished',
      userPrediction: json['user_prediction'] != null
          ? WorldCupPrediction.fromJson(
              json['user_prediction'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get canPredict =>
      predictionsOpen &&
      !isFinished &&
      DateTime.now().toUtc().isBefore(kickoffAt.toUtc());

  String get formattedDate {
    final d = kickoffAt.toUtc();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  /// Heure Abidjan (GMT+0) — telle que saisie dans le dashboard.
  static DateTime _parseKickoffAt(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return DateTime.now().toUtc();
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return DateTime.now().toUtc();
    if (parsed.isUtc) return parsed;
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
  }
}

class WorldCupPrediction {
  final String? id;
  final String matchId;
  final int homeScore;
  final int awayScore;
  final int? pointsEarned;
  final DateTime? createdAt;

  WorldCupPrediction({
    this.id,
    required this.matchId,
    required this.homeScore,
    required this.awayScore,
    this.pointsEarned,
    this.createdAt,
  });

  factory WorldCupPrediction.fromJson(Map<String, dynamic> json) {
    return WorldCupPrediction(
      id: json['id']?.toString(),
      matchId: json['match_id']?.toString() ?? json['match']?.toString() ?? '',
      homeScore: (json['home_score'] as num?)?.toInt() ?? 0,
      awayScore: (json['away_score'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['points_earned'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
    );
  }

  String get scoreLabel => '$homeScore - $awayScore';
}

class WorldCupRankingEntry {
  final int rank;
  final String userId;
  final String displayName;
  final int totalPoints;
  final int exactScores;
  final int correctOutcomes;
  final bool isCurrentUser;

  WorldCupRankingEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.totalPoints,
    this.exactScores = 0,
    this.correctOutcomes = 0,
    this.isCurrentUser = false,
  });

  factory WorldCupRankingEntry.fromJson(Map<String, dynamic> json) {
    return WorldCupRankingEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['user_id']?.toString() ?? '',
      displayName:
          json['display_name'] ?? json['user_name'] ?? json['name'] ?? 'Joueur',
      totalPoints: (json['total_points'] as num?)?.toInt() ??
          (json['points'] as num?)?.toInt() ??
          0,
      exactScores: (json['exact_scores'] as num?)?.toInt() ?? 0,
      correctOutcomes: (json['correct_outcomes'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['is_current_user'] == true,
    );
  }
}
