import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/scratch_card_widget.dart';
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

class ScratchAndWinGameScreen extends StatefulWidget {
  const ScratchAndWinGameScreen({Key? key}) : super(key: key);

  @override
  State<ScratchAndWinGameScreen> createState() =>
      _ScratchAndWinGameScreenState();
}

class _ScratchAndWinGameScreenState extends State<ScratchAndWinGameScreen>
    with TickerProviderStateMixin {
  bool _canPlay = true;
  bool _isPlaying = false;
  int _pointsSpent = 10;
  String _currentPrize = '';
  int _currentPoints = 0;

  final DjangoAuthService _authService = DjangoAuthService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '🎨 Scratch & Win',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFFF9800),
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

            // Carte de grattage
            _buildScratchCard(),

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
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D), Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎨 SCRATCH & WIN',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Coût: $_pointsSpent points par carte',
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

  Widget _buildScratchCard() {
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
          // Afficher une carte de grattage seulement si on a joué
          if (_currentPrize.isNotEmpty)
            ScratchCardWidget(
              prize: _currentPrize,
              points: _currentPoints,
              onScratchComplete: _onScratchComplete,
              isScratched: false,
            )
          else
            Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF607D8B),
                    Color(0xFF455A64),
                    Color(0xFF37474F),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CARTE DE GRATTAGE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jouez pour obtenir votre carte !',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            _currentPrize.isNotEmpty
                ? 'Grattez la carte pour découvrir votre prix !'
                : 'Appuyez sur "Jouer" pour obtenir votre carte !',
            style: const TextStyle(
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
            onPressed: _canPlay && canAfford && !_isPlaying ? _playGame : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canPlay && canAfford
                  ? const Color(0xFFFF9800)
                  : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
            child: _isPlaying
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
                        'Carte en cours...',
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
                        : '🎨 GRATTER LA CARTE',
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
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• Coût: 10 points par carte\n'
            '• Limite: 1 carte par jour\n'
            '• Récompenses: 0 à 50 points\n'
            '• Grattez pour découvrir votre prix\n'
            '• Les points sont ajoutés immédiatement',
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _playGame() async {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    try {
      // Synchroniser les données utilisateur avant de jouer
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserData();

      final currentPoints = authProvider.currentUser?.availablePoints ?? 0;
      print(
        '🎫 Scratch & Win Game: User data refreshed, current points: $currentPoints',
      );

      // Vérifier si l'utilisateur a assez de points
      if (currentPoints < _pointsSpent) {
        throw GameException(
          'Vous n\'avez pas assez de points pour jouer. Il vous faut $_pointsSpent points mais vous n\'en avez que $currentPoints.',
          'insufficient_points',
        );
      }

      // Appeler l'API backend pour jouer
      final result = await _playGameAPI();

      if (result != null) {
        // Définir le prix gagné
        setState(() {
          _currentPrize = result['prize_text'] ?? 'Prix inconnu';
          _currentPoints = result['points_won'] ?? 0;
        });

        // Afficher le popup de résultat après un délai
        Future.delayed(const Duration(milliseconds: 2000), () {
          _showGameResult(
            pointsWon: result['points_won'] ?? 0,
            pointsSpent: result['points_spent'] ?? _pointsSpent,
            isWinning: result['is_winning'] ?? false,
          );
        });

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
        _isPlaying = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _playGameAPI() async {
    try {
      print('🎮 Appel API: ${DjangoConfig.baseUrl}/api/games/play/');
      print(
        '🎮 Token: ${_authService.accessToken != null ? "Présent" : "Absent"}',
      );

      final response = await http.post(
        Uri.parse('${DjangoConfig.baseUrl}/api/games/play/'),
        headers: {
          'Content-Type': 'application/json',
          if (_authService.accessToken != null)
            'Authorization': 'Bearer ${_authService.accessToken}',
        },
        body: jsonEncode({
          'game_type': 'scratch_win',
          'points_cost': _pointsSpent,
        }),
      );

      print('🎮 Réponse API: ${response.statusCode}');
      print('🎮 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('🎮 Résultat du jeu: $result');
        return result;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erreur lors du jeu';
        final errorType = errorData['error_type'] ?? 'unknown';

        print('🎮 Erreur API: $errorMessage (Type: $errorType)');
        // Créer une exception personnalisée avec le type d'erreur
        throw GameException(errorMessage, errorType);
      }
    } catch (e) {
      print('🎮 Erreur lors de l\'appel API: $e');
      if (e is GameException) {
        rethrow;
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        // Gérer les erreurs de connexion spécifiquement
        throw GameException(
          'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
          'connection_error',
        );
      } else {
        // Gérer les autres erreurs
        throw GameException(
          'Erreur inattendue: ${e.toString()}',
          'unknown_error',
        );
      }
    }
  }

  void _onScratchComplete() {
    // Cette méthode est appelée quand la carte est entièrement grattée
    print('Carte grattée ! Prix: $_currentPrize, Points: $_currentPoints');
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
          gameType: 'scratch_and_win',
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
