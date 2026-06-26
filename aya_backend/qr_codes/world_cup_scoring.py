"""Calcul des points pour les pronostics Coupe du Monde."""


def calculate_prediction_points(
    predicted_home: int,
    predicted_away: int,
    actual_home: int,
    actual_away: int,
) -> int:
    """
    Règles (alignées sur l'app mobile) :
    - Score exact : 5 points
    - Bonne différence de buts : 3 points
    - Bon vainqueur ou match nul : 2 points
  """
    if predicted_home == actual_home and predicted_away == actual_away:
        return 5

    pred_diff = predicted_home - predicted_away
    actual_diff = actual_home - actual_away

    if pred_diff == actual_diff:
        return 3

    def outcome(h, a):
        if h > a:
            return 1
        if h < a:
            return -1
        return 0

    if outcome(predicted_home, predicted_away) == outcome(actual_home, actual_away):
        return 2

    return 0
