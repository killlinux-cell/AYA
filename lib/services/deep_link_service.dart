import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../screens/qr_scanner_screen.dart';
import 'vendor_auth_service.dart';

/// Clé de navigation globale pour ouvrir le scanner depuis un deep link.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class DeepLinkService {
  DeepLinkService._();

  static const _pendingQrKey = 'pending_qr_code';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.uborasoftware.aya';
  static const appStoreUrl =
      'https://apps.apple.com/us/app/ayamonunivers/id6757622625';

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;
  static bool _initialized = false;
  static bool _consuming = false;

  /// Capture le lien de lancement puis écoute les liens suivants.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _storeQrFromUri(initial);
      }
    } catch (e) {
      debugPrint('Deep link initial indisponible: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        await _storeQrFromUri(uri);
        await consumePendingQr();
      },
      onError: (Object e) {
        debugPrint('Erreur stream deep link: $e');
      },
    );
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  static Future<void> _storeQrFromUri(Uri uri) async {
    final qrCode = extractQrCode(uri);
    if (qrCode == null || qrCode.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingQrKey, qrCode);
  }

  /// Extrait le code QR d'un lien https://monuniversaya.com/scan ou aya-huile-app://
  static String? extractQrCode(Uri uri) {
    if (uri.scheme == 'https' &&
        (uri.host == 'monuniversaya.com' ||
            uri.host == 'www.monuniversaya.com') &&
        uri.path.startsWith('/scan')) {
      return uri.queryParameters['code'];
    }

    if (uri.scheme == 'aya-huile-app' && uri.host == 'qr') {
      return uri.queryParameters['code'];
    }

    return null;
  }

  /// Si un QR est en attente et l'utilisateur est connecté, ouvre le scanner.
  static Future<void> consumePendingQr() async {
    if (_consuming) return;
    _consuming = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final qrCode = prefs.getString(_pendingQrKey);
      if (qrCode == null || qrCode.isEmpty) return;

      if (VendorAuthService().isAuthenticated) return;

      final context = appNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) return;

      await prefs.remove(_pendingQrKey);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QRScannerScreen(prefilledCode: qrCode),
        ),
      );
    } catch (e) {
      debugPrint('Erreur traitement QR deep link: $e');
    } finally {
      _consuming = false;
    }
  }

  static Future<void> handleDeepLink(Uri uri, BuildContext context) async {
    await _storeQrFromUri(uri);
    await consumePendingQr();
  }

  static Future<void> redirectToStore(String qrCode) async {
    final landingPageUrl = Uri.parse(
      'https://monuniversaya.com/scan?code=$qrCode',
    );
    if (await canLaunchUrl(landingPageUrl)) {
      await launchUrl(landingPageUrl, mode: LaunchMode.externalApplication);
    }
  }

  static String generateQRCodeDeepLink(String qrCode) {
    return 'aya-huile-app://qr?code=$qrCode';
  }

  static String generateQRCodeWebUrl(String qrCode) {
    return 'https://monuniversaya.com/scan?code=$qrCode';
  }

  static String generateGameDeepLink(String gameType) {
    return 'aya-huile-app://game?type=$gameType';
  }

  static String generateExchangeDeepLink(String exchangeCode) {
    return 'aya-huile-app://exchange?code=$exchangeCode';
  }

  static bool isValidDeepLink(Uri uri) {
    return extractQrCode(uri) != null ||
        (uri.scheme == 'aya-huile-app' &&
            ['qr', 'game', 'exchange'].contains(uri.host));
  }
}
