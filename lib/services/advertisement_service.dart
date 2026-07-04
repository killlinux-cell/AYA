import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'django_auth_service.dart';

class Advertisement {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int duration;
  final int priority;
  final String status;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.priority,
    required this.status,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      duration: json['duration'] ?? 5,
      priority: json['priority'] ?? 0,
      status: json['status'] ?? 'active',
    );
  }
}

class AdvertisementService {
  AdvertisementService(DjangoAuthService authService);

  /// Récupérer les publicités actives
  Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      print('📺 AdvertisementService: Récupération des publicités actives...');

      final url = '${DjangoConfig.baseUrl}/api/advertisements/active/';
      print('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> adsJson = data['advertisements'] ?? [];

        final ads = adsJson
            .map((json) => Advertisement.fromJson(json))
            .where((ad) => ad.videoUrl.isNotEmpty)
            .toList();

        print('✅ ${ads.length} publicités récupérées');
        return ads;
      } else {
        print('❌ Erreur: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception: $e');
      return [];
    }
  }

  /// Incrémenter le compteur de vues
  Future<void> incrementView(String adId) async {
    try {
      final url = '${DjangoConfig.baseUrl}/api/advertisements/$adId/view/';

      await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('✅ Vue incrémentée pour publicité $adId');
    } catch (e) {
      print('❌ Erreur incrémentation vue: $e');
    }
  }

  /// Récupérer la bannière d'accueil (toujours depuis l'API, pas de cache).
  Future<HomeBannerData?> getHomeBanner() async {
    try {
      final url = '${DjangoConfig.baseUrl}/api/advertisements/banner/';
      print('🖼️ BannerService: Récupération de la bannière ($url)');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['banner'] == null) {
          print('ℹ️ Aucune bannière active');
          return null;
        }

        return HomeBannerData.fromJson(data['banner']);
      } else {
        print('❌ BannerService: Statut ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ BannerService: $e');
      return null;
    }
  }
}

class HomeBannerData {
  final String id;
  final String? title;
  final String? subtitle;
  final String? buttonText;
  final String? buttonUrl;
  final String? imageUrl;
  final String? updatedAt;

  HomeBannerData({
    required this.id,
    this.title,
    this.subtitle,
    this.buttonText,
    this.buttonUrl,
    this.imageUrl,
    this.updatedAt,
  });

  /// URL image avec cache-busting pour forcer le rechargement après mise à jour admin.
  String? get imageUrlWithCacheBust {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (updatedAt == null || updatedAt!.isEmpty) return imageUrl;
    final sep = imageUrl!.contains('?') ? '&' : '?';
    return '$imageUrl${sep}t=${Uri.encodeComponent(updatedAt!)}';
  }

  factory HomeBannerData.fromJson(Map<String, dynamic> json) {
    return HomeBannerData(
      id: json['id'] ?? '',
      title: json['title'],
      subtitle: json['subtitle'],
      buttonText: json['button_text'],
      buttonUrl: json['button_url'],
      imageUrl: json['image_url'],
      updatedAt: json['updated_at'],
    );
  }
}
