import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart' as app_user;
import '../models/qr_code.dart';
import '../config/django_config.dart';
import 'django_auth_service.dart';

class DjangoUserService {
  static const String baseUrl = DjangoConfig.qrUrl;
  final DjangoAuthService _authService;

  DjangoUserService(this._authService);

  // Constructeur par défaut utilisant l'instance singleton
  DjangoUserService.singleton() : _authService = DjangoAuthService.instance;

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  Future<app_user.User?> getUserData(String userId) async {
    try {
      // Utiliser l'instance AuthService passée au constructeur
      final user = _authService.currentUser;
      if (user != null) {
        print(
          '✅ Données utilisateur récupérées depuis AuthService: ${user.email}',
        );
        return user;
      }

      print('❌ Aucun utilisateur trouvé dans AuthService');
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  Future<String?> getPersonalQRCode(String userId) async {
    try {
      print(
        '🔍 Tentative de récupération du QR code personnel pour l\'utilisateur: $userId',
      );

      // Utiliser l'instance AuthService passée au constructeur
      final user = _authService.currentUser;

      print('🔍 Utilisateur actuel dans AuthService: ${user?.email}');
      print('🔍 QR code personnel dans AuthService: ${user?.personalQRCode}');
      print('🔍 QR code est null: ${user?.personalQRCode == null}');
      print('🔍 QR code est vide: ${user?.personalQRCode?.isEmpty ?? true}');

      if (user != null &&
          user.personalQRCode != null &&
          user.personalQRCode!.isNotEmpty) {
        print(
          '✅ QR code personnel récupéré depuis AuthService: ${user.personalQRCode}',
        );
        return user.personalQRCode;
      }

      print('❌ Aucun QR code personnel trouvé pour l\'utilisateur: $userId');
      print(
        '❌ Détails: user=${user != null}, personalQRCode=${user?.personalQRCode}',
      );
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération du QR code personnel: $e');
      return null;
    }
  }

  Future<app_user.User?> verifyUserByQRCode(String personalQRCode) async {
    try {
      // Cette fonctionnalité nécessiterait un endpoint spécifique côté Django
      // Pour l'instant, on simule la vérification
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = _convertDjangoUserToAppUser(data);
        if (user.personalQRCode == personalQRCode) {
          return user;
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification du QR code: $e');
    }
    return null;
  }

  Future<void> updateUserPoints(
    String userId,
    int availablePoints,
    int exchangedPoints,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile/update/'),
        headers: _authHeaders,
        body: jsonEncode({
          'available_points': availablePoints,
          'exchanged_points': exchangedPoints,
        }),
      );

      if (response.statusCode == 200) {
        print('Points utilisateur mis à jour avec succès');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des points: $e');
    }
  }

  Future<void> addQRCode(String userId, QRCode qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate/'),
        headers: _authHeaders,
        body: jsonEncode({'code': qrCode.code}),
      );

      if (response.statusCode == 200) {
        print('QR code ajouté avec succès');
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du QR code: $e');
    }
  }

  Future<List<QRCode>> getUserQRCodes(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-codes/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> qrCodesData = data['results'] ?? data;

        return qrCodesData
            .map(
              (qrData) => QRCode(
                id: qrData['id'] ?? '',
                code: qrData['qr_code']['code'] ?? '',
                points: qrData['points_earned'] ?? 0,
                collectedAt: qrData['scanned_at'] != null
                    ? DateTime.parse(qrData['scanned_at'])
                    : DateTime.now(),
                description: qrData['qr_code']['description'] ?? '',
              ),
            )
            .toList();
      }
    } catch (e) {
      print('Erreur lors de la récupération des QR codes: $e');
    }
    return [];
  }

  Future<bool> hasQRCode(String userId, String qrCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-codes/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> qrCodesData = data['results'] ?? data;

        return qrCodesData.any((qrData) => qrData['qr_code']['code'] == qrCode);
      }
    } catch (e) {
      print('Erreur lors de la vérification du QR code: $e');
    }
    return false;
  }

  // Récupérer les statistiques utilisateur
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
    }
    return null;
  }

  // Convertir les données utilisateur Django vers notre modèle
  app_user.User _convertDjangoUserToAppUser(Map<String, dynamic> data) {
    return app_user.User(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      name: '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim(),
      availablePoints: data['available_points'] ?? 0,
      exchangedPoints: data['exchanged_points'] ?? 0,
      collectedQRCodes: data['collected_qr_codes'] ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      lastLoginAt: data['last_login_at'] != null
          ? DateTime.parse(data['last_login_at'])
          : DateTime.now(),
      personalQRCode: data['personal_qr_code'] ?? '',
    );
  }
}
