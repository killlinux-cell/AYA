import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/loading_mixin.dart';
import '../widgets/world_cup_games_section.dart';
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
              // Mini-jeux (Scratch & Spin) masqués temporairement — réactiver le moment venu.
            ],
          ),
        ),
      ),
    );
  }
}
