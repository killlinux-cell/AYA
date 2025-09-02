class GameData {
  final String id;
  final String userId;
  final String gameType;
  final int pointsEarned;
  final int score;
  final DateTime playedAt;
  final Map<String, dynamic>? gameDetails;

  GameData({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.pointsEarned,
    required this.score,
    required this.playedAt,
    this.gameDetails,
  });

  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gameType: json['game_type'] as String,
      pointsEarned: json['points_earned'] as int,
      score: json['score'] as int,
      playedAt: DateTime.parse(json['played_at'] as String),
      gameDetails: json['game_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_type': gameType,
      'points_earned': pointsEarned,
      'score': score,
      'played_at': playedAt.toIso8601String(),
      'game_details': gameDetails,
    };
  }

  GameData copyWith({
    String? id,
    String? userId,
    String? gameType,
    int? pointsEarned,
    int? score,
    DateTime? playedAt,
    Map<String, dynamic>? gameDetails,
  }) {
    return GameData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gameType: gameType ?? this.gameType,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      score: score ?? this.score,
      playedAt: playedAt ?? this.playedAt,
      gameDetails: gameDetails ?? this.gameDetails,
    );
  }
}

