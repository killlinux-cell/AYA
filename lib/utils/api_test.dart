import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';

class APITest {
  static const String baseUrl = DjangoConfig.baseUrl;

  /// Tester la connectivité de base avec le serveur
  static Future<bool> testServerConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Accept': 'text/html'},
      );

      print('🔗 Test de connectivité serveur: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur de connectivité: $e');
      return false;
    }
  }

  /// Tester l'endpoint d'authentification
  static Future<bool> testAuthEndpoint() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/'),
        headers: DjangoConfig.defaultHeaders,
      );

      print('🔐 Test endpoint auth: ${response.statusCode}');
      return response.statusCode == 200 ||
          response.statusCode ==
              405; // 405 = Method Not Allowed (normal pour GET)
    } catch (e) {
      print('❌ Erreur endpoint auth: $e');
      return false;
    }
  }

  /// Tester l'endpoint QR codes
  static Future<bool> testQREndpoint() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: DjangoConfig.defaultHeaders,
      );

      print('📱 Test endpoint QR: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 405;
    } catch (e) {
      print('❌ Erreur endpoint QR: $e');
      return false;
    }
  }

  /// Tester tous les endpoints principaux
  static Future<Map<String, bool>> testAllEndpoints() async {
    print('🧪 Test de tous les endpoints API...');
    print('📍 URL de base: $baseUrl');

    final results = <String, bool>{};

    // Test de connectivité serveur
    results['serveur'] = await testServerConnectivity();

    // Test des endpoints API
    results['auth'] = await testAuthEndpoint();
    results['qr'] = await testQREndpoint();

    // Affichage des résultats
    print('\n📊 Résultats des tests:');
    results.forEach((key, value) {
      print('${value ? '✅' : '❌'} $key: ${value ? 'OK' : 'ERREUR'}');
    });

    return results;
  }

  /// Afficher la configuration actuelle
  static void printConfiguration() {
    print('⚙️ Configuration API actuelle:');
    print('   Base URL: ${DjangoConfig.baseUrl}');
    print('   Auth URL: ${DjangoConfig.authUrl}');
    print('   QR URL: ${DjangoConfig.qrUrl}');
    print('   Mode développement: ${DjangoConfig.isDevelopment}');
    print('   Timeout: ${DjangoConfig.requestTimeout}s');
  }
}
