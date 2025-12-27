import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/auth_screen.dart';
import '../providers/auth_provider.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  /// Gérer les deep links entrants
  static Future<void> handleDeepLink(Uri uri, BuildContext context) async {
    try {
      print('Deep link reçu: $uri');

      // Gérer les URLs web (monuniversaya.com)
      if (uri.scheme == 'https' &&
          (uri.host == 'monuniversaya.com' ||
              uri.host == 'www.monuniversaya.com')) {
        if (uri.path.startsWith('/scan')) {
          final qrCode = uri.queryParameters['code'];
          if (qrCode != null) {
            await _processQRCode(qrCode, context);
          }
        }
        return;
      }

      // Gérer les deep links de l'app (aya-huile-app://)
      if (uri.scheme == 'aya-huile-app') {
        if (uri.host == 'qr') {
          final qrCode = uri.queryParameters['code'];
          if (qrCode != null) {
            await _processQRCode(qrCode, context);
          }
        } else if (uri.host == 'game') {
          final gameType = uri.queryParameters['type'];
          if (gameType != null) {
            await _navigateToGame(gameType, context);
          }
        } else if (uri.host == 'exchange') {
          final exchangeCode = uri.queryParameters['code'];
          if (exchangeCode != null) {
            await _navigateToExchange(exchangeCode, context);
          }
        }
      }
    } catch (e) {
      print('Erreur lors du traitement du deep link: $e');
    }
  }

  /// Traiter un QR code scanné
  static Future<void> _processQRCode(
    String qrCode,
    BuildContext context,
  ) async {
    try {
      // Vérifier si l'utilisateur est authentifié
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        // Rediriger vers l'écran d'authentification
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        return;
      }

      // Naviguer vers l'écran de scan avec le code pré-rempli
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QRScannerScreen(prefilledCode: qrCode),
        ),
      );
    } catch (e) {
      print('Erreur lors du traitement du QR code: $e');
    }
  }

  /// Naviguer vers un jeu spécifique
  static Future<void> _navigateToGame(
    String gameType,
    BuildContext context,
  ) async {
    try {
      // Navigation vers les jeux selon le type
      switch (gameType.toLowerCase()) {
        case 'scratch_win':
          // Naviguer vers Scratch & Win
          break;
        case 'spin_wheel':
          // Naviguer vers la Roue de la Chance
          break;
        default:
          // Naviguer vers l'écran des jeux
          break;
      }
    } catch (e) {
      print('Erreur lors de la navigation vers le jeu: $e');
    }
  }

  /// Naviguer vers un échange spécifique
  static Future<void> _navigateToExchange(
    String exchangeCode,
    BuildContext context,
  ) async {
    try {
      // Navigation vers l'écran d'échange avec le code pré-rempli
      // TODO: Implémenter la navigation vers l'écran d'échange
    } catch (e) {
      print('Erreur lors de la navigation vers l\'échange: $e');
    }
  }

  /// Rediriger vers l'App Store/Play Store si l'app n'est pas installée
  static Future<void> redirectToStore(String qrCode) async {
    try {
      // URL de la landing page qui gère la redirection
      final landingPageUrl = Uri.parse(
        'https://monuniversaya.com/scan?code=$qrCode',
      );

      if (await canLaunchUrl(landingPageUrl)) {
        await launchUrl(landingPageUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Erreur lors de la redirection vers le store: $e');
      // Fallback vers le Play Store direct
      await _redirectToPlayStoreDirect();
    }
  }

  /// Redirection directe vers le Play Store (fallback)
  static Future<void> _redirectToPlayStoreDirect() async {
    try {
      final url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.example.aya',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Erreur lors de la redirection directe vers le Play Store: $e');
    }
  }

  /// Ouvrir l'app directement si elle est installée
  static Future<void> openAppDirectly(String qrCode) async {
    try {
      // Essayer d'abord le deep link de l'app
      final appUrl = Uri.parse('aya-huile-app://qr?code=$qrCode');

      if (await canLaunchUrl(appUrl)) {
        await launchUrl(appUrl);
        return;
      }

      // Si l'app n'est pas installée, rediriger vers la landing page
      await redirectToStore(qrCode);
    } catch (e) {
      print('Erreur lors de l\'ouverture directe de l\'app: $e');
      // Fallback vers la landing page
      await redirectToStore(qrCode);
    }
  }

  /// Générer un deep link pour un QR code
  static String generateQRCodeDeepLink(String qrCode) {
    return 'aya-huile-app://qr?code=$qrCode';
  }

  /// Générer une URL web pour un QR code (pour nouveaux utilisateurs)
  static String generateQRCodeWebUrl(String qrCode) {
    return 'https://monuniversaya.com/scan?code=$qrCode';
  }

  /// Générer un deep link pour un jeu
  static String generateGameDeepLink(String gameType) {
    return 'aya-huile-app://game?type=$gameType';
  }

  /// Générer un deep link pour un échange
  static String generateExchangeDeepLink(String exchangeCode) {
    return 'aya-huile-app://exchange?code=$exchangeCode';
  }

  /// Vérifier si un deep link est valide
  static bool isValidDeepLink(Uri uri) {
    return uri.scheme == 'aya-huile-app' &&
        ['qr', 'game', 'exchange'].contains(uri.host);
  }
}
