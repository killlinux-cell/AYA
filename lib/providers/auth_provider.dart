import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;
import '../services/django_auth_service.dart';

class AuthProvider with ChangeNotifier {
  app_user.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  StreamSubscription<Map<String, dynamic>>? _authStateSubscription;

  final DjangoAuthService _authService = DjangoAuthService.instance;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authStateSubscription = _authService.authStateChanges.listen((event) {
      final eventType = event['event'];
      final user = event['user'];
      final message = event['message'];

      switch (eventType) {
        case 'SIGNED_UP':
          _error = null;
          _isLoading = false;
          notifyListeners();
          // Afficher un message de succès
          if (message != null) {
            print('✅ $message');
          }
          break;
        case 'SIGNED_IN':
          _currentUser = user;
          _isAuthenticated = true;
          _error = null;
          _isLoading = false;
          print('AuthProvider: SIGNED_IN event received');
          print('AuthProvider: User: ${user?.email}');
          print('AuthProvider: isAuthenticated: $_isAuthenticated');
          notifyListeners();
          break;
        case 'SIGNED_OUT':
          _currentUser = null;
          _isAuthenticated = false;
          _error = null;
          _isLoading = false;
          notifyListeners();
          break;
        case 'ACCOUNT_DELETED':
          _currentUser = null;
          _isAuthenticated = false;
          _error = null;
          _isLoading = false;
          notifyListeners();
          break;
      }
    });
  }

  // Méthode _loadUserData supprimée - plus nécessaire
  // Les données utilisateur sont maintenant gérées directement par l'AuthService

  void _clearUserData() {
    print('Clearing user data in AuthProvider');
    _currentUser = null;
    _isAuthenticated = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
    print(
      'User data cleared - isAuthenticated: $_isAuthenticated, currentUser: ${_currentUser?.id}',
    );
  }

  Future<void> _checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Vérifier l'état d'authentification du service
      print(
        'AuthProvider: _authService.isAuthenticated = ${_authService.isAuthenticated}',
      );
      print(
        'AuthProvider: _authService.currentUser = ${_authService.currentUser?.email}',
      );

      if (_authService.isAuthenticated) {
        _currentUser = _authService.currentUser;
        _isAuthenticated = true;
        _error = null;
        print('AuthProvider: User is authenticated: ${_currentUser?.email}');
        print(
          'AuthProvider: User personalQRCode: ${_currentUser?.personalQRCode}',
        );
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        print('AuthProvider: User is not authenticated');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la vérification de l\'authentification';
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.signIn(
        email: email,
        password: password,
      );

      if (success) {
        // Charger les données utilisateur
        // L'utilisateur est déjà chargé dans l'AuthService
        // Pas besoin de recharger les données
        return true;
      }

      _error = 'Erreur lors de la connexion';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur de connexion: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String firstName,
    String lastName,
    String email,
    String password,
    String phoneNumber,
    double? latitude,
    double? longitude,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        latitude: latitude,
        longitude: longitude,
      );

      if (success) {
        // Charger les données utilisateur
        // L'utilisateur est déjà chargé dans l'AuthService
        // Pas besoin de recharger les données
        return true;
      }

      _error = 'Erreur lors de l\'inscription';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur d\'inscription: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print('Starting logout process...');

      // Nettoyer immédiatement les données utilisateur
      _clearUserData();

      // Effectuer la déconnexion
      await _authService.signOut();

      print('User successfully logged out');
    } catch (e) {
      print('Error during logout: $e');
      _error = 'Erreur lors de la déconnexion';
      _clearUserData(); // Forcer le nettoyage même en cas d'erreur
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Supprime définitivement le compte utilisateur
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.deleteAccount();
      if (success) {
        _clearUserData();
        return true;
      }
      _error = 'Erreur lors de la suppression du compte';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur lors de la suppression du compte: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Rafraîchir les données utilisateur
  Future<void> refreshUser() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Synchroniser avec les données de l'AuthService
        _currentUser = user;
        _isAuthenticated = true;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors du rafraîchissement des données utilisateur';
      notifyListeners();
    }
  }

  // Rafraîchir les données utilisateur depuis le serveur
  Future<void> refreshUserData() async {
    try {
      print(
        '🔄 AuthProvider: Rafraîchissement des données utilisateur depuis le serveur...',
      );

      // Récupérer le profil utilisateur depuis le serveur
      final updatedUser = await _authService.getUserProfile();

      if (updatedUser != null) {
        _currentUser = updatedUser;
        _isAuthenticated = true;
        _error = null;
        print(
          '✅ AuthProvider: Données utilisateur rafraîchies: ${updatedUser.email}, points: ${updatedUser.availablePoints}',
        );
        notifyListeners();
      } else {
        print('⚠️ AuthProvider: Aucune donnée utilisateur reçue du serveur');
      }
    } catch (e) {
      print('❌ AuthProvider: Erreur lors du rafraîchissement: $e');
      _error = 'Erreur lors du rafraîchissement des données utilisateur';
      notifyListeners();
    }
  }

  // Mettre à jour l'utilisateur actuel
  void updateCurrentUser(app_user.User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Mettre à jour les points de l'utilisateur
  void updateUserPoints(int newPoints) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(availablePoints: newPoints);
      notifyListeners();
      print('✅ AuthProvider: Points utilisateur mis à jour: $newPoints');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
