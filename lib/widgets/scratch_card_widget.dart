import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';

class ScratchCardWidget extends StatefulWidget {
  final String prize;
  final int points;
  final VoidCallback onScratchComplete;
  final bool isScratched;

  const ScratchCardWidget({
    Key? key,
    required this.prize,
    required this.points,
    required this.onScratchComplete,
    this.isScratched = false,
  }) : super(key: key);

  @override
  State<ScratchCardWidget> createState() => _ScratchCardWidgetState();
}

class _ScratchCardWidgetState extends State<ScratchCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  bool _isScratched = false;

  @override
  void initState() {
    super.initState();
    _isScratched = widget.isScratched;

    _revealController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _revealPrize() {
    if (_isScratched) return;

    setState(() {
      _isScratched = true;
    });

    _revealController.forward();
    widget.onScratchComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Contenu révélé (prix)
          AnimatedBuilder(
            animation: _revealAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _isScratched ? _revealAnimation.value : 0.0,
                child: Transform.scale(
                  scale: _isScratched ? _revealAnimation.value : 0.8,
                  child: Container(
                    width: 300,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getPrizeColors(),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône du prix
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
                          child: Icon(
                            _getPrizeIcon(),
                            size: 40,
                            color: _getPrizeColors().first,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Texte du prix
                        Text(
                          widget.prize,
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

                        const SizedBox(height: 8),

                        // Points gagnés
                        Text(
                          '${widget.points} points',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Couche de grattage
          if (!_isScratched)
            Scratcher(
              color: const Color(0xFF607D8B),
              accuracy: ScratchAccuracy.low,
              threshold: 30,
              brushSize: 50,
              onScratchEnd: () {
                _revealPrize();
              },
              child: Container(
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
                    // Icône de grattage
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Texte d'instruction
                    const Text(
                      'GRATTEZ ICI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Sous-texte
                    const Text(
                      'Découvrez votre prix !',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Color> _getPrizeColors() {
    if (widget.points >= 50) {
      return [
        const Color(0xFF9C27B0),
        const Color(0xFFBA68C8),
      ]; // Violet pour gros gain
    } else if (widget.points >= 25) {
      return [
        const Color(0xFF488950),
        const Color(0xFF60A066),
      ]; // Vert pour gain moyen
    } else if (widget.points > 0) {
      return [
        const Color(0xFF2196F3),
        const Color(0xFF42A5F5),
      ]; // Bleu pour petit gain
    } else {
      return [
        const Color(0xFF607D8B),
        const Color(0xFF78909C),
      ]; // Gris pour pas de gain
    }
  }

  IconData _getPrizeIcon() {
    if (widget.points >= 50) {
      return Icons.emoji_events; // Trophée pour gros gain
    } else if (widget.points >= 25) {
      return Icons.stars; // Étoiles pour gain moyen
    } else if (widget.points > 0) {
      return Icons.card_giftcard; // Cadeau pour petit gain
    } else {
      return Icons.sentiment_neutral; // Neutre pour pas de gain
    }
  }
}
