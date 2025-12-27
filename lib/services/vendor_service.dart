import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'django_auth_service.dart';

class VendorService {
  static const String baseUrl = DjangoConfig.baseUrl; // URL de base
  final DjangoAuthService _authService;

  VendorService(this._authService);

  // Headers pour les requêtes authentifiées
  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  /// Récupérer la liste des vendeurs disponibles
  Future<List<Vendor>> getAvailableVendors() async {
    try {
      print('🔄 VendorService: Récupération des vendeurs disponibles...');
      print('🌐 URL: $baseUrl/api/vendor/available/');
      print('🔑 Headers: $_authHeaders');

      final response = await http.get(
        Uri.parse('$baseUrl/api/vendor/available/'),
        headers: _authHeaders,
      );

      print('📡 VendorService: Status Code: ${response.statusCode}');
      print('📄 VendorService: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> vendorsData = data['results'] ?? data;

        print(
          '🏪 VendorService: Nombre de vendeurs trouvés: ${vendorsData.length}',
        );

        final vendors = vendorsData
            .map(
              (vendorData) => Vendor(
                id: vendorData['id'] ?? '',
                businessName: vendorData['business_name'] ?? '',
                businessAddress: vendorData['business_address'] ?? '',
                phoneNumber: vendorData['phone_number'] ?? '',
                city: vendorData['city'] ?? '',
                region: vendorData['region'] ?? '',
                status: vendorData['status'] ?? 'inactive',
                latitude: vendorData['latitude']?.toDouble(),
                longitude: vendorData['longitude']?.toDouble(),
              ),
            )
            .toList();

        print(
          '✅ VendorService: Vendeurs récupérés avec succès: ${vendors.length}',
        );
        for (final vendor in vendors) {
          print('   - ${vendor.businessName} (${vendor.status})');
        }

        return vendors;
      } else {
        print('❌ VendorService: Erreur HTTP ${response.statusCode}');
        print('📄 VendorService: Réponse: ${response.body}');
      }
    } catch (e) {
      print('❌ VendorService: Erreur lors de la récupération des vendeurs: $e');
    }
    return [];
  }

  /// Récupérer les vendeurs par région
  Future<Map<String, List<Vendor>>> getVendorsByRegion() async {
    try {
      final vendors = await getAvailableVendors();
      final Map<String, List<Vendor>> vendorsByRegion = {};

      for (final vendor in vendors) {
        final region = vendor.region.isNotEmpty ? vendor.region : 'Autre';
        if (!vendorsByRegion.containsKey(region)) {
          vendorsByRegion[region] = [];
        }
        vendorsByRegion[region]!.add(vendor);
      }

      return vendorsByRegion;
    } catch (e) {
      print('Erreur lors du groupement des vendeurs par région: $e');
      return {};
    }
  }

  /// Rechercher des vendeurs par nom ou ville
  Future<List<Vendor>> searchVendors(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/vendor/search/?q=$query'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> vendorsData = data['results'] ?? data;

        return vendorsData
            .map(
              (vendorData) => Vendor(
                id: vendorData['id'] ?? '',
                businessName: vendorData['business_name'] ?? '',
                businessAddress: vendorData['business_address'] ?? '',
                phoneNumber: vendorData['phone_number'] ?? '',
                city: vendorData['city'] ?? '',
                region: vendorData['region'] ?? '',
                status: vendorData['status'] ?? 'inactive',
                latitude: vendorData['latitude']?.toDouble(),
                longitude: vendorData['longitude']?.toDouble(),
              ),
            )
            .toList();
      }
    } catch (e) {
      print('Erreur lors de la recherche de vendeurs: $e');
    }
    return [];
  }
}

/// Modèle pour un vendeur
class Vendor {
  final String id;
  final String businessName;
  final String businessAddress;
  final String phoneNumber;
  final String city;
  final String region;
  final String status;
  final double? latitude;
  final double? longitude;

  Vendor({
    required this.id,
    required this.businessName,
    required this.businessAddress,
    required this.phoneNumber,
    required this.city,
    required this.region,
    required this.status,
    this.latitude,
    this.longitude,
  });

  bool get isActive => status == 'active';

  String get location => city.isNotEmpty && region.isNotEmpty
      ? '$city, $region'
      : city.isNotEmpty
      ? city
      : region.isNotEmpty
      ? region
      : 'Localisation non disponible';
}
