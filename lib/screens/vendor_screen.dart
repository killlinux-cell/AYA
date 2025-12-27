import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/vendor_auth_service.dart';
import '../services/exchange_token_service.dart';
import '../services/client_info_service.dart';
import '../widgets/vendor_confirmation_popup_widget.dart';
import '../widgets/vendor_exchange_history_widget.dart';

class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});

  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = false;
  bool _isProcessing = false;
  Map<String, dynamic>? _scannedTokenData;
  late TabController _tabController;
  int _historyRefreshKey =
      0; // Clé pour forcer le rafraîchissement de l'historique

  final VendorAuthService _vendorAuthService = VendorAuthService();
  final ExchangeTokenService _exchangeTokenService = ExchangeTokenService();
  final ClientInfoService _clientInfoService = ClientInfoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Rafraîchir l'historique quand on bascule vers l'onglet historique
      if (_tabController.index == 1) {
        // Déclencher un rebuild pour rafraîchir l'historique
        setState(() {});
      }
    });
    _isScanning = true;
  }

  @override
  void dispose() {
    controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Mode Vendeur',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF488950)),
                    SizedBox(width: 8),
                    Text('Profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec informations vendeur
          _buildVendorHeader(),

          // Onglets
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF488950),
              labelColor: const Color(0xFF488950),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanner'),
                Tab(icon: Icon(Icons.history), text: 'Historique'),
              ],
            ),
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Onglet Scanner
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Zone de scan ou détails de l'échange
                      if (_scannedTokenData == null) ...[
                        Expanded(child: _buildScannerView()),
                      ] else ...[
                        Expanded(child: _buildExchangeDetails()),
                      ],
                    ],
                  ),
                ),
                // Onglet Historique
                VendorExchangeHistoryWidget(key: ValueKey(_historyRefreshKey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorHeader() {
    final vendorInfo = _vendorAuthService.vendorInfo;

    return Container(
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
          Text(
            vendorInfo?['business_name'] ?? 'Vendeur',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Code: ${vendorInfo?['vendor_code'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scannez le QR code d\'échange du client',
            style: TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Container(
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
            MobileScanner(controller: controller, onDetect: _onTokenDetected),

            // Overlay avec instructions
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
                  'Pointez la caméra vers le QR code d\'échange du client',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeDetails() {
    final tokenData = _scannedTokenData!;
    final points = tokenData['points'] as int;
    final token = tokenData['token'] as String;
    final userId = tokenData['user_id'] as String;

    return Container(
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de l'échange
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF488950).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: Color(0xFF488950),
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
                color: const Color(0xFF488950).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF488950).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Token d\'échange',
                    token.substring(0, 8) + '...',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Points à échanger', '$points'),
                  const SizedBox(height: 12),
                  _buildDetailRow('ID Client', userId.substring(0, 8) + '...'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Statut', 'En attente de validation'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informations de sécurité
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sécurité',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Vérifiez que le client est bien présent\n'
                    '• Confirmez le montant des points\n'
                    '• Le token expire automatiquement',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _rejectExchange,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                      backgroundColor: const Color(0xFF488950),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetScan,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF488950),
                  padding: const EdgeInsets.symmetric(vertical: 10),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
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

  void _onTokenDetected(BarcodeCapture capture) {
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    // Parser le code QR d'échange temporaire
    try {
      final parts = code.split(':');
      if (parts.length >= 4 && parts[0] == 'EXCHANGE') {
        final token = parts[1];
        final points = int.parse(parts[2]);
        final userId = parts[3];

        setState(() {
          _scannedTokenData = {
            'token': token,
            'points': points,
            'user_id': userId,
            'raw_code': code,
          };
          _isScanning = false;
        });

        controller.stop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'QR code invalide. Veuillez scanner un QR code d\'échange temporaire.',
            ),
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
    if (_scannedTokenData == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final token = _scannedTokenData!['token'] as String;
      final result = await _exchangeTokenService.validateExchangeToken(token);

      if (result.success) {
        // Afficher le popup de confirmation
        _showConfirmationPopup(result);
      } else {
        _showErrorDialog(result.error!);
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la confirmation: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showConfirmationPopup(ExchangeValidationResult result) async {
    final vendorInfo = _vendorAuthService.vendorInfo;

    // Récupérer l'ID utilisateur depuis les données d'échange (pour usage futur)
    // final userIdString = result.exchangeRequest!['user_id'];
    // final userId = int.tryParse(userIdString.toString()) ?? 0;

    // Récupérer les informations client depuis l'échange
    final clientInfo = await _clientInfoService.getClientInfoFromExchange(
      result.exchangeRequest!,
    );

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return VendorConfirmationPopupWidget(
            exchangeRequest: result.exchangeRequest!,
            message: result.message!,
            vendorInfo: vendorInfo,
            clientName: clientInfo.fullName,
            clientEmail: clientInfo.email,
            onClose: () {
              Navigator.of(context).pop();
              _resetScan();
            },
            onGenerateReceipt: () {
              // Cette méthode n'est plus utilisée car la génération PDF est gérée directement dans le widget
            },
            onExchangeCompleted: () {
              // Forcer le rafraîchissement de l'historique
              setState(() {
                _historyRefreshKey++;
              });
              // Basculer vers l'onglet historique pour voir le nouvel échange
              _tabController.animateTo(1);
            },
            onUserDataRefresh: () async {
              // Rafraîchir les données utilisateur pour mettre à jour les points
              print(
                '🔄 Rafraîchissement des données utilisateur après échange...',
              );

              // Afficher un message de succès
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Échange confirmé avec succès !'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF488950),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
      );
    }
  }

  Future<void> _rejectExchange() async {
    if (_scannedTokenData == null) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Échange rejeté'),
          backgroundColor: Colors.orange,
        ),
      );
      _resetScan();
    }
  }

  void _resetScan() {
    setState(() {
      _scannedTokenData = null;
      _isScanning = true;
    });
    controller.start();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        _showVendorProfile();
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _showVendorProfile() {
    final vendorInfo = _vendorAuthService.vendorInfo;

    // Debug: Afficher les informations du vendeur
    print('🔍 Vendor Profile Debug:');
    print('   vendorInfo: $vendorInfo');
    if (vendorInfo != null) {
      print('   business_name: ${vendorInfo['business_name']}');
      print('   vendor_code: ${vendorInfo['vendor_code']}');
      print('   contact_name: ${vendorInfo['contact_name']}');
      print('   email: ${vendorInfo['email']}');
      print('   status: ${vendorInfo['status']}');
      print('   is_active: ${vendorInfo['is_active']}');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header avec icône
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF488950), Color(0xFF3A6F41)],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF488950).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 40),
                ),

                const SizedBox(height: 20),

                Text(
                  'Profil Vendeur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),

                const SizedBox(height: 24),

                // Informations du vendeur
                _buildProfileInfoCard(
                  'Nom de l\'entreprise',
                  vendorInfo?['business_name'] ?? 'N/A',
                  Icons.business,
                  const Color(0xFF2196F3),
                ),

                const SizedBox(height: 12),

                _buildProfileInfoCard(
                  'Contact',
                  vendorInfo?['contact_name'] ?? 'N/A',
                  Icons.person,
                  const Color(0xFF9C27B0),
                ),

                const SizedBox(height: 12),

                _buildProfileInfoCard(
                  'Code Vendeur',
                  vendorInfo?['vendor_code'] ?? 'N/A',
                  Icons.qr_code,
                  const Color(0xFF673AB7),
                ),

                const SizedBox(height: 12),

                _buildProfileInfoCard(
                  'Email',
                  vendorInfo?['email'] ?? 'N/A',
                  Icons.email,
                  const Color(0xFFFF9800),
                ),

                const SizedBox(height: 12),

                _buildProfileInfoCard(
                  'Statut',
                  (vendorInfo?['is_active'] == true) ? 'Actif' : 'Inactif',
                  Icons.verified_user,
                  (vendorInfo?['is_active'] == true)
                      ? const Color(0xFF488950)
                      : Colors.red,
                ),

                const SizedBox(height: 24),

                // Statistiques rapides
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        'Échanges',
                        '0',
                        Icons.swap_horiz,
                        Colors.blue,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.blue.shade200,
                      ),
                      _buildStatItem(
                        'Tokens',
                        '0',
                        Icons.confirmation_number,
                        Colors.green,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.blue.shade200,
                      ),
                      _buildStatItem(
                        'Clients',
                        '0',
                        Icons.people,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton fermer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF488950),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _vendorAuthService.logout();
      Navigator.of(context).pushReplacementNamed('/vendor-login');
    }
  }

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
