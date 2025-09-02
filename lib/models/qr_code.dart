class QRCode {
  final String id;
  final String code;
  final int points;
  final DateTime collectedAt;
  final String? description;
  final bool isActive;

  QRCode({
    required this.id,
    required this.code,
    required this.points,
    required this.collectedAt,
    this.description,
    this.isActive = true,
  });

  factory QRCode.fromJson(Map<String, dynamic> json) {
    return QRCode(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      points: json['points'] ?? 0,
      collectedAt: DateTime.parse(json['collectedAt'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'points': points,
      'collectedAt': collectedAt.toIso8601String(),
      'description': description,
      'isActive': isActive,
    };
  }
}
