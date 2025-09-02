class QRCodeData {
  final String id;
  final String userId;
  final String qrCodeId;
  final int pointsEarned;
  final DateTime scannedAt;
  final String? location;
  final Map<String, dynamic>? scanDetails;

  QRCodeData({
    required this.id,
    required this.userId,
    required this.qrCodeId,
    required this.pointsEarned,
    required this.scannedAt,
    this.location,
    this.scanDetails,
  });

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      qrCodeId: json['qr_code_id'] as String,
      pointsEarned: json['points_earned'] as int,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      location: json['location'] as String?,
      scanDetails: json['scan_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'qr_code_id': qrCodeId,
      'points_earned': pointsEarned,
      'scanned_at': scannedAt.toIso8601String(),
      'location': location,
      'scan_details': scanDetails,
    };
  }

  QRCodeData copyWith({
    String? id,
    String? userId,
    String? qrCodeId,
    int? pointsEarned,
    DateTime? scannedAt,
    String? location,
    Map<String, dynamic>? scanDetails,
  }) {
    return QRCodeData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      scannedAt: scannedAt ?? this.scannedAt,
      location: location ?? this.location,
      scanDetails: scanDetails ?? this.scanDetails,
    );
  }
}

