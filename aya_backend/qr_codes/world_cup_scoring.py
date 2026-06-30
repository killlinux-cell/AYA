"""Calcul et attribution des points pour les pronostics Coupe du Monde."""

from django.contrib.auth import get_user_model
from django.db.models import F

User = get_user_model()

POINTS_EXACT = 10
POINTS_CORRECT_OUTCOME = 5
POINTS_PARTICIPATION = 1


def calculate_prediction_points(
    predicted_home: int,
    predicted_away: int,
    actual_home: int,
    actual_away: int,
) -> int:
    """
    Barème officiel :
    - Score exact : 10 points
    - Bon résultat (vainqueur ou nul) : 5 points
    - Raté : 1 point (participation)
    """
    if predicted_home == actual_home and predicted_away == actual_away:
        return POINTS_EXACT

    def outcome(h, a):
        if h > a:
            return 1
        if h < a:
            return -1
        return 0

    if outcome(predicted_home, predicted_away) == outcome(actual_home, actual_away):
        return POINTS_CORRECT_OUTCOME

    return POINTS_PARTICIPATION


def classify_prediction_outcome(
    predicted_home: int,
    predicted_away: int,
    actual_home: int,
    actual_away: int,
) -> str:
    """Retourne exact, bon ou rate."""
    points = calculate_prediction_points(
        predicted_home, predicted_away, actual_home, actual_away
    )
    if points == POINTS_EXACT:
        return 'exact'
    if points == POINTS_CORRECT_OUTCOME:
        return 'bon'
    return 'rate'


def outcome_label(outcome_key: str) -> str:
    return {
        'exact': 'Score exact',
        'bon': 'Bon résultat',
        'rate': 'Raté',
    }.get(outcome_key, '—')


def apply_prediction_points(prediction, new_points: int) -> None:
    """Met à jour points_earned et crédite le solde utilisateur (delta)."""
    old_points = prediction.points_earned
    if old_points == new_points:
        return

    old_val = old_points if old_points is not None else 0
    delta = new_points - old_val

    prediction.points_earned = new_points
    prediction.save(update_fields=['points_earned', 'updated_at'])

    if delta:
        User.objects.filter(pk=prediction.user_id).update(
            available_points=F('available_points') + delta
        )


def recalculate_match_predictions(match) -> int:
    """Recalcule tous les pronostics d'un match terminé. Retourne le nombre traité."""
    if not match.is_finished or match.home_score is None or match.away_score is None:
        return 0

    count = 0
    for prediction in match.predictions.select_related('user'):
        points = calculate_prediction_points(
            prediction.home_score,
            prediction.away_score,
            match.home_score,
            match.away_score,
        )
        apply_prediction_points(prediction, points)
        count += 1
    return count
