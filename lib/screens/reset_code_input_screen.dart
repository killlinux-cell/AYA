import 'package:flutter/material.dart';
import '../services/django_auth_service.dart';
import 'new_password_screen.dart';

class ResetCodeInputScreen extends StatefulWidget {
  final String email;

  const ResetCodeInputScreen({super.key, required this.email});

  @override
  State<ResetCodeInputScreen> createState() => _ResetCodeInputScreenState();
}

class _ResetCodeInputScreenState extends State<ResetCodeInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isValidating = false;
  final DjangoAuthService _authService = DjangoAuthService.instance;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isValidating = true;
    });

    try {
      // Utiliser le lien ou code tel qu'il est saisi
      String resetCode = _codeController.text.trim();

      if (resetCode.isEmpty) {
        throw Exception('Lien ou code de réinitialisation invalide');
      }

      // Valider le code avec le serveur
      final isValid = await _authService.isResetCodeValid(resetCode);

      if (mounted) {
        setState(() {
          _isValidating = false;
        });

        if (isValid) {
          // Naviguer vers la page de nouveau mot de passe
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => NewPasswordScreen(resetCode: resetCode),
            ),
          );
        } else {
          throw Exception('Code de réinitialisation invalide ou expiré');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erreur lors de la validation: ${e.toString()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.resetPasswordInternal(widget.email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (token != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Nouveau code envoyé avec succès !'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Erreur lors de l\'envoi du code'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Erreur: ${e.toString()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF488950),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Code de réinitialisation',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.email,
                      size: 40,
                      color: Color(0xFF488950),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vérifiez votre email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un code de réinitialisation a été envoyé à\n${widget.email}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contenu principal
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // Champ code
                        TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Lien ou code de réinitialisation',
                            prefixIcon: Icon(Icons.security),
                            hintText:
                                'Collez le lien reçu par email ou le code extrait',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer le lien ou le code';
                            }
                            if (value.trim().length < 6) {
                              return 'Le lien ou code doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Bouton de validation
                        ElevatedButton(
                          onPressed: _isValidating ? null : _validateCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF488950),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isValidating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Valider le code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 24),

                        // Bouton de renvoi
                        OutlinedButton(
                          onPressed: _isLoading ? null : _resendCode,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF488950)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF488950),
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Renvoyer le code',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF488950),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 32),

                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Instructions :',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                '• Vérifiez votre boîte de réception\n'
                                '• Copiez le lien de réinitialisation reçu\n'
                                '• Collez-le dans le champ ci-dessus\n'
                                '• Ou extrayez le code du lien manuellement\n'
                                '• Le lien peut être dans les spams\n'
                                '• Vous pouvez demander un nouveau lien',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Lien de retour à la connexion
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Retour à la connexion',
                            style: TextStyle(
                              color: Color(0xFF488950),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
