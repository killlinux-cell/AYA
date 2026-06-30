import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/world_cup_models.dart';
import '../utils/world_cup_format.dart';
import 'world_cup_flag.dart';

const _cardGreen = Color(0xFF1B4332);
const _cardGreenLight = Color(0xFF2D6A4F);

class WorldCupMatchCard extends StatefulWidget {
  final WorldCupMatch match;
  final bool showStats;
  final bool isSubmitting;
  final Future<void> Function(int home, int away)? onSubmit;

  const WorldCupMatchCard({
    super.key,
    required this.match,
    this.showStats = true,
    this.isSubmitting = false,
    this.onSubmit,
  });

  @override
  State<WorldCupMatchCard> createState() => _WorldCupMatchCardState();
}

class _WorldCupMatchCardState extends State<WorldCupMatchCard> {
  late final TextEditingController _homeCtrl;
  late final TextEditingController _awayCtrl;
  String? _selectedOutcome;

  @override
  void initState() {
    super.initState();
    final pred = widget.match.userPrediction;
    _homeCtrl = TextEditingController(
      text: pred != null ? '${pred.homeScore}' : '0',
    );
    _awayCtrl = TextEditingController(
      text: pred != null ? '${pred.awayScore}' : '0',
    );
    if (pred != null) {
      _selectedOutcome = outcomeKeyFromScores(pred.homeScore, pred.awayScore);
    }
    _homeCtrl.addListener(_syncOutcomeFromScores);
    _awayCtrl.addListener(_syncOutcomeFromScores);
  }

  @override
  void didUpdateWidget(WorldCupMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.id != widget.match.id) {
      final pred = widget.match.userPrediction;
      _homeCtrl.text = pred != null ? '${pred.homeScore}' : '0';
      _awayCtrl.text = pred != null ? '${pred.awayScore}' : '0';
      _selectedOutcome = pred != null
          ? outcomeKeyFromScores(pred.homeScore, pred.awayScore)
          : null;
    }
  }

  void _syncOutcomeFromScores() {
    final h = int.tryParse(_homeCtrl.text) ?? 0;
    final a = int.tryParse(_awayCtrl.text) ?? 0;
    setState(() => _selectedOutcome = outcomeKeyFromScores(h, a));
  }

  @override
  void dispose() {
    _homeCtrl.dispose();
    _awayCtrl.dispose();
    super.dispose();
  }

  bool get _canEdit =>
      widget.match.canPredict && widget.onSubmit != null;

  bool get _hasPrediction => widget.match.userPrediction != null;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final stats = simulatedOutcomeStats(match.id);
    final timeLabel = formatMatchTimeShort(match.kickoffAt);
    final stageLabel = match.stage.contains('1/16')
        ? '1/16 de finale'
        : match.stage;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardGreen, _cardGreenLight],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _cardGreen.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '🏆 $stageLabel - $timeLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _statusBadge(match),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _teamSide(match.homeTeam, match.homeTeamCode)),
                _scoreCenter(match),
                Expanded(child: _teamSide(match.awayTeam, match.awayTeamCode, right: true)),
              ],
            ),
            if (widget.showStats) ...[
              const SizedBox(height: 14),
              Row(
                children: stats
                    .map((s) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _outcomeStatBox(s),
                          ),
                        ))
                    .toList(),
              ),
            ],
            if (_canEdit) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.isSubmitting ? null : _handleSubmit,
                  icon: widget.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _cardGreen,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    _hasPrediction ? 'Mettre à jour mon prono' : 'Valider mon prono',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.95),
                    foregroundColor: _cardGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            if (match.isFinished && match.userPrediction?.pointsEarned != null) ...[
              const SizedBox(height: 10),
              Text(
                '+${match.userPrediction!.pointsEarned} pts',
                style: const TextStyle(
                  color: Color(0xFF95D5B2),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(WorldCupMatch match) {
    String label;
    Color bg;
    Color fg;
    if (match.isFinished) {
      label = 'TERMINÉ';
      bg = Colors.white24;
      fg = Colors.white70;
    } else if (match.userPrediction != null) {
      label = 'VALIDÉ';
      bg = Colors.white;
      fg = _cardGreen;
    } else if (match.canPredict) {
      label = 'OUVERT';
      bg = Colors.white;
      fg = _cardGreen;
    } else {
      label = 'FERMÉ';
      bg = Colors.white24;
      fg = Colors.white70;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _teamSide(String name, String? code, {bool right = false}) {
    final dots = simulatedFormDots(code);
    return Column(
      children: [
        WorldCupFlag(countryCode: code, width: 44, height: 44, circular: true),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dots
              .map((ok) => Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ok ? const Color(0xFF95D5B2) : Colors.white24,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _scoreCenter(WorldCupMatch match) {
    if (match.isFinished) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scoreBox('${match.homeScore ?? 0}', readOnly: true),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ':',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _scoreBox('${match.awayScore ?? 0}', readOnly: true),
          ],
        ),
      );
    }

    if (!_canEdit && match.userPrediction != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scoreBox('${match.userPrediction!.homeScore}', readOnly: true),
            const Text(
              ' : ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            _scoreBox('${match.userPrediction!.awayScore}', readOnly: true),
          ],
        ),
      );
    }

    if (!_canEdit) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'vs',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _scoreBox(_homeCtrl.text, controller: _homeCtrl),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              ':',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _scoreBox(_awayCtrl.text, controller: _awayCtrl),
        ],
      ),
    );
  }

  Widget _scoreBox(String value, {TextEditingController? controller, bool readOnly = false}) {
    if (readOnly || controller == null) {
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _cardGreen,
          ),
        ),
      );
    }
    return SizedBox(
      width: 36,
      height: 36,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _cardGreen,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _outcomeStatBox(SimulatedOutcomeStat stat) {
    final selected = _selectedOutcome == stat.key;
    return GestureDetector(
      onTap: _canEdit ? () => _applyQuickOutcome(stat.key) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              stat.key,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: selected ? _cardGreen : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stat.odd.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? _cardGreen : Colors.white70,
              ),
            ),
            Text(
              '${stat.percent}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? _cardGreen.withOpacity(0.8) : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyQuickOutcome(String key) {
    setState(() {
      _selectedOutcome = key;
      switch (key) {
        case '1':
          _homeCtrl.text = '1';
          _awayCtrl.text = '0';
          break;
        case 'N':
          _homeCtrl.text = '1';
          _awayCtrl.text = '1';
          break;
        case '2':
          _homeCtrl.text = '0';
          _awayCtrl.text = '1';
          break;
      }
    });
  }

  Future<void> _handleSubmit() async {
    final home = int.tryParse(_homeCtrl.text) ?? 0;
    final away = int.tryParse(_awayCtrl.text) ?? 0;
    if (home < 0 || home > 20 || away < 0 || away > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score invalide (0 à 20)')),
      );
      return;
    }
    await widget.onSubmit?.call(home, away);
  }
}
