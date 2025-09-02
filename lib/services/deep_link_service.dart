import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/qr_scanner_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  /// Gérer les deep links entrants
  static Future<void> handleDeepLink(Uri uri, BuildContext context) async {
    try {
      print('Deep link reçu: $uri');

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
      // Naviguer vers l'écran de scan
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const QRScannerScreen()));
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
      final url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.aya.huile',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Erreur lors de la redirection vers le store: $e');
    }
  }

  /// Ouvrir l'app directement si elle est installée
  static Future<void> openAppDirectly(String qrCode) async {
    try {
      final url = Uri.parse('aya://qr?code=$qrCode');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Si l'app n'est pas installée, rediriger vers le store
        await redirectToStore(qrCode);
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture directe de l\'app: $e');
    }
  }

  /// Générer un deep link pour un QR code
  static String generateQRCodeDeepLink(String qrCode) {
    return 'aya://qr?code=$qrCode';
  }

  /// Générer un deep link pour un jeu
  static String generateGameDeepLink(String gameType) {
    return 'aya://game?type=$gameType';
  }

  /// Générer un deep link pour un échange
  static String generateExchangeDeepLink(String exchangeCode) {
    return 'aya://exchange?code=$exchangeCode';
  }

  /// Vérifier si un deep link est valide
  static bool isValidDeepLink(Uri uri) {
    return uri.scheme == 'aya' && ['qr', 'game', 'exchange'].contains(uri.host);
  }
}
