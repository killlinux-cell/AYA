import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/world_cup_models.dart';
import '../services/django_auth_service.dart';
import '../services/world_cup_service.dart';
import '../theme/app_colors.dart';
import '../widgets/world_cup_flag.dart';
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

  List<WorldCupMatch> _matches = [];
  bool _isLoading = true;
  String? _submittingMatchId;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    final matches = await _service.getMatches();
    if (mounted) {
      setState(() {
        _matches = matches;
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
          'Pronostics CDM',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Classements',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorldCupRankingsScreen(),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMatches),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMatches,
        color: AppColors.primaryGreen,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _matches.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _matches.length,
                    itemBuilder: (context, index) =>
                        _buildMatchCard(_matches[index]),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        SizedBox(height: 80),
        Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Aucun match disponible pour le moment',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(WorldCupMatch match) {
    final hasPrediction = match.userPrediction != null;
    final canEdit = match.canPredict;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.groupName != null
                        ? '${match.stage} • ${match.groupName}'
                        : match.stage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ),
                const Spacer(),
                if (match.isFinished)
                  _statusChip('Terminé', Colors.grey)
                else if (hasPrediction)
                  _statusChip('Pronostic envoyé', AppColors.primaryGreen)
                else if (canEdit)
                  _statusChip('À pronostiquer', AppColors.accentYellow)
                else
                  _statusChip('Fermé', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _teamColumn(match.homeTeam, match.homeTeamCode)),
                _scoreSection(match),
                Expanded(child: _teamColumn(match.awayTeam, match.awayTeamCode, alignEnd: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  match.formattedDate,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                if (match.userPrediction?.pointsEarned != null) ...[
                  const Spacer(),
                  Text(
                    '+${match.userPrediction!.pointsEarned} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ],
            ),
            if (canEdit && !hasPrediction) ...[
              const SizedBox(height: 16),
              _PredictionForm(
                match: match,
                isSubmitting: _submittingMatchId == match.id,
                onSubmit: (home, away) => _submit(match, home, away),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _teamColumn(String name, String? code, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignEnd) WorldCupFlag(countryCode: code, width: 32, height: 22),
            if (!alignEnd) const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            if (alignEnd) const SizedBox(width: 8),
            if (alignEnd) WorldCupFlag(countryCode: code, width: 32, height: 22),
          ],
        ),
        if (code != null)
          Padding(
            padding: EdgeInsets.only(top: 4, left: alignEnd ? 0 : 40, right: alignEnd ? 40 : 0),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _scoreSection(WorldCupMatch match) {
    if (match.isFinished) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '${match.homeScore ?? 0} - ${match.awayScore ?? 0}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    }
    if (match.userPrediction != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          match.userPrediction!.scoreLabel,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'vs',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
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
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      _loadMatches();
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

class _PredictionForm extends StatefulWidget {
  final WorldCupMatch match;
  final bool isSubmitting;
  final Future<void> Function(int home, int away) onSubmit;

  const _PredictionForm({
    required this.match,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<_PredictionForm> createState() => _PredictionFormState();
}

class _PredictionFormState extends State<_PredictionForm> {
  final _homeController = TextEditingController(text: '0');
  final _awayController = TextEditingController(text: '0');

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre pronostic',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _scoreField(_homeController, widget.match.homeTeam)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _scoreField(_awayController, widget.match.awayTeam)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: widget.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Valider mon pronostic',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreField(TextEditingController controller, String team) {
    return Column(
      children: [
        Text(
          team,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    final home = int.tryParse(_homeController.text) ?? 0;
    final away = int.tryParse(_awayController.text) ?? 0;
    if (home < 0 || home > 20 || away < 0 || away > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score invalide (0 à 20)')),
      );
      return;
    }
    await widget.onSubmit(home, away);
  }
}
