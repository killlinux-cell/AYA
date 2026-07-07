import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/points_display_widget.dart';
import '../widgets/collected_qr_display_widget.dart';
import '../widgets/bonus_section_widget.dart';
import '../widgets/navigation_bar_widget.dart';
import '../widgets/vendors_card_widget.dart';
import '../widgets/api_video_widget.dart';
import '../widgets/home_banner_widget.dart';
import '../widgets/world_cup_home_section_widget.dart';
import '../utils/loading_mixin.dart';
import '../theme/app_colors.dart';
import 'games_screen.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';
import 'recettes_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with LoadingMixin {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const GamesScreen(),
    const RecettesScreen(),
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

        // Attendre la fin du chargement de session avant toute redirection
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with WidgetsBindingObserver, LoadingMixin {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 HomeScreen: App resumed, rafraîchissement des données...');
      final authProvider = context.read<AuthProvider>();
      authProvider.refreshUserData();
      BonusSectionWidget.refresh(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header avec logo et heure - commence tout en haut
          const HeaderWidget(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bannière publicitaire pilotée par l'API
                    const HomeBannerWidget(),

                    // Affichage des points
                    const PointsDisplayWidget(),
                    const SizedBox(height: 20),

                    // Affichage des codes QR collectés
                    const CollectedQRDisplayWidget(),
                    const SizedBox(height: 20),

                    // Section bonus
                    const BonusSectionWidget(),
                    const SizedBox(height: 20),

                    // Pronostics Coupe du Monde
                    const WorldCupHomeSectionWidget(),
                    const SizedBox(height: 20),

                    // Section des actions rapides
                    _buildQuickActions(context),
                    const SizedBox(height: 20),

                    // Carte des vendeurs disponibles
                    const VendorsCardWidget(),

                    // Vidéo publicitaire de l'API (lecture aléatoire)
                    const ApiVideoWidget(),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rafraîchir les données de l'utilisateur
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      print('🔄 HomeScreen: Rafraîchissement des données utilisateur...');

      // Rafraîchir les données via AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserData();

      // Rafraîchir la section bonus
      BonusSectionWidget.refresh(context);

      // Rafraîchir bannière et vidéos publicitaires
      HomeBannerWidget.refresh(context);
      ApiVideoWidget.refresh(context);

      print('✅ HomeScreen: Données rafraîchies avec succès');

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Données actualisées !'),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ HomeScreen: Erreur lors du rafraîchissement: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Erreur lors de l\'actualisation: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
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
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.games,
                title: 'Jouer',
                subtitle: 'Gagner des points',
                color: AppColors.accentYellow,
                onTap: () {
                  navigateWithLoading(
                    const GamesScreen(),
                    message: 'Chargement des jeux...',
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
          color: AppColors.primaryGreen,
          onTap: () {
            // Navigation vers le QR code personnel avec chargement
            navigateWithLoading(
              const PersonalQRScreen(),
              message: 'Chargement du QR personnel...',
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
                color: AppColors.textPrimary,
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
