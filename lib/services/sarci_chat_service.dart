import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/django_config.dart';
import 'django_auth_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SarciChatService {
  SarciChatService(this._auth);

  final DjangoAuthService _auth;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_auth.accessToken != null)
      'Authorization': 'Bearer ${_auth.accessToken}',
  };

  Future<String> fetchWelcome() async {
    final response = await http.get(
      Uri.parse(DjangoConfig.chatWelcomeEndpoint),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? '';
    }
    throw Exception('Impossible de charger l\'assistant SARCI');
  }

  Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(DjangoConfig.chatEndpoint),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? 'Pas de réponse.';
    }

    if (response.statusCode == 401) {
      throw Exception('Session expirée. Reconnectez-vous.');
    }

    throw Exception('Erreur serveur (${response.statusCode})');
  }
}
