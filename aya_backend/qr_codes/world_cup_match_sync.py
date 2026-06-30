"""Synchronise le tableau CDM vers les matchs pronostics (WorldCupMatch / app mobile)."""

from django.utils import timezone

from .models_world_cup import WorldCupBracketState, WorldCupMatch
from .world_cup_bracket_data import (
    STAGE_BY_MATCH,
    all_bracket_match_codes,
    default_kickoffs,
    fifa_code,
    resolve_match_teams,
)


def _load_winners(winners=None) -> dict:
    if winners is not None:
        return winners
    state = WorldCupBracketState.objects.filter(pk=1).first()
    return (state.winners or {}) if state else {}


def sync_bracket_to_matches(winners=None) -> dict:
    """
    Crée ou met à jour les WorldCupMatch à partir du tableau.
    - Les 1/16 (R32) sont toujours créés (équipes connues).
    - Les tours suivants sont créés quand les deux équipes sont connues.
    - Ne modifie pas les matchs déjà terminés.
    """
    winners = _load_winners(winners)
    kickoffs = default_kickoffs()
    created = updated = skipped = 0

    for code in all_bracket_match_codes():
        home, away = resolve_match_teams(code, winners)
        if not home or not away:
            continue

        home_name, home_flag = home['name'], home['flag']
        away_name, away_flag = away['name'], away['flag']
        home_code = fifa_code(home_name, home_flag)
        away_code = fifa_code(away_name, away_flag)
        stage = STAGE_BY_MATCH.get(code, 'Élimination directe')
        bracket_code = str(code)

        match = WorldCupMatch.objects.filter(bracket_match_code=bracket_code).first()

        if match is None:
            WorldCupMatch.objects.create(
                bracket_match_code=bracket_code,
                home_team=home_name,
                away_team=away_name,
                home_team_code=home_code,
                away_team_code=away_code,
                kickoff_at=kickoffs.get(code, timezone.now()),
                stage=stage,
                group_name=f'Match {code}',
                status='scheduled',
                predictions_open=True,
                is_active=True,
            )
            created += 1
            continue

        if match.status == 'finished':
            skipped += 1
            continue

        changed = False
        for field, value in (
            ('home_team', home_name),
            ('away_team', away_name),
            ('home_team_code', home_code),
            ('away_team_code', away_code),
            ('stage', stage),
        ):
            if getattr(match, field) != value:
                setattr(match, field, value)
                changed = True

        if changed:
            match.save()
            updated += 1
        else:
            skipped += 1

    return {
        'created': created,
        'updated': updated,
        'skipped': skipped,
        'total_active': WorldCupMatch.objects.filter(is_active=True).count(),
    }
