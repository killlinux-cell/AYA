import 'package:flutter/material.dart';
import '../services/mystery_box_service.dart';
import '../services/django_auth_service.dart';

class MysteryBoxScreen extends StatefulWidget {
  final String qrCode;

  const MysteryBoxScreen({Key? key, required this.qrCode}) : super(key: key);

  @override
  State<MysteryBoxScreen> createState() => _MysteryBoxScreenState();
}

class _MysteryBoxScreenState extends State<MysteryBoxScreen>
    with TickerProviderStateMixin {
  final MysteryBoxService _mysteryBoxService = MysteryBoxService(
    DjangoAuthService.instance,
  );

  bool _isOpening = false;
  bool _isOpened = false;
  MysteryBoxResult? _result;
  late AnimationController _boxAnimationController;
  late AnimationController _prizeAnimationController;
  late Animation<double> _boxScaleAnimation;
  late Animation<double> _prizeFadeAnimation;

  @override
  void initState() {
    super.initState();
    _boxAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _prizeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _boxScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _boxAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _prizeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _prizeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _boxAnimationController.dispose();
    _prizeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _openMysteryBox() async {
    if (_isOpening) return;

    setState(() {
      _isOpening = true;
    });

    try {
      // Démarrer l'animation de la boîte
      await _boxAnimationController.forward();

      // Ouvrir la Mystery Box
      final result = await _mysteryBoxService.openMysteryBox(widget.qrCode);

      if (result.success) {
        setState(() {
          _result = result;
          _isOpened = true;
        });

        // Démarrer l'animation du prix
        await _prizeAnimationController.forward();
      } else {
        _showErrorDialog(result.error ?? 'Erreur inconnue');
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de l\'ouverture: $e');
    } finally {
      setState(() {
        _isOpening = false;
      });
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Erreur'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retour à l'écran précédent
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mystery Box'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0), Color(0xFFE1BEE7)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Titre
                const Text(
                  '🎁 MYSTERY BOX 🎁',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'QR Code: ${widget.qrCode}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Boîte Mystery Box
                AnimatedBuilder(
                  animation: _boxScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _boxScaleAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                              Color(0xFFFF8C00),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🎁', style: TextStyle(fontSize: 80)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Résultat du prix
                if (_isOpened && _result != null)
                  AnimatedBuilder(
                    animation: _prizeFadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _prizeFadeAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _result!.isSpecialPrize
                                ? Colors.amber.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            border: _result!.isSpecialPrize
                                ? Border.all(color: Colors.amber, width: 3)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                _result!.isSpecialPrize
                                    ? '🎉 PRIX SPÉCIAL ! 🎉'
                                    : '🎁 PRIX GAGNÉ !',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _result!.isSpecialPrize
                                      ? Colors.red
                                      : const Color(0xFF6A1B9A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _result!.prizeDescription ?? 'Prix mystère',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_result!.prizeValue > 0) ...[
                                const SizedBox(height: 5),
                                Text(
                                  'Valeur: ${_result!.prizeValue} points',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 40),

                // Bouton d'ouverture
                if (!_isOpened)
                  ElevatedButton(
                    onPressed: _isOpening ? null : _openMysteryBox,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF6A1B9A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                    ),
                    child: _isOpening
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6A1B9A),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Ouverture...'),
                            ],
                          )
                        : const Text(
                            'OUVRIR LA MYSTERY BOX',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                // Bouton de retour après ouverture
                if (_isOpened)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'RETOUR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
