import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'auth_screen.dart';
import 'personal_qr_screen.dart';
import 'edit_profile_screen.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'contact_screen.dart';
import 'qr_generator_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DEBUG: Ajouter des logs de débogage
    print('=== DEBUG PROFILE SCREEN ===');
    print(
      'AuthProvider.isAuthenticated: ${context.read<AuthProvider>().isAuthenticated}',
    );
    print(
      'AuthProvider.currentUser: ${context.read<AuthProvider>().currentUser?.id}',
    );
    print('UserProvider.user: ${context.read<UserProvider>().user?.id}');
    print('UserProvider.isLoading: ${context.read<UserProvider>().isLoading}');
    print('UserProvider.error: ${context.read<UserProvider>().error}');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF488950),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Afficher l'état de chargement
          if (authProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF488950)),
                  SizedBox(height: 16),
                  Text(
                    'Chargement du profil...',
                    style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                  ),
                ],
              ),
            );
          }

          // Afficher les erreurs
          if (authProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFF44336),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.error ?? 'Erreur inconnue',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (authProvider.isAuthenticated) {
                        // Recharger les données utilisateur
                        authProvider.refreshUser();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF488950),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Réessayer'),
                  ),
                  const SizedBox(height: 16),
                  // Bouton pour créer le profil si nécessaire
                  if (_isProfileMissingError(authProvider.error))
                    ElevatedButton(
                      onPressed: () {
                        if (authProvider.isAuthenticated) {
                          // Recharger les données utilisateur
                          authProvider.refreshUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Créer le Profil'),
                    ),
                ],
              ),
            );
          }

          // Vérifier si l'utilisateur est connecté
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Color(0xFF757575)),
                  SizedBox(height: 16),
                  Text(
                    'Vous n\'êtes pas connecté',
                    style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                  ),
                ],
              ),
            );
          }

          // Utiliser les données de l'AuthProvider
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 64, color: Color(0xFF757575)),
                  SizedBox(height: 16),
                  Text(
                    'Aucune donnée utilisateur trouvée',
                    style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                  ),
                ],
              ),
            );
          }

          // Vérifier si c'est un nouvel utilisateur (données vides)
          final isNewUser =
              user.availablePoints == 0 &&
              user.collectedQRCodes == 0 &&
              user.exchangedPoints == 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // En-tête du profil
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF488950), Color(0xFF60A066)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF488950).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      // Message spécial pour les nouveaux utilisateurs
                      if (isNewUser) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.celebration,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Bienvenue ! Commencez à collecter des points',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat(
                            'Points',
                            user.availablePoints.toString(),
                            Icons.stars,
                          ),
                          _buildProfileStat(
                            'Codes QR',
                            user.collectedQRCodes.toString(),
                            Icons.qr_code,
                          ),
                          _buildProfileStat(
                            'Échangés',
                            user.exchangedPoints.toString(),
                            Icons.swap_horiz,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Conseils pour les nouveaux utilisateurs
                if (isNewUser) ...[
                  Container(
                    width: double.infinity,
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
                            Icon(
                              Icons.lightbulb,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Comment commencer ?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTipItem(
                          '1. Scannez des codes QR',
                          'Allez dans "Scanner" pour collecter vos premiers points',
                          Icons.qr_code_scanner,
                        ),
                        const SizedBox(height: 8),
                        _buildTipItem(
                          '2. Jouez aux mini-jeux',
                          'Visitez la section "Jeux" pour gagner des points bonus',
                          Icons.games,
                        ),
                        const SizedBox(height: 8),
                        _buildTipItem(
                          '3. Consultez votre QR personnel',
                          'Allez dans "Mon QR" pour voir votre identifiant unique',
                          Icons.qr_code,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Options du profil
                _buildProfileSection(
                  title: 'Informations du compte',
                  children: [
                    _buildProfileOption(
                      icon: Icons.qr_code,
                      title: 'Mon QR Code Personnel',
                      subtitle: 'Voir mon identifiant unique',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonalQRScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: Icons.person,
                      title: 'Modifier le profil',
                      subtitle: 'Changer vos informations personnelles',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: Icons.email,
                      title: 'Changer l\'email',
                      subtitle: 'Modifier votre adresse email',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangeEmailScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: Icons.lock,
                      title: 'Changer le mot de passe',
                      subtitle: 'Mettre à jour votre mot de passe',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Autres options
                _buildProfileSection(
                  title: 'Autres',
                  children: [
                    _buildProfileOption(
                      icon: Icons.help,
                      title: 'Aide et support',
                      subtitle: 'Besoin d\'aide ?',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: Icons.contact_phone,
                      title: 'Contact',
                      subtitle: 'Nous contacter',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: Icons.info,
                      title: 'À propos',
                      subtitle: 'Informations sur l\'application',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      icon: Icons.privacy_tip,
                      title: 'Politique de confidentialité',
                      subtitle: 'Lire notre politique',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Bouton de déconnexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildProfileSection({
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

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF488950).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF488950), size: 20),
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
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Color(0xFF757575),
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildTipItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Se déconnecter'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF327239), // Vert Aya+
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Fermer le dialogue
                  Navigator.of(context).pop();

                  // Afficher un indicateur de chargement
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Déconnexion en cours...'),
                        ],
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Effectuer la déconnexion
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  // Plus besoin de réinitialiser le UserProvider

                  // Effectuer la déconnexion
                  await authProvider.logout();

                  // Vérifier que la déconnexion a bien fonctionné
                  if (context.mounted) {
                    // Rediriger immédiatement vers la page de connexion
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                      (route) => false,
                    );

                    // Afficher un message de succès
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Déconnexion réussie'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Afficher l'erreur
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la déconnexion: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );

                    // Forcer la redirection même en cas d'erreur
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }

  // Méthode _getErrorMessage supprimée - plus nécessaire

  bool _isProfileMissingError(String? error) {
    return error?.contains('Profile not found') ?? false;
  }

  void _showAuthStatus(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('État d\'Authentification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AuthProvider.isAuthenticated: ${authProvider.isAuthenticated}',
              ),
              Text(
                'AuthProvider.currentUser: ${authProvider.currentUser?.id ?? 'null'}',
              ),
              Text('UserProvider: Non utilisé (données dans AuthProvider)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _forceLogout(BuildContext context) async {
    try {
      print('=== FORCE LOGOUT TEST ===');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Afficher l'état avant la déconnexion
      print('Before logout:');
      print('  AuthProvider.isAuthenticated: ${authProvider.isAuthenticated}');
      print('  AuthProvider.currentUser: ${authProvider.currentUser?.id}');

      // Effectuer la déconnexion
      await authProvider.logout();
      print('AuthProvider logout completed');

      // Afficher l'état après la déconnexion
      print('After logout:');
      print('  AuthProvider.isAuthenticated: ${authProvider.isAuthenticated}');
      print('  AuthProvider.currentUser: ${authProvider.currentUser?.id}');
      // UserProvider non utilisé

      // Rediriger vers l'écran de connexion
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déconnexion forcée réussie'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error during force logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion forcée: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
