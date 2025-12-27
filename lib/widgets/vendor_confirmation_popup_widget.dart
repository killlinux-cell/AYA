import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/pdf_receipt_service.dart';
import '../services/vendor_exchange_history_service.dart';
import '../services/django_auth_service.dart';

class VendorConfirmationPopupWidget extends StatefulWidget {
  final Map<String, dynamic> exchangeRequest;
  final String message;
  final VoidCallback onClose;
  final VoidCallback onGenerateReceipt;
  final VoidCallback? onExchangeCompleted;
  final VoidCallback?
  onUserDataRefresh; // Nouveau callback pour rafraîchir les données utilisateur
  final Map<String, dynamic>? vendorInfo;
  final String? clientName;
  final String? clientEmail;

  const VendorConfirmationPopupWidget({
    Key? key,
    required this.exchangeRequest,
    required this.message,
    required this.onClose,
    required this.onGenerateReceipt,
    this.onExchangeCompleted,
    this.onUserDataRefresh, // Nouveau paramètre
    this.vendorInfo,
    this.clientName,
    this.clientEmail,
  }) : super(key: key);

  @override
  State<VendorConfirmationPopupWidget> createState() =>
      _VendorConfirmationPopupWidgetState();
}

class _VendorConfirmationPopupWidgetState
    extends State<VendorConfirmationPopupWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;

  final PDFReceiptService _pdfService = PDFReceiptService();
  final VendorExchangeHistoryService _historyService =
      VendorExchangeHistoryService(DjangoAuthService.instance);
  bool _isGeneratingPDF = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
    _particleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.exchangeRequest['points'] as int;
    final exchangeId = widget.exchangeRequest['id'] as String;

    return Material(
      color: Colors.black54,
      child: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF488950),
                      Color(0xFF60A066),
                      Color(0xFF3A6F41),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF488950).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: const Color(0xFF3A6F41).withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône de succès avec animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Color(0xFF488950),
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Titre de succès
                    const Text(
                      '✅ Échange Confirmé !',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Message de confirmation
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Détails de l'échange
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
                                'Points échangés:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '$points',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
                                'ID Transaction:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                exchangeId.substring(0, 8) + '...',
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
                                'Statut:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                'Complété',
                                style: TextStyle(
                                  color: Colors.white,
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

                    // Particules animées
                    SizedBox(
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _particleAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: ParticlePainter(_particleAnimation.value),
                            size: const Size(double.infinity, 60),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isGeneratingPDF
                                ? null
                                : _generatePDFReceipt,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isGeneratingPDF
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Génération...',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    '📄 Reçu PDF',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // L'échange est déjà confirmé, on ferme juste la popup
                              widget.onClose();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF488950),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Fermer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Générer le reçu PDF
  Future<void> _generatePDFReceipt() async {
    if (widget.vendorInfo == null) {
      print('❌ PDF: Informations vendeur manquantes');
      _showErrorDialog('Informations vendeur manquantes');
      return;
    }

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      print('🔄 Génération du PDF en cours...');
      print('📄 Exchange Request: ${widget.exchangeRequest}');
      print('🏪 Vendor Info: ${widget.vendorInfo}');

      // Vérifier que les données essentielles sont présentes
      if (widget.exchangeRequest.isEmpty) {
        throw Exception('Données d\'échange manquantes');
      }

      await _pdfService.generateExchangeReceipt(
        exchangeRequest: widget.exchangeRequest,
        vendorInfo: widget.vendorInfo!,
        clientName: widget.clientName ?? 'Client',
        clientEmail: widget.clientEmail ?? 'client@example.com',
      );

      print('✅ PDF généré avec succès');

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la génération du PDF: $e');
      _showErrorDialog('Erreur lors de la génération du PDF: $e');
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  /// Afficher une boîte de dialogue d'erreur
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur'),
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

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Générer des particules aléatoires
    final random = math.Random(42); // Seed fixe pour la cohérence

    for (int i = 0; i < 15; i++) {
      final x = (random.nextDouble() * size.width) * animationValue;
      final y =
          size.height - (random.nextDouble() * size.height * animationValue);
      final radius = (random.nextDouble() * 3 + 1) * animationValue;

      if (x < size.width && y > 0) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
