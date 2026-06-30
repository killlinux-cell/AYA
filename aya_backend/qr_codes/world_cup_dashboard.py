"""Helpers partagés pour le dashboard pronostics CDM."""

from django.db.models import Count, Q, Sum

from .models_world_cup import WorldCupMatch, WorldCupPrediction
from .world_cup_scoring import (
    POINTS_CORRECT_OUTCOME,
    POINTS_EXACT,
    classify_prediction_outcome,
    outcome_label,
)

AVATAR_COLORS = [
    '#e0a92e', '#7c8a93', '#c07b4a', '#2f7df0',
    '#1cb8d6', '#9a5fb0', '#1f9d54', '#e89b08',
]


def avatar_color_for(user_id) -> str:
    key = str(user_id).replace('-', '')
    idx = int(key[:8], 16) % len(AVATAR_COLORS) if key else 0
    return AVATAR_COLORS[idx]


def mask_phone(phone: str) -> str:
    if not phone:
        return '—'
    digits = ''.join(c for c in phone if c.isdigit())
    if len(digits) < 6:
        return phone
    if len(digits) >= 10:
        return f'+{digits[:3]} {digits[3:5]} {digits[5:7]} •• ••'
    return f'{digits[:4]} •• ••'


def user_initials(user) -> str:
    if user.first_name and user.last_name:
        return (user.first_name[:1] + user.last_name[:1]).upper()
    return '??'


def get_prediction_stats(queryset=None):
    qs = queryset or WorldCupPrediction.objects.all()
    scored = qs.filter(points_earned__isnull=False)
    total = qs.count()
    exact = scored.filter(points_earned=POINTS_EXACT).count()
    correct = scored.filter(points_earned__gte=POINTS_CORRECT_OUTCOME).count()
    points_total = scored.aggregate(total=Sum('points_earned'))['total'] or 0
    success_rate = round((correct / total) * 100) if total else 0
    return {
        'total_predictions': total,
        'correct_predictions': correct,
        'exact_predictions': exact,
        'success_rate': success_rate,
        'points_distributed': points_total,
    }


def enrich_prediction_row(prediction):
    """Ajoute issue, labels et statut pour l'affichage dashboard."""
    match = prediction.match
    outcome = None
    outcome_display = '—'
    status_key = 'pending'
    status_label = 'En attente'

    if match.is_finished and match.home_score is not None and match.away_score is not None:
        if prediction.points_earned is not None:
            outcome = classify_prediction_outcome(
                prediction.home_score,
                prediction.away_score,
                match.home_score,
                match.away_score,
            )
            outcome_display = outcome_label(outcome)
            if prediction.points_earned >= POINTS_CORRECT_OUTCOME:
                status_key = 'win'
                status_label = 'Gagné'
            else:
                status_key = 'lose'
                status_label = 'Perdu'
    else:
        outcome = 'wait'
        outcome_display = 'À jouer'
        status_key = 'pending'
        status_label = 'En attente'

    phone = ''
    try:
        if hasattr(prediction.user, 'profile') and prediction.user.profile:
            phone = prediction.user.profile.phone_number or ''
    except Exception:
        pass

    pred_score = f'{prediction.home_score} – {prediction.away_score}'
    match_score = (
        f'{match.home_score} – {match.away_score}'
        if match.is_finished and match.home_score is not None
        else '— : —'
    )

    return {
        'prediction': prediction,
        'outcome': outcome,
        'outcome_display': outcome_display,
        'status_key': status_key,
        'status_label': status_label,
        'phone_masked': mask_phone(phone),
        'initials': user_initials(prediction.user),
        'avatar_color': avatar_color_for(prediction.user_id),
        'display_id': f'PR-{str(prediction.id).replace("-", "")[-4:].upper()}',
        'pred_score': pred_score,
        'match_score': match_score,
        'match_inline_score': f'{prediction.home_score}–{prediction.away_score}',
    }


def enrich_game_row(game):
    prize = '—'
    if game.is_winning and game.points_won >= 10:
        prize = '🎁 Bon -10%'
    status_key = 'win' if game.is_winning else 'pending'
    status_label = 'Validé' if game.is_winning else 'En attente'
    game_type_label = '🎡 Spin Wheel' if game.game_type == 'spin_wheel' else '🎟️ Scratch & Win'
    return {
        'game': game,
        'display_id': f'JX-{str(game.id).replace("-", "")[-4:].upper()}',
        'initials': user_initials(game.user),
        'avatar_color': avatar_color_for(game.user_id),
        'prize': prize,
        'status_key': status_key,
        'status_label': status_label,
        'game_type_label': game_type_label,
        'played_label': game.played_at.strftime('%d/%m · %Hh%M'),
    }


def get_leaderboard(limit=None):
    stats = (
        WorldCupPrediction.objects.filter(points_earned__isnull=False)
        .values('user_id', 'user__first_name', 'user__last_name')
        .annotate(
            total_predictions=Count('id'),
            correct_predictions=Count(
                'id', filter=Q(points_earned__gte=POINTS_CORRECT_OUTCOME)
            ),
            total_points=Sum('points_earned'),
            exact_scores=Count('id', filter=Q(points_earned=POINTS_EXACT)),
        )
        .order_by('-total_points', '-exact_scores', '-correct_predictions')
    )

    if limit:
        stats = stats[:limit]

    rows = []
    for rank, row in enumerate(stats, start=1):
        total_preds = row['total_predictions'] or 0
        correct = row['correct_predictions'] or 0
        precision = round((correct / total_preds) * 100) if total_preds else 0
        name = f"{row['user__first_name']} {row['user__last_name']}".strip() or 'Joueur'
        initials = user_initials(type('U', (), {
            'first_name': row['user__first_name'],
            'last_name': row['user__last_name'],
        })())

        phone = ''
        from django.contrib.auth import get_user_model
        User = get_user_model()
        try:
            user = User.objects.select_related('profile').get(pk=row['user_id'])
            if hasattr(user, 'profile') and user.profile:
                phone = mask_phone(user.profile.phone_number)
        except User.DoesNotExist:
            pass

        rows.append({
            'rank': rank,
            'user_id': row['user_id'],
            'display_name': name,
            'initials': initials,
            'avatar_color': avatar_color_for(row['user_id']),
            'phone_masked': phone,
            'total_predictions': total_preds,
            'correct_predictions': correct,
            'precision': precision,
            'total_points': row['total_points'] or 0,
            'exact_scores': row['exact_scores'] or 0,
        })
    return rows


def filter_predictions(request):
    qs = WorldCupPrediction.objects.select_related('user', 'user__profile', 'match')

    user_filter = request.GET.get('user', '')
    if user_filter:
        qs = qs.filter(user_id=user_filter)

    match_filter = request.GET.get('match', '')
    if match_filter:
        qs = qs.filter(match_id=match_filter)

    date_from = request.GET.get('date_from', '')
    if date_from:
        qs = qs.filter(match__kickoff_at__date__gte=date_from)

    date_to = request.GET.get('date_to', '')
    if date_to:
        qs = qs.filter(match__kickoff_at__date__lte=date_to)

    return qs.order_by('-match__kickoff_at', '-created_at')
