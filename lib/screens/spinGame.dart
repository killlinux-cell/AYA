import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/django_game_service.dart';
import '../services/django_auth_service.dart';

class SpinGame extends StatefulWidget {
  @override
  _SpinGameState createState() => _SpinGameState();
}

class _SpinGameState extends State<SpinGame> {
  StreamController<int> controller = StreamController<int>();
  bool _isSpinning = false;
  bool _isLoading = false;
  int _pointsWon = 0;
  String _result = '';

  final List<Map<String, dynamic>> _items = [
    {'text': '⭐ Bonus', 'points': 20, 'color': Colors.amber},
    {'text': '🎁 Cadeau', 'points': 15, 'color': Colors.pink},
    {'text': '💰 Argent', 'points': 25, 'color': Colors.green},
    {'text': '❌ Perdu', 'points': 0, 'color': Colors.red},
    {'text': '🔄 Rejouer', 'points': 10, 'color': Colors.blue},
    {'text': '🎯 Jackpot', 'points': 50, 'color': Colors.purple},
  ];

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  Future<void> _startGame() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final gameService = DjangoGameService(DjangoAuthService.instance);
      final result = await gameService.playGame(user.id, 'spin_wheel', 10);

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

  void _spinWheel() {
    if (_isSpinning || _isLoading) return;

    setState(() {
      _isSpinning = true;
    });

    // Utiliser le service de jeu pour obtenir le résultat
    final random = Random();
    final selectedIndex = random.nextInt(_items.length);
    final selectedItem = _items[selectedIndex];

    // Le résultat réel vient du LocalGameService, mais on utilise l'index pour l'animation
    _result = selectedItem['text'];

    // Faire tourner la roue
    controller.add(selectedIndex);

    // Attendre la fin de l'animation
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _isSpinning = false;
      });

      // Afficher le résultat (les points viennent du LocalGameService)
      String message;
      if (_pointsWon > 0) {
        message = '🎉 Félicitations ! Vous avez gagné $_pointsWon points !';
      } else {
        message = '😔 Dommage, vous n\'avez rien gagné cette fois...';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _pointsWon > 0
              ? const Color(0xFF488950)
              : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFF488950),
      appBar: AppBar(
        title: const Text(
          "Spin a Wheel",
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
                      Icons.rotate_right,
                      size: 40,
                      color: Color(0xFF488950),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Spin a Wheel',
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
                      if (_isLoading) ...[
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF488950),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Préparation du jeu...'),
                      ] else ...[
                        const Text(
                          "Tournez la roue pour gagner des points ! 🎯",
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
                        const SizedBox(height: 30),

                        // Roue de fortune
                        Expanded(
                          child: FortuneWheel(
                            selected: controller.stream,
                            items: [
                              for (var item in _items)
                                FortuneItem(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      item['text'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  style: FortuneItemStyle(
                                    color: item['color'],
                                    borderWidth: 2,
                                    borderColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Bouton pour tourner
                        ElevatedButton(
                          onPressed: _isSpinning ? null : _spinWheel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF488950),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: _isSpinning
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'TOURNER',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
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
