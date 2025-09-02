class ExchangeRequest {
  final String id;
  final String userId;
  final int points;
  final String exchangeCode;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;

  ExchangeRequest({
    required this.id,
    required this.userId,
    required this.points,
    required this.exchangeCode,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
  });

  // Données pour le QR code
  String get qrCodeData {
    return 'EXCHANGE:$exchangeCode:$points:$userId';
  }

  // Date formatée
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} à ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  factory ExchangeRequest.fromJson(Map<String, dynamic> json) {
    return ExchangeRequest(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      points: json['points'] ?? 0,
      exchangeCode: json['exchange_code'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'exchange_code': exchangeCode,
      'created_at': createdAt.toIso8601String(),
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  ExchangeRequest copyWith({
    String? id,
    String? userId,
    int? points,
    String? exchangeCode,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return ExchangeRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      exchangeCode: exchangeCode ?? this.exchangeCode,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
