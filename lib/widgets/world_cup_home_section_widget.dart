import 'package:flutter/material.dart';
import '../models/world_cup_models.dart';
import '../services/django_auth_service.dart';
import '../services/world_cup_service.dart';
import '../theme/app_colors.dart';
import '../widgets/world_cup_flag.dart';
import '../screens/world_cup_predictions_screen.dart';
import '../screens/world_cup_rankings_screen.dart';

class WorldCupHomeSectionWidget extends StatefulWidget {
  const WorldCupHomeSectionWidget({super.key});

  @override
  State<WorldCupHomeSectionWidget> createState() =>
      _WorldCupHomeSectionWidgetState();
}

class _WorldCupHomeSectionWidgetState extends State<WorldCupHomeSectionWidget> {
  final WorldCupService _service =
      WorldCupService(DjangoAuthService.instance);

  List<WorldCupMatch> _upcomingMatches = [];
  int _userRank = 0;
  int _userPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _service.getMatches();
      final rankings = await _service.getRankings();

      final open = matches.where((m) => m.canPredict).take(2).toList();
      WorldCupRankingEntry? me;
      for (final r in rankings) {
        if (r.isCurrentUser) {
          me = r;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _upcomingMatches = open;
          _userRank = me?.rank ?? 0;
          _userPoints = me?.totalPoints ?? 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pronostics Coupe du Monde',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Prédisez les scores et grimpez au classement',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else ...[
            if (_userRank > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentYellow.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.accentYellow,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Votre classement : #$_userRank • $_userPoints pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_upcomingMatches.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._upcomingMatches.map(_buildMiniMatchCard),
            ],

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Pronostiquer',
                      icon: Icons.edit_note,
                      onTap: () => _openPredictions(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Classements',
                      icon: Icons.leaderboard,
                      filled: false,
                      onTap: () => _openRankings(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMatchCard(WorldCupMatch match) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  WorldCupFlag(countryCode: match.homeTeamCode, width: 28, height: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.homeTeam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'vs',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      match.awayTeam,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  WorldCupFlag(countryCode: match.awayTeamCode, width: 28, height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = true,
  }) {
    return Material(
      color: filled ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: Colors.white54),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: filled ? const Color(0xFF1B4332) : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: filled ? const Color(0xFF1B4332) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPredictions(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorldCupPredictionsScreen(),
      ),
    );
    _loadSummary();
  }

  void _openRankings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorldCupRankingsScreen()),
    );
    _loadSummary();
  }
}
