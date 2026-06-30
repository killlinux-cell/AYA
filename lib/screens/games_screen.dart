import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/loading_mixin.dart';
import '../widgets/world_cup_games_section.dart';
import 'scratch_and_win_game_screen.dart';
import 'spin_wheel_game_screen.dart';
import 'world_cup_rankings_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with LoadingMixin {
  final GlobalKey<WorldCupGamesSectionState> _wcSectionKey =
      GlobalKey<WorldCupGamesSectionState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              '🎮 Jeux',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              '⚽ Pronostics - Coupe du Monde 2026',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Classement',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorldCupRankingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _wcSectionKey.currentState?.loadMatches(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () async {
          await _wcSectionKey.currentState?.loadMatches();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorldCupGamesSection(key: _wcSectionKey),
              const SizedBox(height: 28),
              _miniGamesHeader(),
              const SizedBox(height: 14),
              _buildMiniGameCard(
                title: '🎨 Scratch & Win',
                subtitle: 'Grattez pour découvrir vos gains',
                icon: Icons.auto_fix_high,
                colors: const [Color(0xFF1B4332), Color(0xFF40916C)],
                onTap: () => navigateWithLoading(
                  const ScratchAndWinGameScreen(),
                  message: 'Chargement...',
                ),
              ),
              const SizedBox(height: 12),
              _buildMiniGameCard(
                title: '🎡 Spin a wheel',
                subtitle: 'Tournez la roue de la fortune',
                icon: Icons.casino,
                colors: const [Color(0xFFa93236), Color(0xFFC54A4E)],
                onTap: () => navigateWithLoading(
                  const SpinWheelGameScreen(),
                  message: 'Chargement...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniGamesHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '🎮 Mini-jeux',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '10 pts',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
