import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/qr_code.dart';
import '../config/django_config.dart';
import 'django_auth_service.dart';

class QRPrizeService {
  final DjangoAuthService _authService;

  QRPrizeService(this._authService);

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  /// Extraire le code QR d'une URL ou retourner le code tel quel
  String _extractCodeFromQR(String qrData) {
    // Si c'est une URL, extraire le paramètre 'code'
    if (qrData.startsWith('http')) {
      try {
        final uri = Uri.parse(qrData);
        final code = uri.queryParameters['code'];
        if (code != null && code.isNotEmpty) {
          print('🔗 URL détectée, code extrait: $code');
          return code;
        }
      } catch (e) {
        print('⚠️ Erreur lors de l\'extraction de l\'URL: $e');
      }
    }

    // Sinon, retourner le code tel quel
    print('📝 Code direct: $qrData');
    return qrData;
  }

  /// Valider un QR code et récupérer la récompense
  Future<QRPrizeResult> validateAndClaimPrize(String qrCode) async {
    try {
      // Extraire le code de l'URL si nécessaire
      final extractedCode = _extractCodeFromQR(qrCode);
      print('🎯 Validation du QR code: $extractedCode');

      final response = await http.post(
        Uri.parse('${DjangoConfig.qrUrl}/validate-and-claim/'),
        headers: _authHeaders,
        body: jsonEncode({'code': extractedCode}),
      );

      print('📡 Réponse du serveur: ${response.statusCode}');
      print('📄 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final qrCodeData = data['qr_code'];
          final prizeData = data['prize'];

          return QRPrizeResult(
            success: true,
            qrCode: QRCode(
              id: qrCodeData['id'] ?? '',
              code: qrCodeData['code'] ?? '',
              points: qrCodeData['points'] ?? 0,
              collectedAt: DateTime.now(),
              description: qrCodeData['description'] ?? '',
              isActive: qrCodeData['is_active'] ?? true,
            ),
            prize: Prize(
              type: prizeData['type'] ?? 'points',
              value: prizeData['value'] ?? 0,
              description: prizeData['description'] ?? '',
              isLoyaltyTicket: prizeData['is_loyalty_ticket'] ?? false,
            ),
            message: data['message'] ?? 'Félicitations ! Vous avez gagné !',
            userPoints: data['user_points'] ?? 0,
            qrCodesCollected: data['qr_codes_collected'] ?? 0,
          );
        } else {
          return QRPrizeResult(
            success: false,
            error: data['error'] ?? 'QR code invalide',
            errorType: _mapErrorType(data['error_type']),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        return QRPrizeResult(
          success: false,
          error: errorData['error'] ?? 'Erreur de validation',
          errorType: QRPrizeError.serverError,
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la validation du QR code: $e');
      return QRPrizeResult(
        success: false,
        error: 'Erreur de connexion',
        errorType: QRPrizeError.networkError,
      );
    }
  }

  /// Mettre à jour les données utilisateur après un gain
  Future<void> updateUserDataAfterPrize(String userId, int pointsEarned) async {
    try {
      print('🔄 Mise à jour des données utilisateur...');
      // L'API backend gère déjà la mise à jour des points
      print('✅ Données utilisateur mises à jour via l\'API backend');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des données utilisateur: $e');
    }
  }

  /// Vérifier si un utilisateur a déjà scanné un QR code
  Future<bool> hasUserScannedQRCode(String userId, String qrCode) async {
    try {
      final response = await http.get(
        Uri.parse('${DjangoConfig.qrUrl}/user-codes/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> qrCodesData = data['results'] ?? data;

        return qrCodesData.any((qrData) => qrData['qr_code']['code'] == qrCode);
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du QR code scanné: $e');
    }
    return false;
  }

  /// Obtenir l'historique des gains d'un utilisateur
  Future<List<PrizeHistory>> getUserPrizeHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${DjangoConfig.qrUrl}/user-codes/'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> prizesData = data['results'] ?? data;

        return prizesData
            .map(
              (prizeData) => PrizeHistory(
                id: prizeData['id'] ?? '',
                qrCode: prizeData['qr_code']['code'] ?? '',
                prizeType: prizeData['prize_type'] ?? 'points',
                prizeValue: prizeData['prize_value'] ?? 0,
                claimedAt: DateTime.parse(
                  prizeData['claimed_at'] ?? DateTime.now().toIso8601String(),
                ),
                description: prizeData['description'] ?? '',
              ),
            )
            .toList();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'historique des gains: $e');
    }
    return [];
  }

  /// Mapper les types d'erreur
  QRPrizeError _mapErrorType(String? errorType) {
    switch (errorType) {
      case 'already_used':
        return QRPrizeError.alreadyUsed;
      case 'expired':
        return QRPrizeError.expired;
      case 'invalid_code':
        return QRPrizeError.invalidCode;
      case 'not_authenticated':
        return QRPrizeError.notAuthenticated;
      default:
        return QRPrizeError.serverError;
    }
  }
}

/// Résultat de la validation et réclamation d'un prix
class QRPrizeResult {
  final bool success;
  final QRCode? qrCode;
  final Prize? prize;
  final String? error;
  final QRPrizeError? errorType;
  final String? message;
  final int? userPoints;
  final int? qrCodesCollected;

  QRPrizeResult({
    required this.success,
    this.qrCode,
    this.prize,
    this.error,
    this.errorType,
    this.message,
    this.userPoints,
    this.qrCodesCollected,
  });
}

/// Modèle pour une récompense
class Prize {
  final String type; // 'points', 'loyalty_ticket', 'discount', etc.
  final int value;
  final String description;
  final bool isLoyaltyTicket;

  Prize({
    required this.type,
    required this.value,
    required this.description,
    this.isLoyaltyTicket = false,
  });

  String get displayValue {
    if (isLoyaltyTicket) {
      return 'Ticket Fidélité';
    }
    return '$value points';
  }

  String get emoji {
    switch (type) {
      case 'loyalty_ticket':
        return '🎫';
      case 'points':
        if (value >= 100) return '🏆';
        if (value >= 50) return '🎊';
        if (value >= 20) return '🎈';
        return '⭐';
      default:
        return '🎁';
    }
  }

  Color get color {
    switch (type) {
      case 'loyalty_ticket':
        return const Color(0xFFFF9800);
      case 'points':
        if (value >= 100) return const Color(0xFF9C27B0);
        if (value >= 50) return const Color(0xFF488950);
        if (value >= 20) return const Color(0xFF2196F3);
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF607D8B);
    }
  }
}

/// Historique des gains
class PrizeHistory {
  final String id;
  final String qrCode;
  final String prizeType;
  final int prizeValue;
  final DateTime claimedAt;
  final String description;

  PrizeHistory({
    required this.id,
    required this.qrCode,
    required this.prizeType,
    required this.prizeValue,
    required this.claimedAt,
    required this.description,
  });
}

/// Types d'erreur pour les prix QR
enum QRPrizeError {
  invalidCode,
  alreadyUsed,
  expired,
  notAuthenticated,
  serverError,
  networkError,
}
