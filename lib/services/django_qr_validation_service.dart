import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/qr_code.dart';
import '../config/django_config.dart';
import 'django_auth_service.dart';

class DjangoQRValidationService {
  static const String baseUrl = DjangoConfig.qrUrl;
  final DjangoAuthService _authService;

  DjangoQRValidationService(this._authService);

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  static Future<QRValidationResult> validateQRCode(String qrCode) async {
    // Cette méthode statique est maintenue pour la compatibilité
    // mais elle nécessite une instance d'auth service
    throw UnimplementedError('Utilisez validateQRCodeWithAuth à la place');
  }

  Future<QRValidationResult> validateQRCodeWithAuth(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate/'),
        headers: _authHeaders,
        body: jsonEncode({'code': qrCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['is_valid'] == true) {
          final qrCodeData = data['qr_code'];
          return QRValidationResult(
            isValid: true,
            qrCode: QRCode(
              id: qrCodeData['id'] ?? '',
              code: qrCodeData['code'] ?? '',
              points: qrCodeData['points'] ?? 0,
              collectedAt: DateTime.now(),
              description: qrCodeData['description'] ?? '',
              isActive: qrCodeData['is_active'] ?? true,
            ),
            prizeType: _determinePrizeType(
              qrCodeData['points'] ?? 0,
              qrCodeData['prize_type'],
            ),
            message: data['message'] ?? 'QR code validé avec succès !',
          );
        } else {
          return QRValidationResult(
            isValid: false,
            error: data['error'] ?? 'QR code invalide',
            errorType: _mapErrorType(data['error_type']),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        return QRValidationResult(
          isValid: false,
          error: errorData['error'] ?? 'Erreur de validation',
          errorType: QRValidationError.serverError,
        );
      }
    } catch (e) {
      print('Erreur lors de la validation du QR code: $e');
      return QRValidationResult(
        isValid: false,
        error: 'Erreur de connexion',
        errorType: QRValidationError.networkError,
      );
    }
  }

  Future<bool> markQRCodeAsUsed(String qrCodeId, String userId) async {
    // Django gère automatiquement le marquage des QR codes comme utilisés
    // lors de la validation, donc cette méthode est principalement pour la compatibilité
    return true;
  }

  Future<bool> hasUserScannedQRCode(String userId, String qrCode) async {
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
      print('Erreur lors de la vérification du QR code scanné: $e');
    }
    return false;
  }

  // Déterminer le type de prix basé sur les points et le prize_type
  String _determinePrizeType(int points, String? prizeType) {
    // Si c'est un QR code spécial, retourner le type correspondant
    if (prizeType == 'loyalty_bonus') return 'loyalty_bonus';
    if (prizeType == 'try_again') return 'try_again';
    if (prizeType == 'mystery_box') return 'mystery_box';

    // Sinon, déterminer basé sur les points
    if (points >= 100) return 'big_prize';
    if (points >= 50) return 'medium_prize';
    if (points >= 20) return 'small_prize';
    return 'mini_prize';
  }

  // Mapper les types d'erreur Django vers nos types d'erreur
  QRValidationError _mapErrorType(String? errorType) {
    switch (errorType) {
      case 'already_used':
        return QRValidationError.alreadyUsed;
      case 'expired':
        return QRValidationError.expired;
      case 'invalid_code':
        return QRValidationError.invalidCode;
      default:
        return QRValidationError.serverError;
    }
  }
}

class QRValidationResult {
  final bool isValid;
  final QRCode? qrCode;
  final String? error;
  final QRValidationError? errorType;
  final String? prizeType;
  final String? message;

  QRValidationResult({
    required this.isValid,
    this.qrCode,
    this.error,
    this.errorType,
    this.prizeType,
    this.message,
  });
}

enum QRValidationError {
  invalidCode,
  alreadyUsed,
  expired,
  serverError,
  networkError,
}
