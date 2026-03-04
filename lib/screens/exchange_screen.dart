import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../constants/exchange_catalog.dart';
import '../services/exchange_token_service.dart';
import '../widgets/exchange_qr_popup_widget.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  int _selectedPoints = 0;
  final List<int> _pointOptions = [50, 150, 300, 500, 1000, 2000, 5000];
  bool _isGenerating = false;
  final TextEditingController _customPointsController = TextEditingController();
  bool _isCustomInput = false;

  final ExchangeTokenService _exchangeTokenService = ExchangeTokenService();

  @override
  void dispose() {
    _customPointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '💳 Échanger des Points',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF488950),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<AuthProvider, UserProvider>(
        builder: (context, authProvider, userProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec informations utilisateur
                _buildUserInfo(user),

                const SizedBox(height: 30),

                // Sélection du montant
                _buildAmountSelection(),

                const SizedBox(height: 20),

                // Ce que vous obtiendrez (catalogue)
                if (_selectedPoints > 0) _buildRewardPreview(),

                const SizedBox(height: 30),

                // Bouton d'échange
                _buildExchangeButton(user),

                const SizedBox(height: 20),

                // Instructions
                _buildInstructions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF488950), Color(0xFF60A066), Color(0xFF3A6F41)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF488950).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💳 ÉCHANGE DE POINTS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bonjour ${user.name?.split(' ').first ?? 'Utilisateur'} !',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Points disponibles:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${user.availablePoints ?? 0}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Retourne le prochain palier si l'utilisateur n'a pas atteint un palier du catalogue
  String? _getNextTierHint(int points) {
    if (points <= 0) return null;
    for (final tier in exchangeCatalog) {
      final tierPoints = tier['points'] as int;
      if (tierPoints > points) {
        return 'Prochain palier : $tierPoints pts → ${tier['reward']}';
      }
    }
    return null;
  }

  Widget _buildRewardPreview() {
    final reward = getRewardForPoints(_selectedPoints);
    final nextTier = _getNextTierHint(_selectedPoints);
    final isExactTier =
        exchangeCatalog.any((t) => t['points'] == _selectedPoints);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF488950).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF488950).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: const Color(0xFF488950), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Ce que vous obtiendrez',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF488950),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reward != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF488950).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF488950).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF488950), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        if (!isExactTier)
                          Text(
                            'Palier le plus proche pour $_selectedPoints pts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (nextTier != null && reward != null) ...[
            const SizedBox(height: 12),
            Text(
              nextTier,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Catalogue d\'échange',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...exchangeCatalog.map((tier) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${tier['points']} pts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: tier['points'] == _selectedPoints
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: tier['points'] == _selectedPoints
                              ? const Color(0xFF488950)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Text(
                      '→ ${tier['reward']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAmountSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 Montant à échanger',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF488950),
            ),
          ),
          const SizedBox(height: 16),

          // Options prédéfinies
          const Text(
            'Montants suggérés:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _pointOptions.map((points) {
              final isSelected = _selectedPoints == points && !_isCustomInput;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPoints = points;
                    _isCustomInput = false;
                    _customPointsController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF488950)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF488950)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$points pts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Option personnalisée
          const Text(
            'Ou saisissez un montant personnalisé:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _customPointsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ex: 150',
              prefixIcon: const Icon(Icons.edit, color: Color(0xFF488950)),
              suffixText: 'points',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF488950),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _isCustomInput = true;
                  _selectedPoints = int.tryParse(value) ?? 0;
                });
              } else {
                setState(() {
                  _isCustomInput = false;
                  _selectedPoints = 0;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeButton(user) {
    final canExchange =
        _selectedPoints > 0 && _selectedPoints <= (user.availablePoints ?? 0);

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: canExchange && !_isGenerating ? _createExchangeToken : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canExchange ? const Color(0xFF488950) : Colors.grey,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: _isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Génération du QR code...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Text(
                !canExchange
                    ? _selectedPoints == 0
                          ? 'Sélectionnez un montant'
                          : 'Points insuffisants'
                    : '💳 CRÉER QR CODE D\'ÉCHANGE',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Comment ça marche ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF488950),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Sélectionnez le montant de points à échanger\n'
            '2. Un QR code temporaire sera généré (valide 3 minutes)\n'
            '3. Montrez ce QR code au vendeur\n'
            '4. Le vendeur scannera le code pour confirmer l\'échange\n'
            '5. Vos points seront déduits de votre compte',
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le QR code expire après 3 minutes pour des raisons de sécurité.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createExchangeToken() async {
    if (_selectedPoints <= 0) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final result = await _exchangeTokenService.createExchangeToken(
        _selectedPoints,
      );

      if (result.success) {
        // Afficher le popup avec le QR code
        _showExchangeQRPopup(
          qrCodeData: result.qrCodeData!,
          points: _selectedPoints,
          expiresInMinutes: result.expiresInMinutes!,
        );
      } else {
        _showErrorDialog(result.error!);
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la création du token: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _showExchangeQRPopup({
    required String qrCodeData,
    required int points,
    required int expiresInMinutes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ExchangeQRPopupWidget(
          qrCodeData: qrCodeData,
          points: points,
          expiresInMinutes: expiresInMinutes,
          onClose: () {
            Navigator.of(context).pop();
            // Rafraîchir les données utilisateur
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            userProvider.refreshUserData();
          },
          onExpired: () {
            _showErrorDialog(
              'Le QR code a expiré. Veuillez en créer un nouveau.',
            );
          },
        );
      },
    );
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
