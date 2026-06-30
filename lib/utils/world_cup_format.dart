/// Formatage dates et stats affichage matchs CDM.

class SimulatedOutcomeStat {
  final String key;
  final double odd;
  final int percent;

  const SimulatedOutcomeStat({
    required this.key,
    required this.odd,
    required this.percent,
  });
}

const _frDays = [
  'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
];
const _frMonths = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String formatMatchDayHeader(DateTime dateTime) {
  final d = dateTime.toUtc();
  final weekday = _frDays[d.weekday - 1];
  return '$weekday ${d.day} ${_frMonths[d.month - 1]}';
}

String formatMatchTimeShort(DateTime dateTime) {
  final d = dateTime.toUtc();
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return m == '00' ? '${d.hour}h00' : '${h}h$m';
}

String formatCountdown(Duration remaining) {
  if (remaining.isNegative) return '00 : 00 : 00 : 00';
  final days = remaining.inDays;
  final hours = remaining.inHours % 24;
  final minutes = remaining.inMinutes % 60;
  final seconds = remaining.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(days)} : ${two(hours)} : ${two(minutes)} : ${two(seconds)}';
}

List<SimulatedOutcomeStat> simulatedOutcomeStats(String seed) {
  final h = seed.hashCode.abs();
  final p1 = 55 + (h % 22);
  final pN = 8 + ((h ~/ 7) % 14);
  final p2 = (100 - p1 - pN).clamp(5, 40);
  final adjP1 = 100 - pN - p2;
  return [
    SimulatedOutcomeStat(
      key: '1',
      odd: 1.35 + (h % 30) / 100,
      percent: adjP1,
    ),
    SimulatedOutcomeStat(
      key: 'N',
      odd: 3.5 + (h % 15) / 10,
      percent: pN,
    ),
    SimulatedOutcomeStat(
      key: '2',
      odd: 4.5 + (h % 35) / 10,
      percent: p2,
    ),
  ];
}

List<bool> simulatedFormDots(String? teamCode) {
  final h = (teamCode ?? 'xx').hashCode.abs();
  return List.generate(3, (i) => ((h >> i) & 1) == 1);
}

String outcomeKeyFromScores(int home, int away) {
  if (home > away) return '1';
  if (home < away) return '2';
  return 'N';
}

Map<String, List<T>> groupMatchesByDay<T>(
  List<T> items,
  DateTime Function(T) getDate,
) {
  final map = <String, List<T>>{};
  for (final item in items) {
    final d = getDate(item).toUtc();
    final key = '${d.year}-${d.month}-${d.day}';
    map.putIfAbsent(key, () => []).add(item);
  }
  return map;
}
