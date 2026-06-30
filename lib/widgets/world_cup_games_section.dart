import 'dart:async';
import 'package:flutter/material.dart';
import '../models/world_cup_models.dart';
import '../services/django_auth_service.dart';
import '../services/world_cup_service.dart';
import '../utils/world_cup_format.dart';
import 'world_cup_match_card.dart';

const _darkGreen = Color(0xFF1B4332);

/// Section pronostics CDM pour l'écran Jeux (design mobile complet).
class WorldCupGamesSection extends StatefulWidget {
  final bool embedded;

  const WorldCupGamesSection({super.key, this.embedded = true});

  @override
  State<WorldCupGamesSection> createState() => WorldCupGamesSectionState();
}

class WorldCupGamesSectionState extends State<WorldCupGamesSection> {
  final WorldCupService _service =
      WorldCupService(DjangoAuthService.instance);

  List<WorldCupMatch> _matches = [];
  bool _isLoading = true;
  bool _showStats = true;
  String? _submittingMatchId;
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;

  @override
  void initState() {
    super.initState();
    loadMatches();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> loadMatches() async {
    setState(() => _isLoading = true);
    final matches = await _service.getMatches();
    if (mounted) {
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
      _updateCountdown();
    }
  }

  void _updateCountdown() {
    final upcoming = _matches
        .where((m) => m.canPredict)
        .map((m) => m.kickoffAt.toUtc())
        .toList()
      ..sort();
    if (upcoming.isEmpty) {
      if (_countdown != Duration.zero) {
        setState(() => _countdown = Duration.zero);
      }
      return;
    }
    final next = upcoming.first;
    final diff = next.difference(DateTime.now().toUtc());
    setState(() => _countdown = diff.isNegative ? Duration.zero : diff);
  }

  int get _validatedCount =>
      _matches.where((m) => m.userPrediction != null).length;

  int get _openCount => _matches.where((m) => m.canPredict).length;

  List<WorldCupMatch> get _upcomingOpen =>
      _matches.where((m) => m.canPredict || !m.isFinished).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          const Text(
            '⚽ Pronostics - Coupe du Monde 2026',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildToolbar(),
        const SizedBox(height: 14),
        _buildZoneCard(),
        const SizedBox(height: 20),
        _buildSectionTitle(),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: _darkGreen)),
          )
        else if (_upcomingOpen.isEmpty)
          _buildEmpty()
        else
          ..._buildGroupedMatches(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                formatCountdown(_countdown),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const Text(
          'Stats',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF495057),
          ),
        ),
        const SizedBox(width: 6),
        Switch(
          value: _showStats,
          onChanged: (v) => setState(() => _showStats = v),
          activeTrackColor: _darkGreen.withOpacity(0.5),
          activeThumbColor: _darkGreen,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildZoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zone Pronostics',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Score exact +10 · Bon +5 · Joué +1',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🎯 $_validatedCount/$_openCount pronostics validés',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '⚽ Matchs à venir',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF212529),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Text(
        'Aucun match à pronostiquer pour le moment',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  List<Widget> _buildGroupedMatches() {
    final grouped = groupMatchesByDay(
      _upcomingOpen,
      (m) => m.kickoffAt,
    );
    final keys = grouped.keys.toList()..sort();

    final widgets = <Widget>[];
    for (final key in keys) {
      final dayMatches = grouped[key]!;
      final dayHeader = formatMatchDayHeader(dayMatches.first.kickoffAt);
      final dayOpen = dayMatches.where((m) => m.canPredict).length;
      final dayValidated = dayMatches
          .where((m) => m.userPrediction != null)
          .length;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Text(
                '🏆 $dayHeader',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9ECEF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$dayValidated / $dayOpen',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      for (final match in dayMatches) {
        widgets.add(
          WorldCupMatchCard(
            match: match,
            showStats: _showStats,
            isSubmitting: _submittingMatchId == match.id,
            onSubmit: match.canPredict
                ? (h, a) => _submit(match, h, a)
                : null,
          ),
        );
      }
    }
    return widgets;
  }

  Future<void> _submit(WorldCupMatch match, int home, int away) async {
    setState(() => _submittingMatchId = match.id);
    final result = await _service.submitPrediction(
      matchId: match.id,
      homeScore: home,
      awayScore: away,
    );
    if (!mounted) return;
    setState(() => _submittingMatchId = null);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Pronostic enregistré'),
          backgroundColor: _darkGreen,
        ),
      );
      await loadMatches();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Erreur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
