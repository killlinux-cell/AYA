import '../models/user.dart' as app_user;
import '../models/game_data.dart';
import '../models/qr_code_data.dart';

// Interface abstraite pour les données
abstract class DataSource {
  Future<app_user.User?> getUserData(String userId);
  Future<void> updateUserPoints(String userId, int points);
  Future<void> addGameResult(String userId, GameData gameData);
  Future<List<GameData>> getUserGames(String userId);
  Future<void> addQRCodeScan(String userId, QRCodeData qrData);
  Future<List<QRCodeData>> getUserQRScans(String userId);
  Future<Map<String, dynamic>> getUserStats(String userId);
}

// Service de données principal
class DataService {
  static DataService? _instance;
  DataSource? _dataSource;

  DataService._();

  static DataService get instance {
    _instance ??= DataService._();
    return _instance!;
  }

  // Configuration de la source de données
  void configureDataSource(DataSource dataSource) {
    _dataSource = dataSource;
  }

  // Méthodes pour accéder aux données
  Future<app_user.User?> getUserData(String userId) async {
    if (_dataSource == null) {
      throw Exception('DataSource non configurée');
    }
    return await _dataSource!.getUserData(userId);
  }

  Future<void> updateUserPoints(String userId, int points) async {
    if (_dataSource == null) {
      throw Exception('DataSource non configurée');
    }
    await _dataSource!.updateUserPoints(userId, points);
  }

  Future<void> addGameResult(String userId, GameData gameData) async {
    if (_dataSource == null) {
      throw Exception('DataSource non configurée');
    }
    await _dataSource!.addGameResult(userId, gameData);
  }

  Future<List<GameData>> getUserGames(String userId) async {
    if (_dataSource == null) {
      throw Exception('DataSource non configurée');
    }
    return await _dataSource!.getUserGames(userId);
  }

  Future<void> addQRCodeScan(String userId, QRCodeData qrData) async {
    if (_dataSource == null) {
      throw Exception('DataSource non configurée');
    }
    await _dataSource!.addQRCodeScan(userId, qrData);
  }

  Future<List<QRCodeData>> getUserQRScans(String userId) async {
    if (_dataSource == null) {
      throw Exception('DataSource non configurée');
    }
    return await _dataSource!.getUserQRScans(userId);
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    if (_dataSource == null) {
      throw Exception('DataSource non configurée');
    }
    return await _dataSource!.getUserStats(userId);
  }
}

