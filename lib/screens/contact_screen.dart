import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../config/fonts.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Contact & Support',
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
            // Section Informations Générales
            _buildSection(
              title: 'Informations Générales',
              icon: Icons.business,
              color: AppColors.primaryGreen,
              children: [
                _buildInfoCard(
                  'Siège Social',
                  'Yopougon Zone Industrielle\nAbidjan, Côte d\'Ivoire',
                  Icons.location_on,
                ),
                _buildInfoCard(
                  'Adresse Postale',
                  '04 BP 1244 Abidjan 04',
                  Icons.mail,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Contact
            _buildSection(
              title: 'Nous Contacter',
              icon: Icons.phone,
              color: AppColors.accentRed,
              children: [
                _buildContactCard(
                  'Téléphone',
                  '+225 2723467139',
                  Icons.phone,
                  () => _makePhoneCall('+2252723467139'),
                ),
                _buildContactCard(
                  'Fax',
                  '+225 2723466618',
                  Icons.fax,
                  () => _makePhoneCall('+2252723466618'),
                ),
                _buildContactCard(
                  'Email',
                  'sarci@sarci.ci',
                  Icons.email,
                  () => _sendEmail('sarci@sarci.ci'),
                ),
                _buildContactCard(
                  'Site Web',
                  'www.sarci.ci',
                  Icons.web,
                  () => _openWebsite('https://www.sarci.ci'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Réseaux Sociaux
            _buildSection(
              title: 'Suivez-nous',
              icon: Icons.share,
              color: AppColors.accentYellow,
              children: [
                _buildSocialCard(
                  'Instagram',
                  '@aya_sarci',
                  Icons.camera_alt,
                  () => _openInstagram('@aya_sarci'),
                ),
                _buildSocialCard(
                  'Facebook',
                  '@AYA Afrique de l\'Ouest',
                  Icons.facebook,
                  () => _openFacebook('@AYA Afrique de l\'Ouest'),
                ),
                _buildSocialCard(
                  'TikTok',
                  '@aya.huile.vgtale',
                  Icons.video_library,
                  () => _openTikTok('@aya.huile.vgtale'),
                ),
                _buildSocialCard(
                  'YouTube',
                  'SARCI SA TV',
                  Icons.play_circle_filled,
                  () => _openYouTube('SARCI SA TV'),
                ),
                _buildSocialCard(
                  'LinkedIn',
                  'SARCI SA',
                  Icons.work,
                  () => _openLinkedIn('SARCI SA'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Support
            _buildSection(
              title: 'Support Technique',
              icon: Icons.support_agent,
              color: AppColors.primaryGreen,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderPrimary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Besoin d\'aide ?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Notre équipe est disponible du lundi au vendredi de 8h à 17h pour vous aider.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _sendEmail('sarci@sarci.ci'),
                        icon: const Icon(Icons.email, size: 18),
                        label: const Text('Envoyer un Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    String title,
    String content,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        content,
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
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialCard(
    String platform,
    String handle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderPrimary),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accentYellow, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platform,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        handle,
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
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fonctions pour les actions
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Aya+',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWebsite(String url) async {
    final Uri websiteUri = Uri.parse(url);
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInstagram(String handle) async {
    final Uri instagramUri = Uri.parse(
      'https://www.instagram.com/${handle.replaceAll('@', '')}',
    );
    if (await canLaunchUrl(instagramUri)) {
      await launchUrl(instagramUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openFacebook(String page) async {
    final Uri facebookUri = Uri.parse(
      'https://www.facebook.com/${page.replaceAll('@', '').replaceAll(' ', '')}',
    );
    if (await canLaunchUrl(facebookUri)) {
      await launchUrl(facebookUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTikTok(String handle) async {
    final Uri tiktokUri = Uri.parse(
      'https://www.tiktok.com/@${handle.replaceAll('@', '')}',
    );
    if (await canLaunchUrl(tiktokUri)) {
      await launchUrl(tiktokUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openYouTube(String channel) async {
    final Uri youtubeUri = Uri.parse(
      'https://www.youtube.com/@${channel.replaceAll(' ', '').toLowerCase()}',
    );
    if (await canLaunchUrl(youtubeUri)) {
      await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLinkedIn(String company) async {
    final Uri linkedinUri = Uri.parse(
      'https://www.linkedin.com/company/${company.replaceAll(' ', '-').toLowerCase()}',
    );
    if (await canLaunchUrl(linkedinUri)) {
      await launchUrl(linkedinUri, mode: LaunchMode.externalApplication);
    }
  }
}
