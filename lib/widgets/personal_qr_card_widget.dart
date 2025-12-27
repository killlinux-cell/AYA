import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/django_user_service.dart';

class PersonalQRCardWidget extends StatefulWidget {
  const PersonalQRCardWidget({super.key});

  @override
  State<PersonalQRCardWidget> createState() => _PersonalQRCardWidgetState();
}

class _PersonalQRCardWidgetState extends State<PersonalQRCardWidget> {
  String? _personalQRCode;
  bool _isLoading = false;
  bool _isExpanded = false;
  final DjangoUserService _userService = DjangoUserService.singleton();

  @override
  void initState() {
    super.initState();
    _loadPersonalQRCode();
  }

  Future<void> _loadPersonalQRCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? existingCode = await _userService.getPersonalQRCode(user.id);

      setState(() {
        _personalQRCode = existingCode;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement du QR code personnel: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateQRCode() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Pour l'instant, on ne peut pas régénérer le QR code via l'API
      // On utilise le QR code existant
      final existingCode = await _userService.getPersonalQRCode(user.id);
      setState(() {
        _personalQRCode = existingCode;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code rechargé !'),
          backgroundColor: Color(0xFF488950),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Erreur lors de la régénération du QR code: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF488950).withOpacity(0.1),
            const Color(0xFF81C784).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF488950).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de la carte
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF488950).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code,
                        color: Color(0xFF488950),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mon QR Personnel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Partagez votre QR code avec d\'autres utilisateurs',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF488950),
                      size: 24,
                    ),
                  ],
                ),

                // Contenu expansible
                if (_isExpanded) ...[
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF488950),
                      ),
                    )
                  else if (_personalQRCode != null) ...[
                    // QR Code
                    Center(
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
                          children: [
                            QrImageView(
                              data: _personalQRCode!,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2E7D32),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF488950).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _personalQRCode!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2E7D32),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _regenerateQRCode,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Régénérer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF488950),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Action pour partager le QR code
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fonctionnalité de partage à venir !',
                                  ),
                                  backgroundColor: Color(0xFF488950),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Partager'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF488950),
                              side: const BorderSide(color: Color(0xFF488950)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Center(
                      child: Text(
                        'Erreur lors du chargement du QR code',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
