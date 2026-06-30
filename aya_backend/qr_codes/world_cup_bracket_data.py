"""Données du tableau CDM 2026 — source unique (sync dashboard ↔ app mobile)."""

from datetime import datetime
from zoneinfo import ZoneInfo

ABIDJAN_TZ = ZoneInfo('Africa/Abidjan')

# 1/16 de finale : numéro → [(nom domicile, flag alpha2), (nom extérieur, flag alpha2)]
R32 = {
    74: [('Allemagne', 'de'), ('Paraguay', 'py')],
    77: [('France', 'fr'), ('Suède', 'se')],
    73: [('Afrique du Sud', 'za'), ('Canada', 'ca')],
    75: [('Pays-Bas', 'nl'), ('Maroc', 'ma')],
    83: [('Portugal', 'pt'), ('Croatie', 'hr')],
    84: [('Espagne', 'es'), ('Autriche', 'at')],
    81: [('États-Unis', 'us'), ('Bosnie', 'ba')],
    82: [('Belgique', 'be'), ('Sénégal', 'sn')],
    76: [('Brésil', 'br'), ('Japon', 'jp')],
    78: [("Côte d'Ivoire", 'ci'), ('Norvège', 'no')],
    79: [('Mexique', 'mx'), ('Équateur', 'ec')],
    80: [('Angleterre', 'gb-eng'), ('RD Congo', 'cd')],
    86: [('Argentine', 'ar'), ('Cap-Vert', 'cv')],
    88: [('Australie', 'au'), ('Égypte', 'eg')],
    85: [('Suisse', 'ch'), ('Algérie', 'dz')],
    87: [('Colombie', 'co'), ('Ghana', 'gh')],
}

# Matchs suivants : numéro → [match source domicile, match source extérieur]
FEED = {
    89: [74, 77],
    90: [73, 75],
    93: [83, 84],
    94: [81, 82],
    91: [76, 78],
    92: [79, 80],
    95: [86, 88],
    96: [85, 87],
    97: [89, 90],
    98: [93, 94],
    99: [91, 92],
    100: [95, 96],
    101: [97, 98],
    102: [99, 100],
    104: [101, 102],
}

STAGE_BY_MATCH = {
    **{m: '1/16 de finale' for m in R32},
    **{m: '1/8 de finale' for m in range(89, 97)},
    **{m: 'Quarts de finale' for m in range(97, 101)},
    **{m: 'Demi-finale' for m in (101, 102)},
    104: 'Finale',
}

# Coups d'envoi par défaut (heure Abidjan) — modifiables dans « Gérer les matchs »
_DEFAULT_KICKOFF_RAW = [
    (73, 2026, 6, 28, 17, 0),
    (74, 2026, 6, 29, 17, 0),
    (75, 2026, 6, 29, 21, 0),
    (76, 2026, 6, 30, 17, 0),
    (77, 2026, 6, 30, 21, 0),
    (78, 2026, 7, 1, 17, 0),
    (79, 2026, 7, 1, 21, 0),
    (80, 2026, 7, 2, 17, 0),
    (81, 2026, 7, 2, 21, 0),
    (82, 2026, 7, 3, 17, 0),
    (83, 2026, 7, 3, 21, 0),
    (84, 2026, 7, 4, 17, 0),
    (85, 2026, 7, 4, 21, 0),
    (86, 2026, 7, 5, 17, 0),
    (87, 2026, 7, 5, 21, 0),
    (88, 2026, 7, 6, 17, 0),
    (89, 2026, 7, 7, 17, 0),
    (90, 2026, 7, 7, 21, 0),
    (91, 2026, 7, 8, 17, 0),
    (92, 2026, 7, 8, 21, 0),
    (93, 2026, 7, 9, 17, 0),
    (94, 2026, 7, 9, 21, 0),
    (95, 2026, 7, 10, 17, 0),
    (96, 2026, 7, 10, 21, 0),
    (97, 2026, 7, 11, 17, 0),
    (98, 2026, 7, 11, 21, 0),
    (99, 2026, 7, 12, 17, 0),
    (100, 2026, 7, 12, 21, 0),
    (101, 2026, 7, 15, 17, 0),
    (102, 2026, 7, 15, 21, 0),
    (104, 2026, 7, 19, 17, 0),
]

ALPHA2_TO_FIFA = {
    'de': 'GER',
    'py': 'PAR',
    'fr': 'FRA',
    'se': 'SWE',
    'za': 'RSA',
    'ca': 'CAN',
    'nl': 'NED',
    'ma': 'MAR',
    'pt': 'POR',
    'hr': 'CRO',
    'es': 'ESP',
    'at': 'AUT',
    'us': 'USA',
    'ba': 'BIH',
    'be': 'BEL',
    'sn': 'SEN',
    'br': 'BRA',
    'jp': 'JPN',
    'ci': 'CIV',
    'no': 'NOR',
    'mx': 'MEX',
    'ec': 'ECU',
    'gb-eng': 'ENG',
    'cd': 'COD',
    'ar': 'ARG',
    'cv': 'CPV',
    'au': 'AUS',
    'eg': 'EGY',
    'ch': 'SUI',
    'dz': 'ALG',
    'co': 'COL',
    'gh': 'GHA',
}


def default_kickoffs():
    from django.utils import timezone

    out = {}
    for code, y, mo, d, h, mi in _DEFAULT_KICKOFF_RAW:
        naive = datetime(y, mo, d, h, mi)
        out[code] = timezone.make_aware(naive, ABIDJAN_TZ)
    return out


def all_bracket_match_codes():
    return sorted(set(R32) | set(FEED))


def fifa_code(name: str, flag_alpha2: str) -> str:
    key = (flag_alpha2 or '').lower()
    if key in ALPHA2_TO_FIFA:
        return ALPHA2_TO_FIFA[key]
    if len(key) == 2:
        return key.upper()
    return (name or '')[:3].upper()


def _team_dict(name: str, flag: str) -> dict:
    return {'name': name, 'flag': flag}


def _winner_lookup(winners: dict, match_code: int):
    raw = winners.get(match_code) or winners.get(str(match_code))
    if not raw or not isinstance(raw, dict):
        return None
    name = raw.get('name', '').strip()
    flag = raw.get('flag', '').strip()
    if not name:
        return None
    return _team_dict(name, flag)


def slot_team(match_code: int, side: int, winners: dict) -> dict | None:
    """Résout l'équipe d'un slot (même logique que le JS du tableau)."""
    if match_code in R32:
        name, flag = R32[match_code][side]
        return _team_dict(name, flag)
    feed = FEED.get(match_code)
    if not feed:
        return None
    source = feed[side]
    return _winner_lookup(winners, source)


def resolve_match_teams(match_code: int, winners: dict) -> tuple[dict | None, dict | None]:
    home = slot_team(match_code, 0, winners)
    away = slot_team(match_code, 1, winners)
    return home, away
