import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/points_display_widget.dart';
import '../widgets/collected_qr_display_widget.dart';
import '../widgets/bonus_section_widget.dart';
import '../widgets/navigation_bar_widget.dart';
import '../widgets/personal_qr_card_widget.dart';
import 'games_screen.dart';
import 'qr_scanner_screen.dart';
import 'personal_qr_screen.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';
import 'vendor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const GamesScreen(),
    const QRScannerScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print(
          'HomeScreen: AuthProvider.isAuthenticated = ${authProvider.isAuthenticated}',
        );
        print(
          'HomeScreen: AuthProvider.currentUser = ${authProvider.currentUser?.id}',
        );

        // Vérifier si l'utilisateur est authentifié
        if (!authProvider.isAuthenticated) {
          print(
            'HomeScreen: User not authenticated, redirecting to AuthScreen',
          );
          // Rediriger vers l'écran de connexion
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          });
          // Retourner un écran de chargement pendant la redirection
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: NavigationBarWidget(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec logo et heure
            const HeaderWidget(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Affichage des points
                    const PointsDisplayWidget(),
                    const SizedBox(height: 20),

                    // Affichage des codes QR collectés
                    const CollectedQRDisplayWidget(),
                    const SizedBox(height: 20),

                    // Section bonus
                    const BonusSectionWidget(),
                    const SizedBox(height: 20),

                    // Section des actions rapides
                    _buildQuickActions(context),
                    const SizedBox(height: 20),

                    // Carte QR Personnel stylée
                    const PersonalQRCardWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
            context,
            icon: Icons.store,
            title: 'Mode Vendeur',
            subtitle: 'Scanner les échanges clients',
            color: const Color(0xFF9C27B0),
            onTap: () {
              // Navigation vers l'interface vendeur
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const VendorScreen()),
              );
            },
        ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.games,
                title: 'Jouer',
                subtitle: 'Gagner des points',
                color: const Color(0xFFFF9800),
                onTap: () {
                  // Navigation vers les jeux
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GamesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Carte pour voir son QR code personnel
      /*  _buildActionCard(
          context,
          icon: Icons.qr_code,
          title: 'Mon QR Code',
          subtitle: 'Voir mon identifiant personnel',
          color: const Color(0xFF2196F3),
          onTap: () {
            // Navigation vers le QR code personnel
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PersonalQRScreen()),
            );
          },
        ), */


      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
