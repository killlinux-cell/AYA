import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@aya-huiles.com',
      query:
          'subject=Support Aya App&body=Bonjour, j\'ai besoin d\'aide avec l\'application Aya...',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://orapide.shop');

    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Aide et Support'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.help,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nous sommes là pour vous aider',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ
            _buildSection(
              title: 'Questions fréquentes',
              children: [
                _buildFAQItem(
                  'Comment scanner un code QR ?',
                  'Allez dans l\'onglet "Scanner" et pointez votre caméra vers un code QR. L\'application détectera automatiquement le code et vous attribuera des points.',
                  Icons.qr_code_scanner,
                ),
                _buildFAQItem(
                  'Comment gagner des points ?',
                  'Vous pouvez gagner des points en scannant des codes QR et en jouant aux mini-jeux disponibles dans l\'application.',
                  Icons.stars,
                ),
                _buildFAQItem(
                  'Comment voir mon QR personnel ?',
                  'Allez dans votre profil et cliquez sur "Mon QR Code Personnel" pour voir votre identifiant unique.',
                  Icons.qr_code,
                ),
                _buildFAQItem(
                  'Comment changer mon mot de passe ?',
                  'Dans votre profil, cliquez sur "Changer le mot de passe" et suivez les instructions.',
                  Icons.lock,
                ),
                _buildFAQItem(
                  'Comment contacter le support ?',
                  'Vous pouvez nous contacter par email en cliquant sur le bouton "Contacter le support" ci-dessous.',
                  Icons.email,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Contact
            _buildSection(
              title: 'Nous contacter',
              children: [
                _buildContactItem(
                  'Email de support',
                  'support@aya-huiles.com',
                  Icons.email,
                  _launchEmail,
                ),
                _buildContactItem(
                  'Site web',
                  'orapide.shop',
                  Icons.language,
                  _launchWebsite,
                ),
                _buildContactItem(
                  'Horaires de support',
                  'Lun-Ven : 9h-18h',
                  Icons.schedule,
                  null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informations techniques
            _buildSection(
              title: 'Informations techniques',
              children: [
                _buildInfoItem(
                  'Version de l\'application',
                  '1.0.0',
                  Icons.info,
                ),
                _buildInfoItem(
                  'Dernière mise à jour',
                  'Décembre 2024',
                  Icons.update,
                ),
                _buildInfoItem(
                  'Compatibilité',
                  'Android 6.0+ / iOS 12.0+',
                  Icons.phone_android,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bouton de retour
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retour au profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, IconData icon) {
    return ExpansionTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
      ),
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF757575),
              size: 16,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildInfoItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF4CAF50), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
      ),
    );
  }
}
