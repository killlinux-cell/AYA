import 'package:flutter/material.dart';
import '../utils/loading_mixin.dart';
import '../theme/app_colors.dart';
import 'scratch_and_win_game_screen.dart';
import 'spin_wheel_game_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with TickerProviderStateMixin, LoadingMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardsAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardsAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _cardsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardsAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '🎮 Jeux',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête des jeux avec animation
            AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _headerAnimation.value,
                  child: Opacity(
                    opacity: _headerAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryGreen,
                            AppColors.primaryGreenLight,
                            AppColors.primaryGreenDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: AppColors.primaryGreenDark.withOpacity(0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.casino,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎯 Zone de jeux',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gagnez des points en jouant !',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    '✨ Nouveaux jeux disponibles',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Titre des jeux disponibles avec animation
            AnimatedBuilder(
              animation: _cardsAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _cardsAnimation.value)),
                  child: Opacity(
                    opacity: _cardsAnimation.value.clamp(0.0, 1.0),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryGreen,
                                AppColors.primaryGreenLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '🎮 Jeux disponibles',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Jeu Scratch & Win avec animation
            AnimatedBuilder(
              animation: _cardsAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _cardsAnimation.value)),
                  child: Opacity(
                    opacity: _cardsAnimation.value.clamp(0.0, 1.0),
                    child: _buildGameCard(
                      context,
                      title: '🎨 Scratch & Win',
                      subtitle: 'Grattez pour découvrir vos gains',
                      icon: Icons.auto_fix_high,
                      color: AppColors.primaryGreen,
                      gradientColors: const [
                        AppColors.primaryGreen,
                        AppColors.primaryGreenLight,
                      ],
                      onTap: () {
                        navigateWithLoading(
                          const ScratchAndWinGameScreen(),
                          message: 'Chargement du jeu Grattez & Gagnez...',
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Jeu Spin a wheel avec animation
            AnimatedBuilder(
              animation: _cardsAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _cardsAnimation.value)),
                  child: Opacity(
                    opacity: _cardsAnimation.value.clamp(0.0, 1.0),
                    child: _buildGameCard(
                      context,
                      title: '🎡 Spin a wheel',
                      subtitle: 'Tournez la roue de la fortune',
                      icon: Icons.casino,
                      color: AppColors.accentRed,
                      gradientColors: const [
                        AppColors.accentRed,
                        AppColors.accentRedLight,
                      ],
                      onTap: () {
                        navigateWithLoading(
                          const SpinWheelGameScreen(),
                          message: 'Chargement de la Roue de la Fortune...',
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Section des règles avec animation
            AnimatedBuilder(
              animation: _cardsAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 40 * (1 - _cardsAnimation.value)),
                  child: Opacity(
                    opacity: _cardsAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.surface, AppColors.divider],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryGreen,
                                      AppColors.primaryGreenLight,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF488950,
                                      ).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.rule,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📋 Règles des jeux',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'Comment jouer et gagner',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderPrimary,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildRuleItem(
                                  '💰',
                                  'Chaque jeu coûte 10 points à jouer',
                                ),
                                _buildRuleItem(
                                  '🎯',
                                  'Vous pouvez gagner entre 0 et 50 points',
                                ),
                                _buildRuleItem(
                                  '⏰',
                                  'Jouez une fois par jour par jeu',
                                ),
                                _buildRuleItem(
                                  '📈',
                                  'Les points gagnés sont ajoutés à votre solde',
                                ),
                                _buildRuleItem(
                                  '🔒',
                                  'Les gains sont déterminés par le serveur pour la sécurité',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    List<Color>? gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradientColors != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : null,
          color: gradientColors == null ? Colors.white : null,
          borderRadius: BorderRadius.circular(20),
          border: gradientColors != null
              ? null
              : Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: gradientColors != null
                  ? gradientColors.first.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            if (gradientColors != null)
              BoxShadow(
                color: gradientColors.last.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: -5,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: gradientColors != null
                    ? Colors.white.withOpacity(0.25)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(35),
                border: gradientColors != null
                    ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
                    : null,
                boxShadow: gradientColors != null
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: gradientColors != null ? Colors.white : color,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: gradientColors != null
                          ? AppColors.white
                          : AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      color: gradientColors != null
                          ? AppColors.white.withOpacity(0.9)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: gradientColors != null
                    ? Colors.white.withOpacity(0.25)
                    : color,
                borderRadius: BorderRadius.circular(25),
                border: gradientColors != null
                    ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: Text(
                '10 pts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: gradientColors != null ? Colors.white : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
