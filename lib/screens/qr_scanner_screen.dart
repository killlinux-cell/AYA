import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../services/django_auth_service.dart';
import '../services/qr_prize_service.dart';
import '../widgets/prize_popup_widget.dart';
import '../widgets/loyalty_ticket_popup_widget.dart';
import 'games_screen.dart';
import 'home_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String? prefilledCode;

  const QRScannerScreen({super.key, this.prefilledCode});

  @override
  State<QRScannerScreen> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = false;
  String _scannedCode = '';
  int _pointsEarned = 0;
  bool _showResult = false;
  final QRPrizeService _qrPrizeService = QRPrizeService(
    DjangoAuthService.instance,
  );

  @override
  void initState() {
    super.initState();
    // Si un code est pré-rempli, le traiter automatiquement
    if (widget.prefilledCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onQRCodeDetected(widget.prefilledCode!);
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Scanner QR'),
        backgroundColor: const Color(0xFF488950),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.flash_off : Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: Icon(_isScanning ? Icons.camera_rear : Icons.camera_front),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête du scanner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF488950),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scanner un code QR',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scannez le QR code pour gagner des points',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_showResult) ...[
                    // Scanner QR réel
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              MobileScanner(
                                controller: controller,
                                onDetect: (capture) {
                                  final List<Barcode> barcodes =
                                      capture.barcodes;
                                  for (final barcode in barcodes) {
                                    if (barcode.rawValue != null) {
                                      _onQRCodeDetected(barcode.rawValue!);
                                      break;
                                    }
                                  }
                                },
                              ),
                              // Overlay pour guider l'utilisateur
                              Center(
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF488950),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.qr_code_scanner,
                                      size: 80,
                                      color: Color(0xFF488950),
                                    ),
                                  ),
                                ),
                              ),
                              // Instructions
                              Positioned(
                                bottom: 20,
                                left: 20,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Scannez le QR code pour gagner des points',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Résultat du scan
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF488950,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF488950),
                                  size: 50,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Code QR scanné !',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Code: $_scannedCode',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF488950),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '+$_pointsEarned points',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _resetScan,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade200,
                                        foregroundColor: Colors.grey.shade700,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Scanner un autre'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Retourner à l'écran d'accueil
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HomeScreen(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF488950,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Terminé'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRCodeDetected(String code) async {
    // Éviter les scans multiples rapides
    if (_isScanning) {
      print('🔄 QR Scanner: Already processing, ignoring duplicate scan');
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      print('🎯 QR Scanner: Processing QR code: $code');

      // 1. Valider et réclamer le prix avec le nouveau service
      final prizeResult = await _qrPrizeService.validateAndClaimPrize(code);

      if (!prizeResult.success) {
        // Afficher l'erreur appropriée avec plus de contexte
        String errorMessage = prizeResult.error ?? 'QR code invalide';

        // Améliorer les messages d'erreur
        if (prizeResult.errorType == QRPrizeError.alreadyUsed) {
          errorMessage =
              'Ce QR code a déjà été utilisé. Veuillez scanner un autre code.';
        } else if (prizeResult.errorType == QRPrizeError.expired) {
          errorMessage =
              'Ce QR code a expiré. Veuillez scanner un code plus récent.';
        } else if (prizeResult.errorType == QRPrizeError.invalidCode) {
          errorMessage =
              'QR code non reconnu. Vérifiez que vous scannez un code valide.';
        } else if (prizeResult.errorType == QRPrizeError.networkError) {
          errorMessage =
              'Problème de connexion. Vérifiez votre internet et réessayez.';
        }

        _showErrorDialog(errorMessage);
        return;
      }

      // 2. Arrêter le scanner
      controller.stop();

      // 3. Mettre à jour l'interface utilisateur
      _scannedCode = code;
      _pointsEarned = prizeResult.prize?.value ?? 0;

      setState(() {
        _showResult = true;
        _isScanning = false;
      });

      // 4. Mettre à jour les données utilisateur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        // Mettre à jour les points dans le provider utilisateur
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // Mettre à jour les points localement
        final newAvailablePoints = currentUser.availablePoints + _pointsEarned;
        final newCollectedQRCodes = currentUser.collectedQRCodes + 1;

        // Mettre à jour le provider utilisateur
        await userProvider.updatePoints(
          newAvailablePoints,
          currentUser.exchangedPoints,
        );

        // Mettre à jour le provider d'authentification
        final updatedUser = currentUser.copyWith(
          availablePoints: newAvailablePoints,
          collectedQRCodes: newCollectedQRCodes,
        );
        authProvider.updateCurrentUser(updatedUser);

        print(
          '✅ Points mis à jour: +$_pointsEarned, Total: $newAvailablePoints',
        );
      }

      // 5. Afficher le popup de récompense amélioré
      _showPrizePopup(prizeResult);
    } catch (e) {
      print('❌ QR Scanner: Error processing QR code: $e');
      _showErrorDialog('Erreur lors du traitement du QR code: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Afficher le popup de récompense avec le nouveau système
  void _showPrizePopup(QRPrizeResult prizeResult) {
    // Vérifier si c'est un ticket de fidélité
    if (prizeResult.prize?.isLoyaltyTicket == true) {
      _showLoyaltyTicketPopup(prizeResult);
    } else {
      showPrizePopup(
        context: context,
        prizeResult: prizeResult,
        onClose: () {
          // Optionnel: navigation ou actions supplémentaires
          print('🎉 Popup de récompense fermé');
        },
      );
    }
  }

  // Afficher le popup spécial pour les tickets de fidélité
  void _showLoyaltyTicketPopup(QRPrizeResult prizeResult) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoyaltyTicketPopupWidget(
          message:
              prizeResult.message ?? 'Vous avez gagné un ticket de fidélité !',
          onPlayGame: () {
            Navigator.of(context).pop(); // Fermer le popup
            _navigateToGames();
          },
          onClose: () {
            Navigator.of(context).pop(); // Fermer le popup
          },
        );
      },
    );
  }

  // Navigation automatique vers la page des jeux
  void _navigateToGames() {
    // Attendre un court délai pour une transition fluide
    Future.delayed(const Duration(milliseconds: 300), () {
      // Navigation vers l'écran des jeux via MaterialPageRoute
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GamesScreen()),
      );
    });
  }

  // Afficher une boîte de dialogue d'erreur
  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Problème de scan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  '💡 Conseil: Assurez-vous que le QR code est bien visible et dans le cadre de scan',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Fermer la dialog
                        // Retourner à l'écran d'accueil
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Retour'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Fermer la dialog
                        // Redémarrer le scanner
                        _resetScan();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF488950),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetScan() {
    setState(() {
      _showResult = false;
      _scannedCode = '';
      _pointsEarned = 0;
      _isScanning = false;
    });

    // Redémarrer le scanner de manière plus robuste
    try {
      controller.stop();
      Future.delayed(const Duration(milliseconds: 200), () {
        try {
          controller.start();
          setState(() {
            _isScanning = true;
          });
          print('🔄 QR Scanner: Reset and restarted successfully');
        } catch (e) {
          print('❌ Erreur lors du démarrage du scanner: $e');
          // En cas d'erreur, recréer le controller
          controller.dispose();
          controller = MobileScannerController();
          controller.start();
          setState(() {
            _isScanning = true;
          });
        }
      });
    } catch (e) {
      print('❌ Erreur lors de l\'arrêt du scanner: $e');
      // En cas d'erreur, recréer le controller
      controller.dispose();
      controller = MobileScannerController();
      controller.start();
      setState(() {
        _isScanning = true;
      });
    }
  }
}
