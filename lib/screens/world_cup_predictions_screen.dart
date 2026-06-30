import 'package:flutter/material.dart';
import '../models/world_cup_models.dart';
import '../services/django_auth_service.dart';
import '../services/world_cup_service.dart';
import '../widgets/world_cup_games_section.dart';
import '../widgets/world_cup_match_card.dart';
import 'world_cup_rankings_screen.dart';

class WorldCupPredictionsScreen extends StatefulWidget {
  const WorldCupPredictionsScreen({super.key});

  @override
  State<WorldCupPredictionsScreen> createState() =>
      _WorldCupPredictionsScreenState();
}

class _WorldCupPredictionsScreenState extends State<WorldCupPredictionsScreen> {
  final WorldCupService _service =
      WorldCupService(DjangoAuthService.instance);
  final GlobalKey<WorldCupGamesSectionState> _sectionKey =
      GlobalKey<WorldCupGamesSectionState>();

  List<WorldCupMatch> _finishedMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinished();
  }

  Future<void> _loadFinished() async {
    setState(() => _isLoading = true);
    final matches = await _service.getMatches();
    if (mounted) {
      setState(() {
        _finishedMatches = matches.where((m) => m.isFinished).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadFinished(),
      _sectionKey.currentState?.loadMatches() ?? Future.value(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'Pronostics CDM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Coupe du Monde 2026',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorldCupRankingsScreen(),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: const Color(0xFF1B4332),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            WorldCupGamesSection(key: _sectionKey),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_finishedMatches.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionHeader('📋 Matchs terminés'),
              const SizedBox(height: 10),
              ..._finishedMatches.map(
                (m) => WorldCupMatchCard(match: m, showStats: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF1B4332),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
