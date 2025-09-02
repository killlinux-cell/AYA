class GameHistory {
  final String id;
  final String userId;
  final String gameType;
  final int pointsSpent;
  final int pointsWon;
  final DateTime playedAt;
  final bool isWinning;

  GameHistory({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.pointsSpent,
    required this.pointsWon,
    required this.playedAt,
    required this.isWinning,
  });

  factory GameHistory.fromJson(Map<String, dynamic> json) {
    return GameHistory(
      id: json['id'],
      userId: json['user_id'],
      gameType: json['game_type'],
      pointsSpent: json['points_spent'],
      pointsWon: json['points_won'],
      playedAt: DateTime.parse(json['played_at']),
      isWinning: json['is_winning'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'game_type': gameType,
      'points_spent': pointsSpent,
      'points_won': pointsWon,
      'played_at': playedAt.toIso8601String(),
      'is_winning': isWinning,
    };
  }

  @override
  String toString() {
    return 'GameHistory(id: $id, userId: $userId, gameType: $gameType, pointsSpent: $pointsSpent, pointsWon: $pointsWon, playedAt: $playedAt, isWinning: $isWinning)';
  }
}
