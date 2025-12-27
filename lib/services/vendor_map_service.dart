import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../config/django_config.dart';
import 'django_auth_service.dart';

class VendorLocation {
  final String id;
  final String businessName;
  final String vendorCode;
  final String address;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final String city;
  final String region;
  final String country;
  final String status;
  final double? distance; // Distance en km depuis la position de l'utilisateur

  VendorLocation({
    required this.id,
    required this.businessName,
    required this.vendorCode,
    required this.address,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.region,
    required this.country,
    required this.status,
    this.distance,
  });

  factory VendorLocation.fromJson(Map<String, dynamic> json) {
    return VendorLocation(
      id: json['id']?.toString() ?? '',
      businessName: json['business_name'] ?? '',
      vendorCode: json['vendor_code'] ?? '',
      address: json['business_address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      city: json['city'] ?? '',
      region: json['region'] ?? '',
      country: json['country'] ?? '',
      status: json['status'] ?? 'inactive',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'vendor_code': vendorCode,
      'business_address': address,
      'phone_number': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'region': region,
      'country': country,
      'status': status,
      'distance': distance,
    };
  }

  /// Calculer la distance depuis une position donnée
  double calculateDistance(double userLat, double userLng) {
    return Geolocator.distanceBetween(userLat, userLng, latitude, longitude) /
        1000; // Convertir en km
  }

  /// Vérifier si le vendeur est actif
  bool get isActive => status == 'active';

  /// Obtenir l'adresse complète
  String get fullAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (region.isNotEmpty) parts.add(region);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }
}

class VendorMapService {
  static const String _baseUrl = '${DjangoConfig.baseUrl}/api';

  /// Récupérer la position actuelle de l'utilisateur
  static Future<Position?> getCurrentLocation() async {
    try {
      print('📍 VendorMapService: Récupération de la position actuelle...');

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Permission de localisation refusée');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permission de localisation définitivement refusée');
        return null;
      }

      // Récupérer la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
        '✅ Position récupérée: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la position: $e');
      return null;
    }
  }

  /// Récupérer la liste des vendeurs avec leurs positions
  static Future<List<VendorLocation>> getVendorsWithLocation() async {
    try {
      print('🔄 VendorMapService: Récupération des vendeurs avec positions...');

      // Utiliser l'endpoint des vendeurs disponibles
      return await _getVendorsFromAvailableEndpoint();
    } catch (e) {
      print('❌ Erreur lors de la récupération des vendeurs: $e');
      return [];
    }
  }

  /// Récupérer les vendeurs depuis l'endpoint des vendeurs disponibles
  static Future<List<VendorLocation>> _getVendorsFromAvailableEndpoint() async {
    try {
      print('📍 URL générale: $_baseUrl/vendor/available/');

      // Récupérer le token d'authentification
      final authService = DjangoAuthService.instance;
      final token = authService.accessToken;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/vendor/available/'),
        headers: headers,
      );

      print('📡 Réponse générale: ${response.statusCode}');
      print('📄 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final vendors = <VendorLocation>[];

        final results = data['results'] ?? data;
        print(
          '📊 Nombre de vendeurs dans la réponse générale: ${results.length}',
        );

        for (final vendorData in results) {
          print(
            '🏪 Vendeur: ${vendorData['business_name']} - Lat: ${vendorData['latitude']} - Lng: ${vendorData['longitude']} - Status: ${vendorData['status']}',
          );

          final vendor = VendorLocation.fromJson(vendorData);

          // Filtrer les vendeurs actifs avec coordonnées valides
          if (vendor.isActive &&
              vendor.latitude != 0.0 &&
              vendor.longitude != 0.0) {
            vendors.add(vendor);
            print('✅ Vendeur ajouté: ${vendor.businessName}');
          } else {
            print(
              '⚠️ Vendeur ignoré: ${vendor.businessName} (actif: ${vendor.isActive}, lat: ${vendor.latitude}, lng: ${vendor.longitude})',
            );
          }
        }

        print(
          '✅ ${vendors.length} vendeurs récupérés depuis l\'endpoint général',
        );
        return vendors;
      } else {
        print(
          '❌ Erreur endpoint général ${response.statusCode}: ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('❌ Erreur endpoint général: $e');
      return [];
    }
  }

  /// Récupérer les vendeurs proches d'une position
  static Future<List<VendorLocation>> getNearbyVendors({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      print(
        '🔄 VendorMapService: Recherche de vendeurs dans un rayon de ${radiusKm}km...',
      );

      final allVendors = await getVendorsWithLocation();
      final nearbyVendors = <VendorLocation>[];

      for (final vendor in allVendors) {
        final distance = vendor.calculateDistance(latitude, longitude);

        if (distance <= radiusKm) {
          // Créer une copie avec la distance calculée
          final nearbyVendor = VendorLocation(
            id: vendor.id,
            businessName: vendor.businessName,
            vendorCode: vendor.vendorCode,
            address: vendor.address,
            phoneNumber: vendor.phoneNumber,
            latitude: vendor.latitude,
            longitude: vendor.longitude,
            city: vendor.city,
            region: vendor.region,
            country: vendor.country,
            status: vendor.status,
            distance: distance,
          );

          nearbyVendors.add(nearbyVendor);
        }
      }

      // Trier par distance
      nearbyVendors.sort(
        (a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0),
      );

      print('✅ ${nearbyVendors.length} vendeurs trouvés dans le rayon');
      return nearbyVendors;
    } catch (e) {
      print('❌ Erreur lors de la recherche de vendeurs proches: $e');
      return [];
    }
  }

  /// Obtenir l'adresse à partir de coordonnées
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final parts = <String>[];

        if (placemark.street != null && placemark.street!.isNotEmpty) {
          parts.add(placemark.street!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          parts.add(placemark.locality!);
        }
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          parts.add(placemark.administrativeArea!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          parts.add(placemark.country!);
        }

        return parts.join(', ');
      }

      return 'Position inconnue';
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'adresse: $e');
      return 'Position inconnue';
    }
  }

  /// Calculer l'itinéraire entre deux points
  static Future<Map<String, dynamic>?> getRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      print('🔄 VendorMapService: Calcul de l\'itinéraire...');

      // Pour l'instant, retourner des données de test
      // Dans une vraie implémentation, utiliser l'API Google Directions
      final distance =
          Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
          1000; // Convertir en km

      final duration = (distance * 2).round(); // Estimation: 2 min par km

      return {
        'distance': distance,
        'duration': duration,
        'polyline': '', // Encoded polyline pour Google Maps
      };
    } catch (e) {
      print('❌ Erreur lors du calcul de l\'itinéraire: $e');
      return null;
    }
  }
}
