import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/user_provider.dart';
import '../models/qr_code.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = false;
  String _scannedCode = '';
  int _pointsEarned = 0;
  bool _showResult = false;

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
        backgroundColor: const Color(0xFF4CAF50),
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
              color: Color(0xFF4CAF50),
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
                  'Pointez votre caméra vers un code QR pour collecter des points',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
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
                                      color: const Color(0xFF4CAF50),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.qr_code_scanner,
                                      size: 80,
                                      color: Color(0xFF4CAF50),
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
                                    'Pointez la caméra vers un code QR',
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4CAF50),
                                size: 60,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Code QR scanné !',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Code: $_scannedCode',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF757575),
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '+$_pointsEarned points',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _resetScan,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      foregroundColor: Colors.grey.shade700,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Scanner un autre'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
    // Vérifier si le code n'a pas déjà été scanné
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final hasCode = await userProvider.hasQRCode(code);

    if (hasCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce code QR a déjà été scanné !'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Déterminer le type de QR code et les points
    final qrType = _determineQRType(code);
    _scannedCode = code;
    _pointsEarned = _calculatePoints(qrType);

    // Ajouter le code QR à l'utilisateur
    final qrCode = QRCode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: _scannedCode,
      points: _pointsEarned,
      collectedAt: DateTime.now(),
      description: _getQRDescription(qrType),
    );

    try {
      await userProvider.addQRCode(qrCode);

      // Arrêter le scanner
      controller.stop();

      setState(() {
        _showResult = true;
      });

      // Afficher le pop-up de gain
      _showGainPopup(qrType);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout du code QR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Déterminer le type de QR code
  String _determineQRType(String code) {
    // Simulation de différents types de QR codes
    final hash = code.hashCode.abs();
    if (hash % 100 < 90) {
      return 'winning'; // 90% de chance d'être gagnant
    } else if (hash % 100 < 95) {
      return 'retry'; // 5% de chance d'être "réessayer"
    } else {
      return 'loyalty'; // 5% de chance d'être programme de fidélité
    }
  }

  // Calculer les points selon le type
  int _calculatePoints(String qrType) {
    switch (qrType) {
      case 'winning':
        final random = DateTime.now().millisecondsSinceEpoch;
        final chance = random % 100;
        if (chance < 55) return 10; // 55% pour 10 points
        if (chance < 85) return 50; // 30% pour 50 points
        return 100; // 15% pour 100 points
      case 'retry':
        return 0; // Pas de points pour "réessayer"
      case 'loyalty':
        return 25; // Points bonus pour programme de fidélité
      default:
        return 10;
    }
  }

  // Obtenir la description selon le type
  String _getQRDescription(String qrType) {
    switch (qrType) {
      case 'winning':
        return 'Code QR gagnant';
      case 'retry':
        return 'Ticket "Réessayer"';
      case 'loyalty':
        return 'Programme de fidélité';
      default:
        return 'Code QR collecté';
    }
  }

  // Afficher le pop-up de gain
  void _showGainPopup(String qrType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône selon le type
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    _getQRTypeIcon(qrType),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                Text(
                  _getQRTypeTitle(qrType),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  _getQRTypeMessage(qrType),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (qrType == 'winning' || qrType == 'loyalty') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      '+$_pointsEarned points',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Boutons d'action
                Row(
                  children: [
                    if (qrType == 'loyalty') ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(context, '/games');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Jouer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continuer',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  IconData _getQRTypeIcon(String qrType) {
    switch (qrType) {
      case 'winning':
        return Icons.stars;
      case 'retry':
        return Icons.refresh;
      case 'loyalty':
        return Icons.card_giftcard;
      default:
        return Icons.qr_code;
    }
  }

  String _getQRTypeTitle(String qrType) {
    switch (qrType) {
      case 'winning':
        return 'Félicitations !';
      case 'retry':
        return 'Réessayez !';
      case 'loyalty':
        return 'Bonus Fidélité !';
      default:
        return 'Code QR scanné';
    }
  }

  String _getQRTypeMessage(String qrType) {
    switch (qrType) {
      case 'winning':
        return 'Vous avez gagné des points !';
      case 'retry':
        return 'Pas de chance cette fois, mais ne vous découragez pas !';
      case 'loyalty':
        return 'Accédez aux jeux pour gagner encore plus de points !';
      default:
        return 'Code QR collecté avec succès';
    }
  }

  void _resetScan() {
    setState(() {
      _showResult = false;
      _scannedCode = '';
      _pointsEarned = 0;
    });
    // Redémarrer le scanner
    controller.start();
  }
}
