import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/deep_link_service.dart';
import '../services/vendor_auth_service.dart';
import '../services/app_update_service.dart';
import '../widgets/loading_widget.dart';
import '../theme/app_colors.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'vendor_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (mounted) {
      final blocked = await AppUpdateService().handleStartupUpdate(context);
      if (!mounted || blocked) return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Attendre la restauration de la session avant de naviguer
    await authProvider.initialized;

    // Laisser l'animation du splash se jouer (minimum 1,5 s)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      final vendorAuthService = VendorAuthService();

      // Vendeur connecté → écran vendeur
      if (vendorAuthService.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const VendorScreen()),
        );
      } else if (authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DeepLinkService.consumePendingQr();
        });
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Image.asset(
                        'assets/icons/univers.png',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Mon univers AYA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Trésor de mon Pays.',
                      style: TextStyle(fontSize: 16, color: AppColors.white),
                    ),
                    const SizedBox(height: 40),
                    // Utilisation du widget de chargement personnalisé
                    const LoadingWidget(
                      message: 'Initialisation...',
                      size: 40.0,
                      backgroundColor: Colors.transparent,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
