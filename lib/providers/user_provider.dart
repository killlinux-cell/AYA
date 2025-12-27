import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;
import '../models/qr_code.dart';
import '../services/django_user_service.dart';
import '../services/django_auth_service.dart';

class UserProvider with ChangeNotifier {
  app_user.User? _user;
  List<QRCode> _qrCodes = [];
  bool _isLoading = false;
  String? _error;

  final DjangoUserService _userService = DjangoUserService.singleton();
  final DjangoAuthService _authService = DjangoAuthService.instance;

  app_user.User? get user => _user;
  List<QRCode> get collectedQRCodes => _qrCodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialiser le provider
  void initialize() {
    _checkCurrentUser();
  }

  // Synchroniser avec l'utilisateur de l'AuthProvider (pour l'inscription)
  void syncWithAuthUser(app_user.User authUser) {
    _user = authUser;
    _error = null;
    _isLoading = false;
    notifyListeners();
    print('UserProvider: Synchronized with AuthUser: ${authUser.email}');
  }

  // Vérifier l'utilisateur actuel
  Future<void> _checkCurrentUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('UserProvider: Checking current user...');
      print(
        'UserProvider: AuthService.isAuthenticated: ${_authService.isAuthenticated}',
      );

      // Récupérer les données utilisateur fraîches depuis l'API
      final freshUserData = await _authService.getUserProfile();
      if (freshUserData != null) {
        print('UserProvider: Fresh user data from API: ${freshUserData.id}');
        print(
          'UserProvider: Fresh user points: ${freshUserData.availablePoints}',
        );
        // Synchroniser avec les données fraîches de l'API
        syncWithAuthUser(freshUserData);
      } else {
        print('UserProvider: No fresh user data found from API');
        _error = 'Aucun utilisateur connecté trouvé';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la vérification de l\'utilisateur: $e';
      print('UserProvider: Error in _checkCurrentUser: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rafraîchir les données utilisateur
  Future<void> refreshUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      print('Refreshing user data for: ${currentUser.id}');
      // Synchroniser avec les données de l'AuthProvider
      syncWithAuthUser(currentUser);

      // Rafraîchir aussi la liste des QR codes
      await loadUserQRCodes(currentUser.id);
    }
  }

  void setUser(app_user.User user) {
    _user = user;
    notifyListeners();
  }

  // Méthode loadUserData supprimée - plus nécessaire
  // Les données utilisateur sont maintenant synchronisées directement depuis l'AuthProvider

  // Charger les codes QR collectés
  Future<void> loadUserQRCodes(String userId) async {
    try {
      final qrCodes = await _userService.getUserQRCodes(userId);
      _qrCodes = qrCodes;
      print('QR codes loaded: ${qrCodes.length}');

      // Pour un nouvel utilisateur, c'est normal d'avoir 0 QR codes
      if (qrCodes.isEmpty) {
        print('No QR codes collected yet - normal for new users');
      }
    } catch (e) {
      print('Error loading QR codes: $e');
      _qrCodes = [];
      // Ne pas considérer l'absence de QR codes comme une erreur fatale
    }
  }

  Future<void> updatePoints(int availablePoints, int exchangedPoints) async {
    if (_user != null) {
      try {
        await _userService.updateUserPoints(
          _user!.id,
          availablePoints,
          exchangedPoints,
        );
        _user = _user!.copyWith(
          availablePoints: availablePoints,
          exchangedPoints: exchangedPoints,
        );
        notifyListeners();
        print(
          'Points updated: Available: $availablePoints, Exchanged: $exchangedPoints',
        );
      } catch (e) {
        _error = 'Erreur lors de la mise à jour des points: $e';
        notifyListeners();
      }
    }
  }

  Future<void> addQRCode(QRCode qrCode) async {
    if (_user != null) {
      try {
        await _userService.addQRCode(_user!.id, qrCode);

        _qrCodes.add(qrCode);
        _user = _user!.copyWith(
          availablePoints: _user!.availablePoints + qrCode.points,
          collectedQRCodes: _user!.collectedQRCodes + 1,
        );
        notifyListeners();
        print(
          'QR code added: +${qrCode.points} points, Total: ${_user!.availablePoints}',
        );
      } catch (e) {
        _error = 'Erreur lors de l\'ajout du code QR: $e';
        notifyListeners();
      }
    }
  }

  Future<bool> hasQRCode(String code) async {
    if (_user != null) {
      return await _userService.hasQRCode(_user!.id, code);
    }
    return false;
  }

  Future<void> exchangePoints(int points) async {
    if (_user != null && _user!.availablePoints >= points) {
      try {
        final newAvailablePoints = _user!.availablePoints - points;
        final newExchangedPoints = _user!.exchangedPoints + points;

        await _userService.updateUserPoints(
          _user!.id,
          newAvailablePoints,
          newExchangedPoints,
        );

        _user = _user!.copyWith(
          availablePoints: newAvailablePoints,
          exchangedPoints: newExchangedPoints,
        );
        notifyListeners();
        print(
          'Points exchanged: -$points, Available: $newAvailablePoints, Exchanged: $newExchangedPoints',
        );
      } catch (e) {
        _error = 'Erreur lors de l\'échange de points: $e';
        notifyListeners();
      }
    }
  }

  // Méthode pour jouer à un jeu et gagner/perdre des points
  Future<void> playGame(int cost, int pointsWon) async {
    if (_user != null && _user!.availablePoints >= cost) {
      try {
        final newAvailablePoints = _user!.availablePoints - cost + pointsWon;

        await _userService.updateUserPoints(
          _user!.id,
          newAvailablePoints,
          _user!.exchangedPoints,
        );

        _user = _user!.copyWith(availablePoints: newAvailablePoints);
        notifyListeners();
        print(
          'Game played: Cost: $cost, Won: $pointsWon, New balance: $newAvailablePoints',
        );
      } catch (e) {
        _error = 'Erreur lors du jeu: $e';
        notifyListeners();
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Réinitialiser le provider
  void reset() {
    print('Resetting UserProvider');
    _user = null;
    _qrCodes.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
    print(
      'UserProvider reset - user: ${_user?.id}, QR codes: ${_qrCodes.length}',
    );
  }
}
