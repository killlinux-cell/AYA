import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/exchange_request.dart';
import '../services/exchange_service.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = false;
  ExchangeRequest? _scannedExchange;
  bool _isProcessing = false;

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
        title: const Text('Scanner Échange'),
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
          // En-tête
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
                  'Scanner QR Code d\'Échange',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scannez le QR code du client pour valider l\'échange',
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
                  // Zone de scan
                  if (_scannedExchange == null) ...[
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
                          child: MobileScanner(
                            controller: controller,
                            onDetect: _onExchangeDetected,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Affichage des détails de l'échange
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: const Icon(
                                    Icons.swap_horiz,
                                    color: Color(0xFF4CAF50),
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Échange Détecté',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF212121),
                                        ),
                                      ),
                                      Text(
                                        'Vérifiez les détails ci-dessous',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Détails de l'échange
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow('Code d\'échange', _scannedExchange!.exchangeCode),
                                  const SizedBox(height: 12),
                                  _buildDetailRow('Points à échanger', '${_scannedExchange!.points}'),
                                  const SizedBox(height: 12),
                                  _buildDetailRow('Date de création', _scannedExchange!.formattedDate),
                                  const SizedBox(height: 12),
                                  _buildDetailRow('Statut', _scannedExchange!.isCompleted ? 'Complété' : 'En attente'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Informations client
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Informations Client',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: ExchangeService.getUserInfo(_scannedExchange!.userId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      
                                      final userInfo = snapshot.data;
                                      if (userInfo == null) {
                                        return const Text(
                                          'Informations client non disponibles',
                                          style: TextStyle(color: Colors.grey),
                                        );
                                      }

                                      return Column(
                                        children: [
                                          _buildDetailRow('Nom', userInfo['name'] ?? 'N/A'),
                                          const SizedBox(height: 8),
                                          _buildDetailRow('Email', userInfo['email'] ?? 'N/A'),
                                          const SizedBox(height: 8),
                                          _buildDetailRow('Points disponibles', '${userInfo['availablePoints'] ?? 0}'),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Boutons d'action
                            if (!_scannedExchange!.isCompleted) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isProcessing ? null : _rejectExchange,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Rejeter',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isProcessing ? null : _confirmExchange,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4CAF50),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isProcessing
                                          ? const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text('Traitement...'),
                                              ],
                                            )
                                          : const Text(
                                              'Confirmer Échange',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Échange déjà complété',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _resetScan,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4CAF50),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Scanner un autre échange'),
                              ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF757575),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
      ],
    );
  }

  void _onExchangeDetected(BarcodeCapture capture) {
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    // Parser le code QR d'échange
    try {
      final parts = code.split(':');
      if (parts.length >= 4 && parts[0] == 'EXCHANGE') {
        final exchangeCode = parts[1];
        final points = int.parse(parts[2]);
        final userId = parts[3];

        final exchangeRequest = ExchangeRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          points: points,
          exchangeCode: exchangeCode,
          createdAt: DateTime.now(),
        );

        setState(() {
          _scannedExchange = exchangeRequest;
          _isScanning = false;
        });

        controller.stop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR code invalide. Veuillez scanner un QR code d\'échange.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du scan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmExchange() async {
    if (_scannedExchange == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simuler le traitement
      await Future.delayed(const Duration(seconds: 2));

      // Ici on appellerait le service pour confirmer l'échange
      await ExchangeService.confirmExchange(_scannedExchange!.id);

      setState(() {
        _scannedExchange = _scannedExchange!.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échange confirmé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la confirmation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectExchange() async {
    if (_scannedExchange == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter l\'échange'),
        content: const Text('Êtes-vous sûr de vouloir rejeter cet échange ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Simuler le traitement
        await Future.delayed(const Duration(seconds: 1));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échange rejeté'),
            backgroundColor: Colors.orange,
          ),
        );

        _resetScan();
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rejet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetScan() {
    setState(() {
      _scannedExchange = null;
      _isScanning = true;
    });
    controller.start();
  }
}
