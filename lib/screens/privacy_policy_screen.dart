import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
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
                      Icons.privacy_tip,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Politique de confidentialité',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Protection de vos données personnelles',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contenu de la politique
            Container(
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
                  _buildSection(
                    '1. Collecte des données',
                    'Nous collectons uniquement les informations nécessaires au fonctionnement de l\'application :\n\n'
                        '• Informations de profil (nom, email)\n'
                        '• Données de connexion\n'
                        '• Historique des points et codes QR scannés\n'
                        '• Données techniques de l\'appareil',
                  ),
                  _buildSection(
                    '2. Utilisation des données',
                    'Vos données sont utilisées pour :\n\n'
                        '• Gérer votre compte utilisateur\n'
                        '• Tracker vos points et récompenses\n'
                        '• Améliorer l\'expérience utilisateur\n'
                        '• Assurer la sécurité de l\'application',
                  ),
                  _buildSection(
                    '3. Protection des données',
                    'Nous mettons en place des mesures de sécurité pour protéger vos données :\n\n'
                        '• Chiffrement des données sensibles\n'
                        '• Accès restreint aux données\n'
                        '• Sauvegarde sécurisée\n'
                        '• Mise à jour régulière des systèmes',
                  ),
                  _buildSection(
                    '4. Partage des données',
                    'Nous ne partageons vos données qu\'avec :\n\n'
                        '• Les services techniques nécessaires\n'
                        '• Les autorités si requis par la loi\n'
                        '• Votre consentement explicite',
                  ),
                  _buildSection(
                    '5. Vos droits',
                    'Vous avez le droit de :\n\n'
                        '• Accéder à vos données personnelles\n'
                        '• Corriger vos informations\n'
                        '• Supprimer votre compte\n'
                        '• Exporter vos données\n'
                        '• Retirer votre consentement',
                  ),
                  _buildSection(
                    '6. Conservation des données',
                    'Vos données sont conservées :\n\n'
                        '• Pendant la durée de votre compte\n'
                        '• Maximum 2 ans après suppression\n'
                        '• Selon les obligations légales',
                  ),
                  _buildSection(
                    '7. Cookies et traceurs',
                    'Notre application utilise :\n\n'
                        '• Des cookies de session\n'
                        '• Des traceurs de performance\n'
                        '• Des outils d\'analyse anonymisés',
                  ),
                  _buildSection(
                    '8. Modifications',
                    'Cette politique peut être mise à jour. Nous vous informerons de tout changement important.',
                  ),
                  _buildSection(
                    '9. Contact',
                    'Pour toute question sur cette politique :\n\n'
                        'Email : privacy@aya-huiles.com\n'
                        'Adresse : Aya Huiles Team\n'
                        'Site web : orapide.shop',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informations légales
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Informations légales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cette politique de confidentialité est conforme au RGPD (Règlement Général sur la Protection des Données) et aux lois françaises en vigueur.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dernière mise à jour : Décembre 2024',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
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

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF424242),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
