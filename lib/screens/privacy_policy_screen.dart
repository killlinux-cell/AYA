import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../config/fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Politique de Confidentialité',
          style: TextStyle(
            fontFamily: AppFonts.helvetica,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.security, color: AppColors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Mon univers AYA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Politique de Confidentialité',
                    style: TextStyle(fontSize: 16, color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dernière mise à jour : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              title: 'Introduction',
              content:
                  'Chez Aya, nous respectons votre vie privée et nous nous engageons à protéger vos informations personnelles. Cette politique explique quelles données nous collectons, comment nous les utilisons et vos droits.',
            ),

            const SizedBox(height: 20),

            // Section 1: Informations collectées
            _buildSection(
              title: '1. Informations collectées',
              content:
                  'Lorsque vous utilisez notre application, nous collectons :',
              children: [
                _buildListItem(
                  'Votre nom, adresse e-mail et numéro de téléphone lors de l\'inscription.',
                ),
                _buildListItem(
                  'Vos points et activités dans l\'application (scans de QR code, participation aux jeux).',
                ),
                _buildListItem(
                  'Informations techniques de votre appareil (type d\'appareil, version du système d\'exploitation).',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section 2: Utilisation des informations
            _buildSection(
              title: '2. Utilisation des informations',
              content: 'Nous utilisons vos données pour :',
              children: [
                _buildListItem(
                  'Gérer votre compte, suivre vos points et récompenses.',
                ),
                _buildListItem(
                  'Faciliter votre participation aux jeux et aux concours.',
                ),
                _buildListItem(
                  'Vous envoyer des communications importantes liées à l\'application et nos produits.',
                ),
                _buildListItem(
                  'Améliorer notre application et votre expérience utilisateur.',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section 3: Partage des informations
            _buildSection(
              title: '3. Partage des informations',
              content:
                  'Nous ne vendons ni ne louons vos informations personnelles. Vos données peuvent être partagées avec :',
              children: [
                _buildListItem(
                  'Nos prestataires techniques pour le bon fonctionnement de l\'application.',
                ),
                _buildListItem('Les autorités si la loi l\'exige.'),
              ],
            ),

            const SizedBox(height: 20),

            // Section 4: Sécurité des données
            _buildSection(
              title: '4. Sécurité des données',
              content:
                  'Nous mettons en place des mesures techniques et organisationnelles pour protéger vos données contre tout accès non autorisé, perte ou divulgation.',
            ),

            const SizedBox(height: 20),

            // Section 5: Vos droits
            _buildSection(
              title: '5. Vos droits',
              content: 'Vous pouvez :',
              children: [
                _buildListItem('Accéder à vos données et demander une copie.'),
                _buildListItem(
                  'Demander la correction ou la suppression de vos données.',
                ),
                _buildListItem(
                  'Vous désinscrire des communications marketing (si applicable).',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section 6: Contact
            _buildSection(
              title: '6. Contact',
              content: 'Pour exercer vos droits, contactez-nous à :',
              children: [
                _buildContactInfo(
                  'Email',
                  'sarci@sarci.ci',
                  Icons.email,
                  () => _sendEmail('sarci@sarci.ci'),
                ),
                _buildContactInfo(
                  'Téléphone',
                  '+225 2723467139',
                  Icons.phone,
                  () => _makePhoneCall('+2252723467139'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section 7: Modifications
            _buildSection(
              title: '7. Modifications de la politique',
              content:
                  'Nous pouvons mettre à jour cette politique de confidentialité de temps en temps. La version la plus récente sera toujours disponible dans l\'application.',
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Column(
                children: [
                  Text(
                    'Mon univers AYA par SARCI SA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yopougon Zone Industrielle, Abidjan, Côte d\'Ivoire',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
        if (children != null) ...[const SizedBox(height: 12), ...children],
      ],
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fonctions pour les actions
  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Politique de Confidentialité Aya+',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    }
  }
}
