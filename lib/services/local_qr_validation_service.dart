import '../models/qr_code.dart';
import 'dart:math';

class LocalQRValidationService {
  // Liste de QR codes de démonstration
  static final List<Map<String, dynamic>> _demoQRCodes = [
    {
      'id': 'qr_001',
      'code': 'DEMO_QR_001',
      'points': 25,
      'description': 'QR Code de démonstration - 25 points',
      'is_active': true,
      'expires_at': null,
    },
    {
      'id': 'qr_002',
      'code': 'DEMO_QR_002',
      'points': 50,
      'description': 'QR Code de démonstration - 50 points',
      'is_active': true,
      'expires_at': null,
    },
    {
      'id': 'qr_003',
      'code': 'DEMO_QR_003',
      'points': 10,
      'description': 'QR Code de démonstration - 10 points',
      'is_active': true,
      'expires_at': null,
    },
  ];

  static final Set<String> _usedQRCodes = <String>{};

  /// Valider un QR code scanné
  /// Retourne les détails du QR code si valide, null si invalide
  static Future<QRValidationResult> validateQRCode(String qrCode) async {
    try {
      print('LocalQRValidationService: Validating QR code: $qrCode');

      // Simulation d'un délai réseau
      await Future.delayed(const Duration(milliseconds: 500));

      // 1. Vérifier si le QR code existe dans notre liste de démo
      final qrData = _demoQRCodes.firstWhere(
        (qr) => qr['code'] == qrCode && qr['is_active'] == true,
        orElse: () => {},
      );

      if (qrData.isEmpty) {
        print('LocalQRValidationService: QR code not found in demo list');
        return QRValidationResult(
          isValid: false,
          error: 'QR code invalide ou introuvable',
          errorType: QRValidationError.invalidCode,
        );
      }

      // 2. Vérifier si le QR code n'a pas déjà été utilisé
      if (_usedQRCodes.contains(qrCode)) {
        print('LocalQRValidationService: QR code already used');
        return QRValidationResult(
          isValid: false,
          error: 'Ce QR code a déjà été utilisé',
          errorType: QRValidationError.alreadyUsed,
        );
      }

      // 3. Vérifier si le QR code n'a pas expiré
      final expiresAt = qrData['expires_at'];
      if (expiresAt != null) {
        final expirationDate = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expirationDate)) {
          print('LocalQRValidationService: QR code expired');
          return QRValidationResult(
            isValid: false,
            error: 'Ce QR code a expiré',
            errorType: QRValidationError.expired,
          );
        }
      }

      // 4. QR code valide - retourner les détails
      final qrCodeData = QRCode(
        id: qrData['id'],
        code: qrData['code'],
        points: qrData['points'] ?? 0,
        collectedAt: DateTime.now(),
        description: qrData['description'] ?? 'Code QR collecté',
        isActive: qrData['is_active'] ?? true,
      );

      print(
        'LocalQRValidationService: QR code is valid - ${qrCodeData.points} points',
      );

      return QRValidationResult(
        isValid: true,
        qrCode: qrCodeData,
        prizeType: _determinePrizeType(qrCodeData.points),
        message: _generateSuccessMessage(qrCodeData.points),
      );
    } catch (e) {
      print('LocalQRValidationService: Error validating QR code: $e');
      return QRValidationResult(
        isValid: false,
        error: 'Erreur lors de la validation du QR code',
        errorType: QRValidationError.serverError,
      );
    }
  }

  /// Marquer un QR code comme utilisé
  static Future<bool> markQRCodeAsUsed(String qrCodeId, String userId) async {
    try {
      // Simulation d'un délai réseau
      await Future.delayed(const Duration(milliseconds: 300));

      // Trouver le QR code dans notre liste
      final qrData = _demoQRCodes.firstWhere(
        (qr) => qr['id'] == qrCodeId,
        orElse: () => {},
      );

      if (qrData.isNotEmpty) {
        _usedQRCodes.add(qrData['code']);
        print(
          'LocalQRValidationService: QR code marked as used for user: $userId',
        );
        return true;
      }

      return false;
    } catch (e) {
      print('LocalQRValidationService: Error marking QR code as used: $e');
      return false;
    }
  }

  /// Déterminer le type de prix selon les points
  static String _determinePrizeType(int points) {
    if (points >= 100) return 'grand_prize';
    if (points >= 50) return 'medium_prize';
    if (points >= 10) return 'small_prize';
    return 'loyalty_ticket';
  }

  /// Générer un message de succès personnalisé
  static String _generateSuccessMessage(int points) {
    if (points >= 100) {
      return '🎉 Félicitations ! Vous avez gagné $points points ! C\'est un grand prix !';
    } else if (points >= 50) {
      return '🎊 Excellent ! Vous avez gagné $points points !';
    } else if (points >= 10) {
      return '🎈 Bravo ! Vous avez gagné $points points !';
    } else {
      return '🎫 Parfait ! Vous avez gagné un ticket de fidélité !';
    }
  }

  /// Vérifier si un utilisateur a déjà scanné un QR code spécifique
  static Future<bool> hasUserScannedQRCode(String userId, String qrCode) async {
    try {
      // Simulation d'un délai réseau
      await Future.delayed(const Duration(milliseconds: 200));
      return _usedQRCodes.contains(qrCode);
    } catch (e) {
      print(
        'LocalQRValidationService: Error checking if user has scanned QR code: $e',
      );
      return false;
    }
  }

  /// Générer un QR code aléatoire pour les tests
  static String generateRandomQRCode() {
    final random = Random();
    final qrCodes = ['DEMO_QR_001', 'DEMO_QR_002', 'DEMO_QR_003'];
    return qrCodes[random.nextInt(qrCodes.length)];
  }
}

/// Résultat de la validation d'un QR code
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

/// Types d'erreurs de validation
enum QRValidationError {
  invalidCode,
  alreadyUsed,
  expired,
  serverError,
  networkError,
}

/// Types de prix
enum PrizeType {
  grandPrize, // 100+ points
  mediumPrize, // 50-99 points
  smallPrize, // 10-49 points
  loyaltyTicket, // < 10 points
}
