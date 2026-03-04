/// Catalogue d'échange partagé : paliers et récompenses correspondantes
/// Utilisé par l'écran d'échange client et l'affichage vendeur
const List<Map<String, dynamic>> exchangeCatalog = [
  {'points': 50, 'reward': 'Huile 0,45L ou margarine 250g'},
  {'points': 150, 'reward': 'Huile 0,9L ou pâte à tartiner'},
  {'points': 300, 'reward': 'Huile 3L'},
  {'points': 500, 'reward': 'Box Aya (mix produits)'},
  {'points': 1000, 'reward': 'Carton huile 0,9L × 12'},
  {'points': 2000, 'reward': '2 × 5L huile'},
  {'points': 5000, 'reward': 'Carton huile 5L × 4'},
];

/// Retourne la récompense pour un montant de points (palier exact ou inférieur le plus proche)
String? getRewardForPoints(int points) {
  if (points <= 0) return null;
  Map<String, dynamic>? bestMatch;
  for (final tier in exchangeCatalog) {
    final tierPoints = tier['points'] as int;
    if (tierPoints <= points) {
      if (bestMatch == null || tierPoints > (bestMatch['points'] as int)) {
        bestMatch = tier;
      }
    }
  }
  return bestMatch?['reward'] as String?;
}
