from django.db import transaction
from django.db.models import Count, Q, Sum
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from zoneinfo import ZoneInfo

from .models_world_cup import WorldCupMatch, WorldCupPrediction

ABIDJAN_TZ = ZoneInfo('Africa/Abidjan')


def _kickoff_iso_abidjan(dt):
    """Heure murale Abidjan (GMT+0) pour l'app mobile."""
    local = timezone.localtime(dt, ABIDJAN_TZ)
    return local.strftime('%Y-%m-%dT%H:%M:%S') + '+00:00'


def _serialize_prediction(prediction):
    return {
        'id': str(prediction.id),
        'match_id': str(prediction.match_id),
        'home_score': prediction.home_score,
        'away_score': prediction.away_score,
        'points_earned': prediction.points_earned,
        'created_at': prediction.created_at.isoformat(),
    }


def _serialize_match(match, user_prediction=None):
    data = {
        'id': str(match.id),
        'home_team': match.home_team,
        'away_team': match.away_team,
        'home_team_code': match.home_team_code,
        'away_team_code': match.away_team_code,
        'kickoff_at': _kickoff_iso_abidjan(match.kickoff_at),
        'stage': match.stage,
        'group': match.group_name,
        'group_name': match.group_name,
        'home_score': match.home_score,
        'away_score': match.away_score,
        'is_finished': match.is_finished,
        'predictions_open': match.can_predict,
        'status': match.status,
    }
    if user_prediction:
        data['user_prediction'] = _serialize_prediction(user_prediction)
    return data


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def world_cup_matches(request):
    """Liste des matchs avec le pronostic de l'utilisateur connecté."""
    matches = WorldCupMatch.objects.filter(is_active=True).order_by('kickoff_at')
    user_predictions = {
        p.match_id: p
        for p in WorldCupPrediction.objects.filter(
            user=request.user, match__in=matches
        )
    }

    return Response({
        'success': True,
        'matches': [
            _serialize_match(m, user_predictions.get(m.id))
            for m in matches
        ],
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def world_cup_submit_prediction(request):
    """Créer ou mettre à jour un pronostic avant le coup d'envoi."""
    match_id = request.data.get('match_id')
    home_score = request.data.get('home_score')
    away_score = request.data.get('away_score')

    if not match_id:
        return Response({'error': 'match_id requis'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        home_score = int(home_score)
        away_score = int(away_score)
    except (TypeError, ValueError):
        return Response(
            {'error': 'Scores invalides'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if home_score < 0 or away_score < 0 or home_score > 20 or away_score > 20:
        return Response(
            {'error': 'Les scores doivent être entre 0 et 20'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        match = WorldCupMatch.objects.get(id=match_id, is_active=True)
    except WorldCupMatch.DoesNotExist:
        return Response({'error': 'Match introuvable'}, status=status.HTTP_404_NOT_FOUND)

    if not match.can_predict:
        return Response(
            {'error': 'Les pronostics sont fermés pour ce match'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    with transaction.atomic():
        prediction, created = WorldCupPrediction.objects.update_or_create(
            user=request.user,
            match=match,
            defaults={
                'home_score': home_score,
                'away_score': away_score,
                'points_earned': None,
            },
        )

    return Response({
        'success': True,
        'message': 'Pronostic enregistré' if created else 'Pronostic mis à jour',
        'prediction': _serialize_prediction(prediction),
    }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def world_cup_my_predictions(request):
    """Historique des pronostics de l'utilisateur."""
    predictions = WorldCupPrediction.objects.filter(
        user=request.user
    ).select_related('match').order_by('-created_at')

    return Response({
        'success': True,
        'predictions': [
            {
                **_serialize_prediction(p),
                'match': _serialize_match(p.match),
            }
            for p in predictions
        ],
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def world_cup_rankings(request):
    """Classement général des pronosticateurs."""
    stats = (
        WorldCupPrediction.objects.filter(points_earned__isnull=False)
        .values('user_id', 'user__first_name', 'user__last_name')
        .annotate(
            total_points=Sum('points_earned'),
            exact_scores=Count('id', filter=Q(points_earned=10)),
            correct_outcomes=Count('id', filter=Q(points_earned__gte=5)),
            total_predictions=Count('id'),
        )
        .order_by('-total_points', '-exact_scores')
    )

    rankings = []
    for rank, row in enumerate(stats, start=1):
        display_name = f"{row['user__first_name']} {row['user__last_name']}".strip()
        rankings.append({
            'rank': rank,
            'user_id': str(row['user_id']),
            'display_name': display_name or 'Joueur',
            'user_name': display_name,
            'total_points': row['total_points'] or 0,
            'points': row['total_points'] or 0,
            'exact_scores': row['exact_scores'] or 0,
            'correct_outcomes': row['correct_outcomes'] or 0,
            'total_predictions': row.get('total_predictions') or 0,
            'is_current_user': str(row['user_id']) == str(request.user.id),
        })

    return Response({
        'success': True,
        'rankings': rankings,
    })
