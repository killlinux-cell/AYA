import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'django_auth_service.dart';

class ExchangeTokenService {
  static final ExchangeTokenService _instance =
      ExchangeTokenService._internal();
  factory ExchangeTokenService() => _instance;
  ExchangeTokenService._internal();

  final DjangoAuthService _authService = DjangoAuthService.instance;
  static const String _baseUrl = DjangoConfig.qrUrl;

  /// Créer un token d'échange temporaire
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

  /// Valider un token d'échange
  Future<ExchangeValidationResult> validateExchangeToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/exchange-tokens/validate/'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.accessToken != null)
            'Authorization': 'Bearer ${_authService.accessToken}',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExchangeValidationResult.success(
          exchangeRequest: data['exchange_request'],
          message: data['message'],
        );
      } else {
        final errorData = jsonDecode(response.body);
        return ExchangeValidationResult.error(
          error: errorData['error'] ?? 'Erreur lors de la validation du token',
        );
      }
    } catch (e) {
      return ExchangeValidationResult.error(error: 'Erreur de connexion: $e');
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
