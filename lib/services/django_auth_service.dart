import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_user;
import '../config/django_config.dart';
import '../utils/error_handler.dart';
import 'dart:async';

class DjangoAuthService {
  static const String baseUrl = DjangoConfig.baseUrl;

  // Clés pour le stockage persistant
  static const String _accessTokenKey = 'aya_access_token';
  static const String _refreshTokenKey = 'aya_refresh_token';
  static const String _userDataKey = 'aya_user_data';

  // Instance singleton
  static DjangoAuthService? _instance;
  static DjangoAuthService get instance {
    _instance ??= DjangoAuthService._internal();
    return _instance!;
  }

  // Constructeur privé pour le singleton
  DjangoAuthService._internal() {
    _loadPersistedData();
  }

  String? _accessToken;
  String? _refreshToken;
  app_user.User? _currentUser;

  final StreamController<Map<String, dynamic>> _authStateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get authStateChanges =>
      _authStateController.stream;

  app_user.User? get currentUser {
    print('🔍 DjangoAuthService.currentUser appelé: ${_currentUser?.email}');
    return _currentUser;
  }

  bool get isAuthenticated => _currentUser != null && _accessToken != null;
  bool get isEmailConfirmed =>
      true; // Django gère l'email confirmation différemment

  // Getters publics pour les autres services
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// Gère les erreurs de connexion de manière sécurisée
  Exception _handleConnectionError(dynamic error) {
    final errorMessage = ErrorHandler.handleAuthError(error);
    return Exception(errorMessage);
  }

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // Headers pour les requêtes publiques
  Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
  };

  // Charger les données persistées au démarrage
  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);

      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _currentUser = _convertDjangoUserToAppUser(userData);
      }

      print('🔄 Données chargées depuis le stockage persistant');
      print('Access Token: ${_accessToken != null ? "✅ Présent" : "❌ Absent"}');
      print('User: ${_currentUser?.email ?? "❌ Absent"}');

      // Notifier que l'utilisateur est connecté si les données sont présentes
      if (isAuthenticated) {
        _authStateController.add({'event': 'SIGNED_IN', 'user': _currentUser});
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données persistées: $e');
    }
  }

  // Sauvegarder les données de manière persistante
  Future<void> _savePersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_accessToken != null) {
        await prefs.setString(_accessTokenKey, _accessToken!);
      }
      if (_refreshToken != null) {
        await prefs.setString(_refreshTokenKey, _refreshToken!);
      }
      if (_currentUser != null) {
        // Convertir l'utilisateur en Map pour le stockage
        final userData = {
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'name': _currentUser!.name,
          'availablePoints': _currentUser!.availablePoints,
          'exchangedPoints': _currentUser!.exchangedPoints,
          'collectedQRCodes': _currentUser!.collectedQRCodes,
          'createdAt': _currentUser!.createdAt.toIso8601String(),
          'lastLoginAt': _currentUser!.lastLoginAt.toIso8601String(),
          'personalQRCode': _currentUser!.personalQRCode,
        };
        await prefs.setString(_userDataKey, jsonEncode(userData));
      }

      print('💾 Données sauvegardées dans le stockage persistant');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des données: $e');
    }
  }

  // Nettoyer les données persistées
  Future<void> _clearPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
      print('🗑️ Données persistées nettoyées');
    } catch (e) {
      print('❌ Erreur lors du nettoyage des données: $e');
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final requestData = {'email': email, 'password': password};

      final loginUrl = DjangoConfig.loginEndpoint;
      print('Tentative de connexion vers: $loginUrl');
      print('Données envoyées: ${jsonEncode(requestData)}');
      print('Headers: $_publicHeaders');

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: _publicHeaders,
        body: jsonEncode(requestData),
      );

      print('Réponse de connexion - Status: ${response.statusCode}');
      print('Réponse de connexion - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        _refreshToken = data['refresh'];

        // Convertir les données utilisateur Django vers notre modèle
        _currentUser = _convertDjangoUserToAppUser(data['user']);

        print('✅ Connexion réussie!');
        print('Access Token: ${_accessToken?.substring(0, 20)}...');
        print('User ID: ${_currentUser?.id}');
        print('User Email: ${_currentUser?.email}');

        // Sauvegarder les données de manière persistante
        await _savePersistedData();

        _authStateController.add({'event': 'SIGNED_IN', 'user': _currentUser});
        return true;
      } else {
        print('Erreur de connexion - Status: ${response.statusCode}');
        print('Erreur de connexion - Body: ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['detail'] ?? 'Erreur de connexion');
        } catch (e) {
          throw Exception('Erreur de connexion: ${response.body}');
        }
      }
    } catch (e) {
      print('Erreur de connexion: $e');
      throw _handleConnectionError(e);
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber, // ✅ Rendu optionnel
    double? latitude,
    double? longitude,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'password_confirm': password,
        'first_name': firstName,
        'last_name': lastName,
        // Envoyer le téléphone seulement s'il est fourni et non vide
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final registerUrl = DjangoConfig.registerEndpoint;
      print('Tentative d\'inscription vers: $registerUrl');
      print('Données envoyées: ${jsonEncode(requestData)}');
      print('Headers: $_publicHeaders');

      final response = await http.post(
        Uri.parse(registerUrl),
        headers: _publicHeaders,
        body: jsonEncode(requestData),
      );

      print('Réponse d\'inscription - Status: ${response.statusCode}');
      print('Réponse d\'inscription - Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _accessToken = data['access'];
        _refreshToken = data['refresh'];

        _currentUser = _convertDjangoUserToAppUser(data['user']);

        print('✅ Inscription réussie!');
        print('Access Token: ${_accessToken?.substring(0, 20)}...');
        print('User ID: ${_currentUser?.id}');
        print('User Email: ${_currentUser?.email}');
        print('isAuthenticated: $isAuthenticated');

        // Sauvegarder les données de manière persistante
        await _savePersistedData();

        // Notifier l'inscription réussie
        _authStateController.add({
          'event': 'SIGNED_UP',
          'user': _currentUser,
          'message': 'Compte créé avec succès !',
        });

        // Puis notifier la connexion automatique
        _authStateController.add({'event': 'SIGNED_IN', 'user': _currentUser});
        return true;
      } else {
        print('Erreur d\'inscription - Status: ${response.statusCode}');
        print('Erreur d\'inscription - Body: ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Erreur d\'inscription');
        } catch (e) {
          throw Exception('Erreur d\'inscription: ${response.body}');
        }
      }
    } catch (e) {
      print('Erreur d\'inscription: $e');
      throw _handleConnectionError(e);
    }
  }

  Future<void> signOut() async {
    try {
      if (_refreshToken != null) {
        await http.post(
          Uri.parse(DjangoConfig.logoutEndpoint),
          headers: _authHeaders,
          body: jsonEncode({'refresh': _refreshToken}),
        );
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    } finally {
      _accessToken = null;
      _refreshToken = null;
      _currentUser = null;

      // Nettoyer les données persistées
      await _clearPersistedData();

      _authStateController.add({'event': 'SIGNED_OUT', 'user': null});
    }
  }

  /// Supprimer définitivement le compte utilisateur
  /// Cette action est irréversible et supprime toutes les données utilisateur
  Future<bool> deleteAccount() async {
    if (!isAuthenticated) {
      throw Exception('Vous devez être connecté pour supprimer votre compte');
    }

    try {
      print('🗑️ Tentative de suppression du compte...');
      
      final response = await http.delete(
        Uri.parse(DjangoConfig.deleteAccountEndpoint),
        headers: _authHeaders,
      );

      print('Réponse suppression - Status: ${response.statusCode}');
      print('Réponse suppression - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Nettoyer les données locales
        _accessToken = null;
        _refreshToken = null;
        _currentUser = null;

        // Nettoyer les données persistées
        await _clearPersistedData();

        // Notifier la suppression
        _authStateController.add({
          'event': 'ACCOUNT_DELETED',
          'user': null,
          'message': 'Compte supprimé avec succès',
        });

        print('✅ Compte supprimé avec succès');
        return true;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
            errorData['message'] ?? 
            errorData['detail'] ?? 
            'Erreur lors de la suppression du compte',
          );
        } catch (e) {
          throw Exception('Erreur lors de la suppression: ${response.body}');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression du compte: $e');
      throw _handleConnectionError(e);
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoConfig.authUrl}/password/change/'),
        headers: _authHeaders,
        body: jsonEncode({
          'old_password': 'current_password', // À améliorer
          'new_password': newPassword,
          'new_password_confirm': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour du mot de passe: $e');
      return false;
    }
  }

  Future<String?> resetPasswordInternal(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoConfig.authUrl}/password/reset/request/'),
        headers: _publicHeaders,
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token']; // Retourner le token généré
      }
      return null;
    } catch (e) {
      print('Erreur lors de la réinitialisation: $e');
      return null;
    }
  }

  Future<bool> updatePasswordWithCode(String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoConfig.authUrl}/password/reset/confirm/'),
        headers: _publicHeaders,
        body: jsonEncode({
          'token': code,
          'new_password': newPassword,
          'new_password_confirm': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour avec code: $e');
      return false;
    }
  }

  Future<bool> isResetCodeValid(String code) async {
    try {
      // Tester la validité du code en essayant de récupérer les informations
      // Pour l'instant, on valide juste que le code n'est pas vide
      // Dans une vraie implémentation, on pourrait faire un appel API pour valider
      return code.isNotEmpty && code.length >= 8;
    } catch (e) {
      print('Erreur lors de la validation du code: $e');
      return false;
    }
  }

  // Récupérer le profil utilisateur
  Future<app_user.User?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await http.get(
        Uri.parse(DjangoConfig.profileEndpoint),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = _convertDjangoUserToAppUser(data);
        return _currentUser;
      }
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
    }
    return null;
  }

  // Mettre à jour le profil utilisateur
  Future<bool> updateUserProfile({String? firstName, String? lastName}) async {
    if (!isAuthenticated) return false;

    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;

      final response = await http.put(
        Uri.parse('${DjangoConfig.authUrl}/profile/update/'),
        headers: _authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        await getUserProfile(); // Rafraîchir le profil
        return true;
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
    }
    return false;
  }

  // Mettre à jour l'email utilisateur
  Future<bool> updateUserEmail(String newEmail) async {
    if (!isAuthenticated) return false;

    try {
      // Récupérer les données actuelles de l'utilisateur
      final user = currentUser;
      if (user == null) return false;

      // Diviser le nom complet en prénom et nom
      final nameParts = user.name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final response = await http.put(
        Uri.parse('${DjangoConfig.authUrl}/profile/update/'),
        headers: _authHeaders,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': newEmail,
        }),
      );

      if (response.statusCode == 200) {
        await getUserProfile(); // Rafraîchir le profil
        return true;
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'email: $e');
    }
    return false;
  }

  // Convertir les données utilisateur Django vers notre modèle
  app_user.User _convertDjangoUserToAppUser(Map<String, dynamic> data) {
    print('🔍 Conversion des données utilisateur Django vers Flutter:');
    print('Données reçues: $data');
    print('personal_qr_code: ${data['personal_qr_code']}');

    final user = app_user.User(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      name: '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim(),
      availablePoints: data['available_points'] ?? 0,
      exchangedPoints: data['exchanged_points'] ?? 0,
      collectedQRCodes: data['collected_qr_codes'] ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      lastLoginAt: data['last_login_at'] != null
          ? DateTime.parse(data['last_login_at'])
          : DateTime.now(),
      personalQRCode: data['personal_qr_code'] ?? '',
    );

    print('✅ Utilisateur Flutter créé:');
    print('ID: ${user.id}');
    print('Email: ${user.email}');
    print('Personal QR Code: ${user.personalQRCode}');
    print('Available Points: ${user.availablePoints}');

    return user;
  }

  void dispose() {
    _authStateController.close();
  }
}
