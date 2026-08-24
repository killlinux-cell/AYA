import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../services/django_auth_service.dart';
import '../services/qr_prize_service.dart';
import '../widgets/prize_popup_widget.dart';
import '../widgets/loyalty_ticket_popup_widget.dart';
import 'home_screen.dart';

class QRScannerScreen extends StatefulWidget {
  final String? prefilledCode;

  const QRScannerScreen({super.key, this.prefilledCode});

  @override
  State<QRScannerScreen> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String _scannedCode = '';
  int _pointsEarned = 0;
  bool _showResult = false;
  /// 0 = saisie 6 chiffres (défaut), 1 = scanner QR (anciens codes)
  int _mode = 0;
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  final QRPrizeService _qrPrizeService = QRPrizeService(
    DjangoAuthService.instance,
  );

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _claimCode(widget.prefilledCode!);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _submitManualCode() async {
    final raw = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(raw)) {
      _showErrorDialog(
        'Entrez exactement 6 chiffres (exemple : 482917).',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await _claimCode(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_mode == 0 ? 'Saisir le code' : 'Scanner QR'),
        backgroundColor: const Color(0xFF488950),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_mode == 1) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => controller.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              onPressed: () => controller.switchCamera(),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF488950),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.pin, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Gagnez des points',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _mode == 0
                      ? 'Entrez le code à 6 chiffres sur le bouchon'
                      : 'Ou scannez un ancien QR code',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeChip(
                          label: 'Code 6 chiffres',
                          selected: _mode == 0,
                          onTap: () {
                            if (_mode == 0) return;
                            setState(() => _mode = 0);
                            try {
                              controller.stop();
                            } catch (_) {}
                          },
                        ),
                      ),
                      Expanded(
                        child: _ModeChip(
                          label: 'Scanner QR',
                          selected: _mode == 1,
                          onTap: () {
                            if (_mode == 1) return;
                            setState(() => _mode = 1);
                            try {
                              controller.start();
                            } catch (_) {}
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _showResult
                  ? _buildResult()
                  : (_mode == 0 ? _buildCodeEntry() : _buildQrScanner()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeEntry() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Code du bouchon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  focusNode: _codeFocus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                    fontFamily: 'monospace',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      letterSpacing: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF488950)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF488950),
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _submitManualCode(),
                ),
                const SizedBox(height: 12),
                Text(
                  '6 chiffres uniquement',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _submitManualCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF488950),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Valider et gagner des points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrScanner() {
    return Column(
      children: [
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
                      for (final barcode in capture.barcodes) {
                        if (barcode.rawValue != null) {
                          _claimCode(barcode.rawValue!);
                          break;
                        }
                      }
                    },
                  ),
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
                    ),
                  ),
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
                        'Anciens QR codes uniquement',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
      ],
    );
  }

  Widget _buildResult() {
    return Container(
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
          const Icon(Icons.check_circle, color: Color(0xFF488950), size: 64),
          const SizedBox(height: 16),
          const Text(
            'Code validé !',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Code: $_scannedCode',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'monospace',
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Autre code'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF488950),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Future<void> _claimCode(String code) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final prizeResult = await _qrPrizeService.validateAndClaimPrize(code);

      if (!prizeResult.success) {
        String errorMessage = prizeResult.error ?? 'Code invalide';

        if (prizeResult.errorType == QRPrizeError.alreadyUsed) {
          errorMessage = 'Ce code a déjà été utilisé.';
        } else if (prizeResult.errorType == QRPrizeError.expired) {
          errorMessage = 'Ce code a déjà été utilisé ou a expiré.';
        } else if (prizeResult.errorType == QRPrizeError.invalidCode) {
          errorMessage =
              prizeResult.error ?? 'Code non reconnu. Vérifiez les 6 chiffres.';
        } else if (prizeResult.errorType == QRPrizeError.networkError) {
          errorMessage =
              'Problème de connexion. Vérifiez votre internet et réessayez.';
        } else if (prizeResult.errorType == QRPrizeError.notAuthenticated) {
          errorMessage = prizeResult.error ??
              'Session expirée. Veuillez vous reconnecter.';
        } else if (prizeResult.errorType == QRPrizeError.serverError) {
          errorMessage =
              prizeResult.error ?? 'Erreur du serveur. Réessayez plus tard.';
        }

        _showErrorDialog(errorMessage);
        return;
      }

      try {
        await controller.stop();
      } catch (_) {}

      _scannedCode = prizeResult.qrCode?.code ?? code;
      _pointsEarned = prizeResult.prize?.value ?? 0;

      setState(() {
        _showResult = true;
        _isProcessing = false;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final newAvailablePoints = currentUser.availablePoints + _pointsEarned;
        final newCollectedQRCodes = currentUser.collectedQRCodes + 1;

        await userProvider.updatePoints(
          newAvailablePoints,
          currentUser.exchangedPoints,
        );

        authProvider.updateCurrentUser(
          currentUser.copyWith(
            availablePoints: newAvailablePoints,
            collectedQRCodes: newCollectedQRCodes,
          ),
        );
      }

      _showPrizePopup(prizeResult);
    } catch (e) {
      _showErrorDialog('Erreur lors du traitement du code: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPrizePopup(QRPrizeResult prizeResult) {
    if (prizeResult.prize?.isLoyaltyTicket == true) {
      _showLoyaltyTicketPopup(prizeResult);
    } else {
      showPrizePopup(
        context: context,
        prizeResult: prizeResult,
        onClose: () {},
      );
    }
  }

  void _showLoyaltyTicketPopup(QRPrizeResult prizeResult) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoyaltyTicketPopupWidget(
          message:
              prizeResult.message ?? 'Vous avez gagné un ticket de fidélité !',
          onPlayGame: () {
            Navigator.of(context).pop();
            _navigateToGames();
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _navigateToGames() {
    // Section Jeux masquée pour le moment
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Les jeux seront bientôt disponibles.'),
      ),
    );
  }

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
                'Code non valide',
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
                  'Vérifiez les 6 chiffres imprimés sur le bouchon.',
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
                        Navigator.of(context).pop();
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
                        Navigator.of(context).pop();
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
    _codeController.clear();
    setState(() {
      _showResult = false;
      _scannedCode = '';
      _pointsEarned = 0;
      _isProcessing = false;
      _mode = 0;
    });
    try {
      controller.stop();
    } catch (_) {}
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF488950) : Colors.white,
          ),
        ),
      ),
    );
  }
}
