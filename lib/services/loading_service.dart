import 'package:flutter/material.dart';

/// Service global de gestion du chargement
class LoadingService {
  static final LoadingService _instance = LoadingService._internal();
  factory LoadingService() => _instance;
  LoadingService._internal();

  static LoadingService get instance => _instance;

  bool _isLoading = false;
  String? _loadingMessage;
  BuildContext? _context;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  /// Afficher l'écran de chargement
  void showLoading({required BuildContext context, String? message}) {
    if (_isLoading) return;

    _isLoading = true;
    _loadingMessage = message;
    _context = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ApiLoadingWidget(),
    );
  }

  /// Masquer l'écran de chargement
  void hideLoading() {
    if (!_isLoading || _context == null) return;

    _isLoading = false;
    _loadingMessage = null;

    if (_context!.mounted) {
      Navigator.of(_context!).pop();
    }

    _context = null;
  }

  /// Afficher le chargement de navigation
  void showNavigationLoading({required BuildContext context, String? message}) {
    if (_isLoading) return;

    _isLoading = true;
    _loadingMessage = message;
    _context = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NavigationLoadingWidget(message: message),
    );
  }

  /// Afficher le chargement pour les appels API
  void showApiLoading({required BuildContext context, String? message}) {
    showLoading(context: context, message: message);
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
      backgroundColor: Colors.black.withOpacity(0.8),
      size: 80.0,
    );
  }
}

/// Widget de chargement pour la navigation
class NavigationLoadingWidget extends StatelessWidget {
  final String? message;

  const NavigationLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      message: message ?? 'Chargement...',
      fullScreen: true,
      backgroundColor: const Color(0xFF488950),
      size: 100.0,
    );
  }
}

/// Widget de chargement réutilisable
class LoadingWidget extends StatefulWidget {
  final String? message;
  final Color? backgroundColor;
  final double size;
  final bool fullScreen;
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

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

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
              color: Colors.white,
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
            widget.backgroundColor ?? Colors.black.withOpacity(widget.opacity),
        body: Center(child: content),
      );
    }

    return Container(
      color: widget.backgroundColor ?? Colors.black.withOpacity(widget.opacity),
      child: Center(child: content),
    );
  }
}
