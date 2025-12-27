import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Widget de chargement réutilisable affichant l'image loading.png
class LoadingWidget extends StatefulWidget {
  /// Message de chargement optionnel
  final String? message;

  /// Couleur de fond du widget
  final Color? backgroundColor;

  /// Taille de l'image de chargement
  final double size;

  /// Indique si le widget doit occuper tout l'écran
  final bool fullScreen;

  /// Opacité du fond
  final double opacity;

  const LoadingWidget({
    super.key,
    this.message,
    this.backgroundColor,
    this.size = 80.0,
    this.fullScreen = false,
    this.opacity = 0.8,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animation de rotation pour l'image de chargement
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animation de pulsation pour l'effet de respiration
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Démarrer les animations
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Image.asset(
                  'assets/icons/loading.png',
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 24),
          Text(
            widget.message!,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (widget.fullScreen) {
      return Scaffold(
        backgroundColor:
            widget.backgroundColor ??
            AppColors.black.withOpacity(widget.opacity),
        body: Center(child: content),
      );
    }

    return Container(
      color:
          widget.backgroundColor ?? AppColors.black.withOpacity(widget.opacity),
      child: Center(child: content),
    );
  }
}

/// Widget de chargement en overlay pour les appels API
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          LoadingWidget(
            message: message,
            fullScreen: true,
            backgroundColor: AppColors.black.withOpacity(0.7),
          ),
      ],
    );
  }
}

/// Widget de chargement pour la navigation entre écrans
class NavigationLoadingWidget extends StatelessWidget {
  final String? message;

  const NavigationLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      message: message ?? 'Chargement...',
      fullScreen: true,
      backgroundColor: AppColors.primaryGreen,
      size: 100.0,
    );
  }
}

/// Widget de chargement pour les appels API
class ApiLoadingWidget extends StatelessWidget {
  final String? message;

  const ApiLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      message: message ?? 'Chargement des données...',
      fullScreen: true,
      backgroundColor: AppColors.black.withOpacity(0.8),
      size: 80.0,
    );
  }
}
