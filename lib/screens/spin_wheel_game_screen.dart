import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/spin_wheel_widget.dart';
import '../widgets/game_result_popup_widget.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../services/django_auth_service.dart';
import '../config/django_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Classe d'exception personnalisée pour les jeux
class GameException implements Exception {
  final String message;
  final String errorType;

  GameException(this.message, this.errorType);

  @override
  String toString() => message;
}

class SpinWheelGameScreen extends StatefulWidget {
  const SpinWheelGameScreen({Key? key}) : super(key: key);

  @override
  State<SpinWheelGameScreen> createState() => _SpinWheelGameScreenState();
}

class _SpinWheelGameScreenState extends State<SpinWheelGameScreen> {
  final GlobalKey<SpinWheelWidgetState> _spinWheelKey = GlobalKey();
  bool _isSpinning = false;
  bool _canPlay = true;
  int _pointsSpent = 10;

  final DjangoAuthService _authService = DjangoAuthService.instance;

  // Sections de la roue avec différentes récompenses
  final List<WheelSection> _wheelSections = [
    WheelSection(text: '5 pts', color: const Color(0xFF488950), points: 5),
    WheelSection(text: '10 pts', color: const Color(0xFF2196F3), points: 10),
    WheelSection(text: '15 pts', color: const Color(0xFF9C27B0), points: 15),
    WheelSection(text: '25 pts', color: const Color(0xFFFF9800), points: 25),
    WheelSection(text: '0 pts', color: const Color(0xFF607D8B), points: 0),
    WheelSection(text: '5 pts', color: const Color(0xFF488950), points: 5),
    WheelSection(text: '50 pts', color: const Color(0xFFE91E63), points: 50),
    WheelSection(text: '10 pts', color: const Color(0xFF2196F3), points: 10),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '🎡 Roue de la Chance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF488950),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // En-tête avec informations
            _buildHeader(),

            const SizedBox(height: 30),

            // Roue de la chance
            _buildSpinWheel(),

            const SizedBox(height: 30),

            // Bouton de jeu
            _buildPlayButton(),

            const SizedBox(height: 20),

            // Règles du jeu
            _buildGameRules(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF488950), Color(0xFF60A066), Color(0xFF3A6F41)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF488950).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎡 ROUE DE LA CHANCE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Coût: $_pointsSpent points par tour',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Text(
                'Vos points: ${authProvider.currentUser?.availablePoints ?? 0}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpinWheel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SpinWheelWidget(
            key: _spinWheelKey,
            sections: _wheelSections,
            onSpinComplete: _onSpinComplete,
            isSpinning: _isSpinning,
          ),
          const SizedBox(height: 20),
          const Text(
            'Appuyez sur "Tourner" pour jouer !',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentPoints = authProvider.currentUser?.availablePoints ?? 0;
        final canAfford = currentPoints >= _pointsSpent;

        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _canPlay && canAfford && !_isSpinning ? _playGame : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canPlay && canAfford
                  ? const Color(0xFF488950)
                  : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
            child: _isSpinning
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Tour en cours...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    !canAfford
                        ? 'Points insuffisants'
                        : !_canPlay
                        ? 'Limite atteinte'
                        : '🎡 TOURNER LA ROUE',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildGameRules() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Règles du jeu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF488950),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• Coût: 10 points par tour\n'
            '• Limite: 1 tour par jour\n'
            '• Récompenses: 0 à 50 points\n'
            '• La roue détermine votre gain\n'
            '• Les points sont ajoutés immédiatement',
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _playGame() async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
    });

    try {
      // Synchroniser les données utilisateur avant de jouer
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserData();

      print(
        '🎡 Spin Wheel Game: User data refreshed, current points: ${authProvider.currentUser?.availablePoints ?? 0}',
      );

      // Appeler l'API backend pour jouer
      final result = await _playGameAPI();

      if (result != null) {
        // Faire tourner la roue vers la section gagnante
        await _spinToWinningSection(result['points_won']);

        // Afficher le popup de résultat
        _showGameResult(
          pointsWon: result['points_won'],
          pointsSpent: result['points_spent'],
          isWinning: result['is_winning'],
        );

        // Mettre à jour les données utilisateur
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Forcer la mise à jour des points localement
        if (authProvider.currentUser != null) {
          final currentUser = authProvider.currentUser!;
          final pointsWon = result['points_won'] ?? 0;
          final pointsSpent = result['points_spent'] ?? _pointsSpent;
          final newAvailablePoints =
              currentUser.availablePoints - pointsSpent + pointsWon;

          // Mettre à jour le provider utilisateur
          await userProvider.updatePoints(
            newAvailablePoints.toInt(),
            currentUser.exchangedPoints,
          );

          // Mettre à jour le provider d'authentification
          final updatedUser = currentUser.copyWith(
            availablePoints: newAvailablePoints.toInt(),
          );
          authProvider.updateCurrentUser(updatedUser);

          print(
            '✅ Points mis à jour: -$pointsSpent +$pointsWon = ${newAvailablePoints}',
          );
        }

        // Rafraîchir aussi les données depuis le serveur
        await userProvider.refreshUserData();
      }
    } catch (e) {
      print('Erreur lors du jeu: $e');

      String errorMessage;
      String dialogTitle;

      if (e is GameException) {
        // Gérer les erreurs spécifiques du jeu
        final message = e.message.toLowerCase();

        if (e.errorType == 'daily_limit_reached' ||
            message.contains('déjà joué') ||
            message.contains('aujourd\'hui') ||
            message.contains('demain') ||
            message.contains('limite')) {
          dialogTitle = 'Limite quotidienne atteinte';
          errorMessage =
              'Vous avez déjà joué à ce jeu aujourd\'hui. Revenez demain !';
        } else if (e.errorType == 'insufficient_points' ||
            message.contains('points') && message.contains('insuffisant')) {
          dialogTitle = 'Points insuffisants';
          errorMessage =
              'Vous n\'avez pas assez de points pour jouer. Collectez plus de QR codes !';
        } else if (e.errorType == 'game_not_available' ||
            message.contains('disponible')) {
          dialogTitle = 'Jeu indisponible';
          errorMessage = 'Ce jeu n\'est pas disponible pour le moment.';
        } else {
          dialogTitle = 'Erreur du jeu';
          errorMessage = e.message;
        }
      } else {
        // Erreur générique - analyser le message même pour les Exception normales
        final message = e.toString().toLowerCase();

        if (message.contains('déjà joué') ||
            message.contains('aujourd\'hui') ||
            message.contains('demain') ||
            message.contains('limite')) {
          dialogTitle = 'Limite quotidienne atteinte';
          errorMessage =
              'Vous avez déjà joué à ce jeu aujourd\'hui. Revenez demain !';
        } else if (message.contains('points') &&
            message.contains('insuffisant')) {
          dialogTitle = 'Points insuffisants';
          errorMessage =
              'Vous n\'avez pas assez de points pour jouer. Collectez plus de QR codes !';
        } else if (message.contains('disponible')) {
          dialogTitle = 'Jeu indisponible';
          errorMessage = 'Ce jeu n\'est pas disponible pour le moment.';
        } else {
          dialogTitle = 'Erreur de connexion';
          errorMessage =
              'Problème de connexion. Vérifiez votre internet et réessayez.';
        }
      }

      _showErrorDialog(errorMessage, dialogTitle);
    } finally {
      setState(() {
        _isSpinning = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _playGameAPI() async {
    try {
      final response = await http.post(
        Uri.parse('${DjangoConfig.baseUrl}/games/play/'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.accessToken != null)
            'Authorization': 'Bearer ${_authService.accessToken}',
        },
        body: jsonEncode({
          'game_type': 'spin_wheel',
          'points_cost': _pointsSpent,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erreur lors du jeu';
        final errorType = errorData['error_type'] ?? 'unknown';

        // Créer une exception personnalisée avec le type d'erreur
        throw GameException(errorMessage, errorType);
      }
    } catch (e) {
      print('Erreur API: $e');
      rethrow;
    }
  }

  Future<void> _spinToWinningSection(int pointsWon) async {
    // Faire tourner la roue
    _spinWheelKey.currentState?.spin();

    // Attendre que l'animation se termine
    await Future.delayed(const Duration(milliseconds: 3000));
  }

  void _onSpinComplete(int winningIndex) {
    // Cette méthode est appelée quand la roue s'arrête
    print('Roue arrêtée sur l\'index: $winningIndex');
  }

  void _showGameResult({
    required int pointsWon,
    required int pointsSpent,
    required bool isWinning,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameResultPopupWidget(
          gameType: 'spin_wheel',
          pointsWon: pointsWon,
          pointsSpent: pointsSpent,
          isWinning: isWinning,
          onClose: () {
            Navigator.of(context).pop();
            // Marquer que l'utilisateur a joué aujourd'hui
            setState(() {
              _canPlay = false;
            });
          },
        );
      },
    );
  }

  void _showErrorDialog(String message, [String title = 'Erreur']) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
