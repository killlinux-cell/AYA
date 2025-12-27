import 'package:flutter/material.dart';
import '../services/local_auth_service.dart';
import 'home_screen.dart';
import 'auth_screen.dart';
import 'new_password_screen.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final String? email;
  final String? type; // 'confirmation' ou 'reset'

  const EmailConfirmationScreen({super.key, this.email, this.type});

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  bool _isLoading = true;
  bool _isConfirmed = false;
  String _message = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _handleEmailConfirmation();
  }

  Future<void> _handleEmailConfirmation() async {
    try {
      final authService = LocalAuthService();

      // Pour la démo, toujours considérer l'email comme confirmé
      setState(() {
        _isConfirmed = true;
        _message = 'Votre email a été confirmé avec succès !';
        _isLoading = false;
      });

      // Rediriger vers l'écran principal après un délai
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isConfirmed = false;
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF488950),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isLoading
                          ? Icons.hourglass_empty
                          : _isConfirmed
                          ? Icons.check_circle
                          : Icons.error,
                      size: 40,
                      color: _isLoading
                          ? Colors.orange
                          : _isConfirmed
                          ? const Color(0xFF488950)
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoading
                        ? 'Vérification en cours...'
                        : _isConfirmed
                        ? 'Email confirmé !'
                        : 'Erreur de confirmation',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Contenu principal
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF488950)),
            ),
            SizedBox(height: 24),
            Text(
              'Vérification de votre email...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isConfirmed ? Icons.check_circle : Icons.error,
          color: _isConfirmed ? const Color(0xFF488950) : Colors.red,
          size: 80,
        ),
        const SizedBox(height: 24),
        Text(
          _isConfirmed ? 'Succès !' : 'Erreur',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isConfirmed ? const Color(0xFF488950) : Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage.isNotEmpty ? _errorMessage : _message,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_isConfirmed)
          const Text(
            'Redirection automatique...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          )
        else
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF488950),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Retour à la connexion',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
