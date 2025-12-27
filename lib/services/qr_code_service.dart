import 'deep_link_service.dart';

class QRCodeService {
  static final QRCodeService _instance = QRCodeService._internal();
  factory QRCodeService() => _instance;
  QRCodeService._internal();

  /// Générer une URL pour un QR code
  /// Cette URL fonctionne pour les nouveaux utilisateurs (redirection vers stores)
  /// et pour les utilisateurs existants (ouverture directe de l'app)
  static String generateQRCodeUrl(String qrCode) {
    return DeepLinkService.generateQRCodeWebUrl(qrCode);
  }

  /// Générer un deep link direct pour l'app
  /// Utilisé uniquement pour les utilisateurs qui ont déjà l'app installée
  static String generateAppDeepLink(String qrCode) {
    return DeepLinkService.generateQRCodeDeepLink(qrCode);
  }

  /// Valider un code QR
  static bool isValidQRCode(String qrCode) {
    if (qrCode.isEmpty) return false;

    // Vérifier que le code contient uniquement des caractères alphanumériques
    final regex = RegExp(r'^[a-zA-Z0-9_-]+$');
    return regex.hasMatch(qrCode);
  }

  /// Extraire le code QR d'une URL
  static String? extractQRCodeFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Vérifier si c'est une URL de notre landing page
      if (uri.scheme == 'https' && uri.host == 'aya-app.com') {
        if (uri.path.startsWith('/scan')) {
          return uri.queryParameters['code'];
        }
      }

      // Vérifier si c'est un deep link de l'app
      if (uri.scheme == 'aya-huile-app' && uri.host == 'qr') {
        return uri.queryParameters['code'];
      }

      return null;
    } catch (e) {
      print('Erreur lors de l\'extraction du code QR: $e');
      return null;
    }
  }

  /// Générer un code QR unique
  static String generateUniqueQRCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString().padLeft(6, '0');
    return 'AYA_${timestamp}_$random';
  }

  /// Formater un code QR pour l'affichage
  static String formatQRCodeForDisplay(String qrCode) {
    if (qrCode.length <= 20) return qrCode;

    final start = qrCode.substring(0, 8);
    final end = qrCode.substring(qrCode.length - 8);
    return '$start...$end';
  }
}
