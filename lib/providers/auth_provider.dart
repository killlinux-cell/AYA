import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  app_user.User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authStateSubscription = _authService.authStateChanges.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('Auth state changed: $event, session: ${session?.user.id}');

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session?.user != null) {
            print('User signed in, loading user data...');
            await _loadUserData(session!.user.id);
          }
          break;
        case AuthChangeEvent.signedIn:
          if (session?.user != null) {
            print('User signed in, loading user data...');
            await _loadUserData(session!.user.id);
          }
          break;
        case AuthChangeEvent.signedOut:
          print('User signed out, clearing data...');
          _clearUserData();
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (session?.user != null) {
            print('Token refreshed, loading user data...');
            await _loadUserData(session!.user.id);
          }
          break;
        case AuthChangeEvent.userUpdated:
          if (session?.user != null) {
            print('User updated, loading user data...');
            await _loadUserData(session!.user.id);
          }
          break;
        default:
          print('Unhandled auth event: $event');
          break;
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    try {
      print('Loading user data for ID: $userId');
      _isLoading = true;
      notifyListeners();

      // Attendre un peu pour s'assurer que le profil est créé
      await Future.delayed(const Duration(milliseconds: 1000));

      final userData = await _userService.getUserData(userId);
      if (userData != null) {
        _currentUser = userData;
        _isAuthenticated = true;
        _error = null;
        print(
          'User data loaded successfully in AuthProvider: ${userData.name}, Points: ${userData.availablePoints}',
        );
      } else {
        _error = 'Impossible de charger les données utilisateur';
        _isAuthenticated = false;
        print('No user data found in AuthProvider for ID: $userId');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      _error =
          'Erreur lors du chargement des données utilisateur: ${e.toString()}';
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

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

      if (_authService.isAuthenticated) {
        final user = _authService.currentUser;
        if (user != null) {
          await _loadUserData(user.id);
        }
      } else {
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
      }
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
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // L'état sera mis à jour via l'écoute des changements d'auth
        _isLoading = false;
        notifyListeners();
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
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (response.user != null) {
        // L'état sera mis à jour via l'écoute des changements d'auth
        _isLoading = false;
        notifyListeners();
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

      // Forcer une vérification supplémentaire de l'état d'auth
      await Future.delayed(const Duration(milliseconds: 100));

      // Vérifier que l'utilisateur est bien déconnecté
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print(
          'WARNING: User still authenticated after logout, forcing cleanup',
        );
        _clearUserData();
      } else {
        print('User successfully logged out');
      }

      // L'état sera mis à jour via l'écoute des changements d'auth
      print('Logout completed - user data cleared');
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

  // Rafraîchir les données utilisateur
  Future<void> refreshUser() async {
    try {
      if (_authService.isAuthenticated) {
        final user = _authService.currentUser;
        if (user != null) {
          await _loadUserData(user.id);
        }
      }
    } catch (e) {
      _error = 'Erreur lors du rafraîchissement des données utilisateur';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
