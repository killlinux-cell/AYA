import 'dart:convert';
import 'package:http/http.dart' as http;
import 'vendor_auth_service.dart';

class ClientInfoService {
  static final ClientInfoService _instance = ClientInfoService._internal();
  factory ClientInfoService() => _instance;
  ClientInfoService._internal();

  static const String _baseUrl = 'https://monuniversaya.com/api';
  final VendorAuthService _vendorAuthService = VendorAuthService();

  /// Récupérer les informations d'un client par son ID
  Future<ClientInfoResult> getClientInfo(int userId) async {
    try {
      // Vérifier que le vendeur est authentifié
      if (!_vendorAuthService.isAuthenticated) {
        return ClientInfoResult.error(error: 'Vendeur non authentifié');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/client/$userId/'),
        headers: _vendorAuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final clientData = data['client'];
          return ClientInfoResult.success(
            client: ClientInfo.fromJson(clientData),
          );
        } else {
          return ClientInfoResult.error(
            error: data['error'] ?? 'Erreur inconnue',
          );
        }
      } else if (response.statusCode == 403) {
        return ClientInfoResult.error(
          error: 'Accès refusé. Compte vendeur requis.',
        );
      } else if (response.statusCode == 404) {
        return ClientInfoResult.error(error: 'Client non trouvé');
      } else {
        final errorData = jsonDecode(response.body);
        return ClientInfoResult.error(
          error: errorData['error'] ?? 'Erreur de connexion',
        );
      }
    } catch (e) {
      return ClientInfoResult.error(error: 'Erreur de connexion: $e');
    }
  }

  /// Récupérer les informations client avec gestion d'erreur et fallback
  Future<ClientInfo> getClientInfoWithFallback(int userId) async {
    try {
      final result = await getClientInfo(userId);

      if (result.success) {
        return result.client!;
      } else {
        // Retourner des informations par défaut en cas d'erreur
        return ClientInfo(
          id: userId,
          email: 'client@aya.com',
          firstName: 'Client',
          lastName: 'Aya+',
          fullName: 'Client Aya+',
          dateJoined: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      // Fallback en cas d'exception
      return ClientInfo(
        id: userId,
        email: 'client@aya.com',
        firstName: 'Client',
        lastName: 'Aya+',
        fullName: 'Client Aya+',
        dateJoined: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Récupérer les informations client depuis les données d'échange
  Future<ClientInfo> getClientInfoFromExchange(
    Map<String, dynamic> exchangeRequest,
  ) async {
    try {
      // Essayer d'abord l'API normale
      final userId = exchangeRequest['user_id'];
      if (userId != null) {
        final userIdInt = int.tryParse(userId.toString()) ?? 0;
        if (userIdInt > 0) {
          final result = await getClientInfo(userIdInt);
          if (result.success) {
            return result.client!;
          }
        }
      }

      // Si l'API échoue, essayer d'extraire les infos depuis l'échange
      final userInfo = exchangeRequest['user_info'];
      if (userInfo != null) {
        return ClientInfo(
          id: int.tryParse(exchangeRequest['user_id']?.toString() ?? '0') ?? 0,
          email: userInfo['email'] ?? 'client@aya.com',
          firstName: userInfo['first_name'] ?? 'Client',
          lastName: userInfo['last_name'] ?? 'Aya+',
          fullName:
              userInfo['full_name'] ??
              '${userInfo['first_name'] ?? 'Client'} ${userInfo['last_name'] ?? 'Aya+'}' ??
              'Client Aya+',
          dateJoined:
              userInfo['date_joined'] ?? DateTime.now().toIso8601String(),
        );
      }

      // Fallback final
      return ClientInfo(
        id: int.tryParse(exchangeRequest['user_id']?.toString() ?? '0') ?? 0,
        email: 'client@aya.com',
        firstName: 'Client',
        lastName: 'Aya+',
        fullName: 'Client Aya+',
        dateJoined: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print(
        '❌ Erreur lors de la récupération des infos client depuis l\'échange: $e',
      );
      return ClientInfo(
        id: int.tryParse(exchangeRequest['user_id']?.toString() ?? '0') ?? 0,
        email: 'client@aya.com',
        firstName: 'Client',
        lastName: 'Aya+',
        fullName: 'Client Aya+',
        dateJoined: DateTime.now().toIso8601String(),
      );
    }
  }
}

class ClientInfoResult {
  final bool success;
  final ClientInfo? client;
  final String? error;

  ClientInfoResult._({required this.success, this.client, this.error});

  factory ClientInfoResult.success({required ClientInfo client}) {
    return ClientInfoResult._(success: true, client: client);
  }

  factory ClientInfoResult.error({required String error}) {
    return ClientInfoResult._(success: false, error: error);
  }
}

class ClientInfo {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String dateJoined;

  ClientInfo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.dateJoined,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      dateJoined: json['date_joined'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'date_joined': dateJoined,
    };
  }

  @override
  String toString() {
    return 'ClientInfo(id: $id, email: $email, fullName: $fullName)';
  }
}
