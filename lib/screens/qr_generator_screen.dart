import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final List<Map<String, dynamic>> _testQRCodes = [
    {
      'code': 'BOTTLE_001_GRAND',
      'points': 100,
      'description': 'Grand Prix - 100 points',
      'type': 'Grand Prix',
      'color': Color(0xFF9C27B0),
      'emoji': '🏆',
    },
    {
      'code': 'BOTTLE_002_GRAND',
      'points': 150,
      'description': 'Mega Prix - 150 points',
      'type': 'Grand Prix',
      'color': Color(0xFF9C27B0),
      'emoji': '🏆',
    },
    {
      'code': 'BOTTLE_003_GRAND',
      'points': 200,
      'description': 'Ultra Prix - 200 points',
      'type': 'Grand Prix',
      'color': Color(0xFF9C27B0),
      'emoji': '🏆',
    },
    {
      'code': 'BOTTLE_004_MEDIUM',
      'points': 50,
      'description': 'Prix Moyen - 50 points',
      'type': 'Prix Moyen',
      'color': Color(0xFF488950),
      'emoji': '🎊',
    },
    {
      'code': 'BOTTLE_005_MEDIUM',
      'points': 75,
      'description': 'Prix Moyen - 75 points',
      'type': 'Prix Moyen',
      'color': Color(0xFF488950),
      'emoji': '🎊',
    },
    {
      'code': 'BOTTLE_006_MEDIUM',
      'points': 80,
      'description': 'Prix Moyen - 80 points',
      'type': 'Prix Moyen',
      'color': Color(0xFF488950),
      'emoji': '🎊',
    },
    {
      'code': 'BOTTLE_007_SMALL',
      'points': 10,
      'description': 'Petit Prix - 10 points',
      'type': 'Petit Prix',
      'color': Color(0xFF2196F3),
      'emoji': '🎈',
    },
    {
      'code': 'BOTTLE_008_SMALL',
      'points': 15,
      'description': 'Petit Prix - 15 points',
      'type': 'Petit Prix',
      'color': Color(0xFF2196F3),
      'emoji': '🎈',
    },
    {
      'code': 'BOTTLE_009_SMALL',
      'points': 25,
      'description': 'Petit Prix - 25 points',
      'type': 'Petit Prix',
      'color': Color(0xFF2196F3),
      'emoji': '🎈',
    },
    {
      'code': 'BOTTLE_010_SMALL',
      'points': 30,
      'description': 'Petit Prix - 30 points',
      'type': 'Petit Prix',
      'color': Color(0xFF2196F3),
      'emoji': '🎈',
    },
    {
      'code': 'BOTTLE_011_LOYALTY',
      'points': 5,
      'description': 'Ticket Fidélité - 5 points',
      'type': 'Ticket Fidélité',
      'color': Color(0xFFFF9800),
      'emoji': '🎫',
    },
    {
      'code': 'BOTTLE_012_LOYALTY',
      'points': 8,
      'description': 'Ticket Fidélité - 8 points',
      'type': 'Ticket Fidélité',
      'color': Color(0xFFFF9800),
      'emoji': '🎫',
    },
    {
      'code': 'BOTTLE_013_EXPIRED',
      'points': 50,
      'description': 'QR Code Expiré',
      'type': 'Expiré',
      'color': Color(0xFF9E9E9E),
      'emoji': '⏰',
    },
    {
      'code': 'BOTTLE_014_EXPIRED',
      'points': 25,
      'description': 'QR Code Expiré',
      'type': 'Expiré',
      'color': Color(0xFF9E9E9E),
      'emoji': '⏰',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générateur de QR Codes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushNamed(context, '/qr-scanner');
            },
            tooltip: 'Scanner QR Code',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                const Icon(Icons.qr_code, size: 48, color: Colors.blue),
                const SizedBox(height: 8),
                const Text(
                  'QR Codes de Test',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Générez et testez les QR codes pour le scanner',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/qr-scanner');
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Tester le Scanner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Liste des QR codes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testQRCodes.length,
              itemBuilder: (context, index) {
                final qrData = _testQRCodes[index];
                return _buildQRCodeCard(qrData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard(Map<String, dynamic> qrData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et points
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: qrData['color'],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        qrData['emoji'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        qrData['type'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${qrData['points']} points',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Code et description
            Text(
              'Code: ${qrData['code']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              qrData['description'],
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 16),

            // QR Code visuel
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: qrData['code'],
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareQRCode(qrData),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Partager'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testQRCode(qrData['code']),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Tester'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareQRCode(Map<String, dynamic> qrData) async {
    try {
      // Créer une image du QR code
      final qrPainter = QrPainter(
        data: qrData['code'],
        version: QrVersions.auto,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final picData = await qrPainter.toImageData(200);
      if (picData != null) {
        // Sauvegarder temporairement
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qr_${qrData['code']}.png');
        await file.writeAsBytes(picData.buffer.asUint8List());

        // Partager
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'QR Code: ${qrData['code']}\n${qrData['description']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testQRCode(String code) {
    // Naviguer vers le scanner avec le code pré-rempli
    Navigator.pushNamed(
      context,
      '/qr-scanner',
      arguments: {'prefilledCode': code},
    );
  }
}
