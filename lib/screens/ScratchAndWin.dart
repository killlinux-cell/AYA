import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/django_game_service.dart';
import '../services/django_auth_service.dart';

class ScratchAndWinGame extends StatefulWidget {
  @override
  _ScratchAndWinGameState createState() => _ScratchAndWinGameState();
}

class _ScratchAndWinGameState extends State<ScratchAndWinGame> {
  double _progress = 0.0;
  bool _revealed = false;
  bool _isLoading = false;
  int _pointsWon = 0;

  Future<void> _startGame() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final gameService = DjangoGameService(DjangoAuthService.instance);
      final result = await gameService.playGame(user.id, 'scratch_win', 10);

      if (result['success']) {
        _pointsWon = result['pointsWon'];

        // Rafraîchir les données utilisateur pour synchroniser les points
        await userProvider.refreshUserData();

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF488950),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _onScratchComplete() {
    setState(() {
      _revealed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Félicitations ! Vous avez gagné $_pointsWon points !',
        ),
        backgroundColor: const Color(0xFF488950),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFF488950),
      appBar: AppBar(
        title: const Text(
          "Scratch & Win",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec informations
            Container(
              padding: const EdgeInsets.all(20),
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
                    child: const Icon(
                      Icons.brush,
                      size: 40,
                      color: Color(0xFF488950),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scratch & Win',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Points disponibles: ${user?.availablePoints ?? 0}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
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
                  child: Column(
                    children: [
                      if (!_revealed && !_isLoading) ...[
                        const Text(
                          "Grattez pour découvrir votre récompense ! 🎉",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Coût: 10 points",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF488950),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Commencer le jeu',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ] else if (_isLoading) ...[
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF488950),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Préparation du jeu...'),
                      ] else ...[
                        const Text(
                          "Grattez la zone ci-dessous !",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Scratcher(
                          brushSize: 50,
                          threshold: 50,
                          color: Colors.grey,
                          onChange: (value) {
                            setState(() {
                              _progress = value;
                            });
                          },
                          onThreshold: _onScratchComplete,
                          child: Container(
                            height: 200,
                            width: 300,
                            decoration: BoxDecoration(
                              color: const Color(0xFF488950),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _revealed ? "🎁 $_pointsWon points !" : "???",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Progression : ${_progress.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Bouton pour rejouer
                      if (_revealed)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _revealed = false;
                              _progress = 0.0;
                              _pointsWon = 0;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF488950),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Rejouer',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
