import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'django_auth_service.dart';
import 'vendor_auth_service.dart';

class ExchangeTokenService {
  static final ExchangeTokenService _instance =
      ExchangeTokenService._internal();
  factory ExchangeTokenService() => _instance;
  ExchangeTokenService._internal();

  final DjangoAuthService _authService = DjangoAuthService.instance;
  final VendorAuthService _vendorAuthService = VendorAuthService();
  static const String _baseUrl = DjangoConfig.qrUrl;

  /// Créer un token d'échange temporaire (utilisé par le client)
  Future<ExchangeTokenResult> createExchangeToken(int points) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/exchange-tokens/create/'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.accessToken != null)
            'Authorization': 'Bearer ${_authService.accessToken}',
        },
        body: jsonEncode({'points': points}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ExchangeTokenResult.success(
          token: data['token'].toString(),
          qrCodeData: data['qr_code_data'],
          expiresInMinutes: data['expires_in_minutes'],
          message: data['message'],
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ExchangeTokenResult.error(
          error: errorData['error'] ?? 'Erreur lors de la création du token',
          availablePoints: errorData['available_points'],
        );
      }
    } catch (e) {
      return ExchangeTokenResult.error(error: 'Erreur de connexion: $e');
    }
  }

  /// Valider un token d'échange (utilisé par le vendeur)
  /// Utilise l'authentification vendeur car seul un vendeur peut valider un échange
  Future<ExchangeValidationResult> validateExchangeToken(String token) async {
    try {
      // Utiliser le token vendeur pour l'authentification (les vendeurs ne sont pas authentifiés via DjangoAuthService)
      await _vendorAuthService.initialize();
      final headers = _vendorAuthService.getAuthHeaders();

      if (headers['Authorization'] == null) {
        return ExchangeValidationResult.error(
          error: 'Session vendeur expirée. Veuillez vous reconnecter.',
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/exchange-tokens/validate/'),
        headers: headers,
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExchangeValidationResult.success(
          exchangeRequest: data['exchange_request'],
          message: data['message'],
        );
      } else {
        String errorMessage = 'Erreur lors de la validation du token';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? errorData['detail'] ?? errorMessage;
        } catch (_) {
          if (response.statusCode == 401) {
            errorMessage = 'Session vendeur expirée. Veuillez vous reconnecter.';
          } else if (response.statusCode == 403) {
            errorMessage = 'Accès refusé. Vérifiez vos droits vendeur.';
          } else if (response.statusCode == 404) {
            errorMessage = 'Token invalide ou expiré. Le client doit générer un nouveau QR code.';
          }
        }
        return ExchangeValidationResult.error(error: errorMessage);
      }
    } catch (e) {
      return ExchangeValidationResult.error(
        error: 'Erreur de connexion: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }
}

class ExchangeTokenResult {
  final bool success;
  final String? token;
  final String? qrCodeData;
  final int? expiresInMinutes;
  final String? message;
  final String? error;
  final int? availablePoints;

  ExchangeTokenResult._({
    required this.success,
    this.token,
    this.qrCodeData,
    this.expiresInMinutes,
    this.message,
    this.error,
    this.availablePoints,
  });

  factory ExchangeTokenResult.success({
    required String token,
    required String qrCodeData,
    required int expiresInMinutes,
    required String message,
  }) {
    return ExchangeTokenResult._(
      success: true,
      token: token,
      qrCodeData: qrCodeData,
      expiresInMinutes: expiresInMinutes,
      message: message,
    );
  }

  factory ExchangeTokenResult.error({
    required String error,
    int? availablePoints,
  }) {
    return ExchangeTokenResult._(
      success: false,
      error: error,
      availablePoints: availablePoints,
    );
  }
}

class ExchangeValidationResult {
  final bool success;
  final Map<String, dynamic>? exchangeRequest;
  final String? message;
  final String? error;

  ExchangeValidationResult._({
    required this.success,
    this.exchangeRequest,
    this.message,
    this.error,
  });

  factory ExchangeValidationResult.success({
    required Map<String, dynamic> exchangeRequest,
    required String message,
  }) {
    return ExchangeValidationResult._(
      success: true,
      exchangeRequest: exchangeRequest,
      message: message,
    );
  }

  factory ExchangeValidationResult.error({required String error}) {
    return ExchangeValidationResult._(success: false, error: error);
  }
}
