"""Helpers partagés pour le dashboard pronostics CDM."""

from django.db.models import Count, Q, Sum

from .models_world_cup import WorldCupMatch, WorldCupPrediction
from .world_cup_scoring import (
    POINTS_CORRECT_OUTCOME,
    POINTS_EXACT,
    POINTS_PARTICIPATION,
    classify_prediction_outcome,
    outcome_label,
)


def mask_phone(phone: str) -> str:
    if not phone:
        return '—'
    digits = ''.join(c for c in phone if c.isdigit() or c == '+')
    if len(digits) < 6:
        return phone
    return f'{digits[:8]} .. ..'


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
    """Ajoute issue, labels et statut gagné/perdu pour l'affichage dashboard."""
    match = prediction.match
    outcome = None
    outcome_display = '—'
    status_won = None

    if (
        match.is_finished
        and match.home_score is not None
        and match.away_score is not None
        and prediction.points_earned is not None
    ):
        outcome = classify_prediction_outcome(
            prediction.home_score,
            prediction.away_score,
            match.home_score,
            match.away_score,
        )
        outcome_display = outcome_label(outcome)
        status_won = prediction.points_earned >= POINTS_CORRECT_OUTCOME

    phone = ''
    if hasattr(prediction.user, 'profile'):
        phone = getattr(prediction.user.profile, 'phone_number', '') or ''

    initials = (
        (prediction.user.first_name[:1] + prediction.user.last_name[:1]).upper()
        if prediction.user.first_name
        else '??'
    )

    return {
        'prediction': prediction,
        'outcome': outcome,
        'outcome_display': outcome_display,
        'status_won': status_won,
        'phone_masked': mask_phone(phone),
        'initials': initials,
        'display_id': f'PR-{str(prediction.id).replace("-", "")[:4].upper()}',
    }


def get_leaderboard(limit=None):
    stats = (
        WorldCupPrediction.objects.filter(points_earned__isnull=False)
        .values('user_id', 'user__first_name', 'user__last_name', 'user__email')
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
        initials = (name.split()[0][:1] + (name.split()[1][:1] if len(name.split()) > 1 else '')).upper()

        phone = ''
        from django.contrib.auth import get_user_model
        User = get_user_model()
        try:
            user = User.objects.select_related('profile').get(pk=row['user_id'])
            if hasattr(user, 'profile'):
                phone = mask_phone(user.profile.phone_number)
        except User.DoesNotExist:
            pass

        rows.append({
            'rank': rank,
            'user_id': row['user_id'],
            'display_name': name,
            'initials': initials,
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
