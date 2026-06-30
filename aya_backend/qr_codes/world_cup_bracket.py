"""Propagation des vainqueurs dans le tableau CDM."""

from .models_world_cup import WorldCupBracketMatch


def _clear_downstream(slot: WorldCupBracketMatch) -> None:
    """Efface les équipes propagées en aval d'un slot."""
    children = WorldCupBracketMatch.objects.filter(
        home_source_code=slot.code
    ) | WorldCupBracketMatch.objects.filter(
        away_source_code=slot.code
    )
    for child in children:
        if child.home_source_code == slot.code:
            child.home_team = ''
            child.home_team_code = ''
        if child.away_source_code == slot.code:
            child.away_team = ''
            child.away_team_code = ''
        child.winner_side = ''
        child.save()
        _clear_downstream(child)


def set_bracket_winner(code: str, side: str) -> WorldCupBracketMatch:
    slot = WorldCupBracketMatch.objects.get(code=code)

    if side not in ('home', 'away'):
        raise ValueError('Côté invalide')

    team = slot.home_team if side == 'home' else slot.away_team
    team_code = slot.home_team_code if side == 'home' else slot.away_team_code

    if not team:
        raise ValueError('Équipe non définie pour ce match')

    if slot.winner_side and slot.winner_side != side:
        _clear_downstream(slot)

    slot.winner_side = side
    slot.save(update_fields=['winner_side', 'updated_at'])

    for child in WorldCupBracketMatch.objects.filter(home_source_code=code):
        child.home_team = team
        child.home_team_code = team_code
        child.save(update_fields=['home_team', 'home_team_code', 'updated_at'])

    for child in WorldCupBracketMatch.objects.filter(away_source_code=code):
        child.away_team = team
        child.away_team_code = team_code
        child.save(update_fields=['away_team', 'away_team_code', 'updated_at'])

    return slot


def reset_bracket() -> None:
    WorldCupBracketMatch.objects.all().delete()
    from django.core.management import call_command
    call_command('seed_world_cup_bracket')
