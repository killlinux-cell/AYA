import 'package:flutter/material.dart';
import '../models/world_cup_models.dart';
import '../services/django_auth_service.dart';
import '../services/world_cup_service.dart';
import '../theme/app_colors.dart';

class WorldCupRankingsScreen extends StatefulWidget {
  const WorldCupRankingsScreen({super.key});

  @override
  State<WorldCupRankingsScreen> createState() => _WorldCupRankingsScreenState();
}

class _WorldCupRankingsScreenState extends State<WorldCupRankingsScreen> {
  final WorldCupService _service =
      WorldCupService(DjangoAuthService.instance);

  List<WorldCupRankingEntry> _rankings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() => _isLoading = true);
    final rankings = await _service.getRankings();
    if (mounted) {
      setState(() {
        _rankings = rankings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Classements CDM',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRankings),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRankings,
        color: AppColors.primaryGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _rankings.isEmpty
                ? _buildEmpty()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildRulesCard(),
                      const SizedBox(height: 16),
                      ..._rankings.map(_buildRankingCard),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Icon(Icons.leaderboard, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Le classement sera disponible bientôt',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Comment gagner des points ?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Score exact : 10 points\n'
            '• Bon résultat (vainqueur ou nul) : 5 points\n'
            '• Participation (raté) : 1 point',
            style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(WorldCupRankingEntry entry) {
    final isTop3 = entry.rank <= 3;
    final isMe = entry.isCurrentUser;

    Color? medalColor;
    if (entry.rank == 1) medalColor = const Color(0xFFFFD700);
    if (entry.rank == 2) medalColor = const Color(0xFFC0C0C0);
    if (entry.rank == 3) medalColor = const Color(0xFFCD7F32);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF1B4332).withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(color: const Color(0xFF1B4332), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isTop3
                ? medalColor!.withOpacity(0.2)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isTop3
                ? Icon(Icons.emoji_events, color: medalColor, size: 24)
                : Text(
                    '#${entry.rank}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        title: Text(
          entry.displayName + (isMe ? ' (vous)' : ''),
          style: TextStyle(
            fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
            color: isMe ? const Color(0xFF1B4332) : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${entry.exactScores} scores exacts • ${entry.correctOutcomes} bons résultats',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${entry.totalPoints} pts',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }
}
