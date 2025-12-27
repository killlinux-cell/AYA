import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/django_config.dart';

class VendorAuthService {
  static final VendorAuthService _instance = VendorAuthService._internal();
  factory VendorAuthService() => _instance;
  VendorAuthService._internal();

  static const String _baseUrl = '${DjangoConfig.baseUrl}/api';
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _vendorInfo;

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get vendorInfo => _vendorInfo;
  bool get isAuthenticated => _accessToken != null;

  /// Initialiser le service avec les tokens sauvegardés
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('vendor_access_token');
    _refreshToken = prefs.getString('vendor_refresh_token');

    final vendorInfoString = prefs.getString('vendor_info');
    if (vendorInfoString != null) {
      _vendorInfo = jsonDecode(vendorInfoString);
    }
  }

  /// Connexion du vendeur
  Future<VendorLoginResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/vendor/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Vérifier si la connexion a réussi
        if (data['success'] == true) {
          _accessToken = data['access'];
          _refreshToken = data['refresh'];
          _vendorInfo = data['vendor'];

          // Sauvegarder les tokens
          await _saveTokens();

          return VendorLoginResult.success(
            accessToken: _accessToken!,
            refreshToken: _refreshToken!,
            vendorInfo: _vendorInfo!,
          );
        } else {
          return VendorLoginResult.error(
            error: data['error'] ?? 'Erreur de connexion',
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        return VendorLoginResult.error(
          error:
              errorData['error'] ??
              errorData['errors']?.toString() ??
              'Erreur de connexion',
        );
      }
    } catch (e) {
      return VendorLoginResult.error(error: 'Erreur de connexion: $e');
    }
  }

  /// Déconnexion du vendeur
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _vendorInfo = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vendor_access_token');
    await prefs.remove('vendor_refresh_token');
    await prefs.remove('vendor_info');
  }

  /// Sauvegarder les tokens
  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('vendor_access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('vendor_refresh_token', _refreshToken!);
    }
    if (_vendorInfo != null) {
      await prefs.setString('vendor_info', jsonEncode(_vendorInfo!));
    }
  }

  /// Obtenir les headers d'authentification
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }
}

class VendorLoginResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? vendorInfo;
  final String? error;

  VendorLoginResult._({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.vendorInfo,
    this.error,
  });

  factory VendorLoginResult.success({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> vendorInfo,
  }) {
    return VendorLoginResult._(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      vendorInfo: vendorInfo,
    );
  }

  factory VendorLoginResult.error({required String error}) {
    return VendorLoginResult._(success: false, error: error);
  }
}
