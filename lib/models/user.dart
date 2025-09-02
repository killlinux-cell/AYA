class User {
  final String id;
  final String email;
  final String name;
  final int availablePoints;
  final int exchangedPoints;
  final int collectedQRCodes;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? personalQRCode; // QR code personnel pour l'identité

  User({
    required this.id,
    required this.email,
    required this.name,
    this.availablePoints = 0,
    this.exchangedPoints = 0,
    this.collectedQRCodes = 0,
    required this.createdAt,
    required this.lastLoginAt,
    this.personalQRCode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      availablePoints: json['availablePoints'] ?? 0,
      exchangedPoints: json['exchangedPoints'] ?? 0,
      collectedQRCodes: json['collectedQRCodes'] ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastLoginAt: DateTime.parse(
        json['lastLoginAt'] ?? DateTime.now().toIso8601String(),
      ),
      personalQRCode: json['personalQRCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'availablePoints': availablePoints,
      'exchangedPoints': exchangedPoints,
      'collectedQRCodes': collectedQRCodes,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'personalQRCode': personalQRCode,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    int? availablePoints,
    int? exchangedPoints,
    int? collectedQRCodes,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? personalQRCode,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      availablePoints: availablePoints ?? this.availablePoints,
      exchangedPoints: exchangedPoints ?? this.exchangedPoints,
      collectedQRCodes: collectedQRCodes ?? this.collectedQRCodes,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      personalQRCode: personalQRCode ?? this.personalQRCode,
    );
  }
}
