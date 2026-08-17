import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';

class RecipeVideoItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String categoryLabel;
  final String videoUrl;
  final String? thumbnailUrl;

  RecipeVideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryLabel,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  factory RecipeVideoItem.fromJson(Map<String, dynamic> json) {
    return RecipeVideoItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'recettes',
      categoryLabel: json['category_label'] ?? 'Recettes',
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
    );
  }
}

class RecipeService {
  Future<List<RecipeVideoItem>> getActiveRecipes() async {
    try {
      final response = await http.get(
        Uri.parse(DjangoConfig.recipesActiveEndpoint),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['recipes'] ?? [];
      return items
          .map((e) => RecipeVideoItem.fromJson(e as Map<String, dynamic>))
          .where((r) => r.videoUrl.isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ RecipeService: $e');
      return [];
    }
  }

  Future<void> incrementView(String id) async {
    try {
      await http.post(
        Uri.parse('${DjangoConfig.qrUrl}/recipes/$id/view/'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {}
  }
}
