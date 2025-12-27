import 'package:flutter/material.dart';
import 'dart:math' as math;

class GameResultPopupWidget extends StatefulWidget {
  final String gameType;
  final int pointsWon;
  final int pointsSpent;
  final bool isWinning;
  final VoidCallback onClose;

  const GameResultPopupWidget({
    Key? key,
    required this.gameType,
    required this.pointsWon,
    required this.pointsSpent,
    required this.isWinning,
    required this.onClose,
  }) : super(key: key);

  @override
  State<GameResultPopupWidget> createState() => _GameResultPopupWidgetState();
}

class _GameResultPopupWidgetState extends State<GameResultPopupWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    _fadeController.forward();
    if (widget.isWinning) {
      _particleController.repeat();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.isWinning) {
      if (widget.pointsWon >= 50) {
        return const Color(0xFF9C27B0); // Violet pour gros gain
      } else if (widget.pointsWon >= 25) {
        return const Color(0xFF488950); // Vert pour gain moyen
      } else {
        return const Color(0xFF2196F3); // Bleu pour petit gain
      }
    } else {
      return const Color(0xFF607D8B); // Gris pour perte
    }
  }

  String get _emoji {
    if (widget.isWinning) {
      if (widget.pointsWon >= 50) {
        return '🏆';
      } else if (widget.pointsWon >= 25) {
        return '🎊';
      } else {
        return '🎈';
      }
    } else {
      return '😔';
    }
  }

  String get _title {
    if (widget.isWinning) {
      return '🎉 FÉLICITATIONS !';
    } else {
      return '😔 Dommage...';
    }
  }

  String get _message {
    if (widget.isWinning) {
      return 'Vous avez gagné ${widget.pointsWon} points !';
    } else {
      return 'Vous n\'avez pas gagné cette fois.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _backgroundColor,
                        _backgroundColor.withOpacity(0.8),
                        _backgroundColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _backgroundColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: _backgroundColor.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Particules animées (seulement si gagnant)
                      if (widget.isWinning)
                        AnimatedBuilder(
                          animation: _particleAnimation,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Particules flottantes
                                ...List.generate(8, (index) {
                                  final angle =
                                      (index * 45.0) * (3.14159 / 180);
                                  final radius =
                                      60.0 + (_particleAnimation.value * 20);
                                  final x = radius * math.cos(angle);
                                  final y = radius * math.sin(angle);

                                  return Transform.translate(
                                    offset: Offset(x, y),
                                    child: Opacity(
                                      opacity: (1.0 - _particleAnimation.value)
                                          .clamp(0.0, 1.0),
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                // Icône principale
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _emoji,
                                    style: const TextStyle(fontSize: 40),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      else
                        // Icône simple pour les pertes
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            _emoji,
                            style: const TextStyle(fontSize: 40),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Titre
                      Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Message
                      Text(
                        _message,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Détails des points
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Points dépensés:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '-${widget.pointsSpent}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Points gagnés:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '+${widget.pointsWon}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white54, height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Résultat net:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${widget.pointsWon - widget.pointsSpent >= 0 ? '+' : ''}${widget.pointsWon - widget.pointsSpent}',
                                  style: TextStyle(
                                    color:
                                        widget.pointsWon - widget.pointsSpent >=
                                            0
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bouton fermer
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _backgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Continuer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
