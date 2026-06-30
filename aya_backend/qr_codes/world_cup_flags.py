"""Codes pays et URLs de drapeaux pour la Coupe du Monde."""

# FIFA / ISO alpha-3 → ISO alpha-2 (flagcdn.com)
ALPHA3_TO_ALPHA2 = {
    'AFG': 'af', 'ALB': 'al', 'ALG': 'dz', 'AND': 'ad', 'ANG': 'ao', 'ARG': 'ar',
    'ARM': 'am', 'AUS': 'au', 'AUT': 'at', 'AZE': 'az', 'BAH': 'bs', 'BHR': 'bh',
    'BAN': 'bd', 'BLR': 'by', 'BEL': 'be', 'BEN': 'bj', 'BOL': 'bo', 'BIH': 'ba',
    'BRA': 'br', 'BUL': 'bg', 'BFA': 'bf', 'CMR': 'cm', 'CAN': 'ca', 'CHI': 'cl',
    'CHN': 'cn', 'COL': 'co', 'CRC': 'cr', 'CRO': 'hr', 'CUW': 'cw', 'CIV': 'ci',
    'CYP': 'cy', 'CZE': 'cz', 'DEN': 'dk', 'ECU': 'ec', 'EGY': 'eg', 'ENG': 'gb',
    'EST': 'ee', 'FIN': 'fi', 'FRA': 'fr', 'GAB': 'ga', 'GEO': 'ge', 'GER': 'de',
    'GHA': 'gh', 'GRE': 'gr', 'GUA': 'gt', 'HON': 'hn', 'HUN': 'hu', 'ISL': 'is',
    'IND': 'in', 'IDN': 'id', 'IRN': 'ir', 'IRQ': 'iq', 'IRL': 'ie', 'ISR': 'il',
    'ITA': 'it', 'JAM': 'jm', 'JPN': 'jp', 'JAP': 'jp', 'JOR': 'jo', 'KAZ': 'kz',
    'KEN': 'ke', 'KOR': 'kr', 'KUW': 'kw', 'LVA': 'lv', 'LBN': 'lb', 'LBY': 'ly',
    'LTU': 'lt', 'LUX': 'lu', 'MKD': 'mk', 'MLI': 'ml', 'MLT': 'mt', 'MAR': 'ma',
    'MEX': 'mx', 'MDA': 'md', 'MNE': 'me', 'NED': 'nl', 'NZL': 'nz', 'NGA': 'ng',
    'NIR': 'gb', 'NOR': 'no', 'OMN': 'om', 'PAN': 'pa', 'PAR': 'py', 'PER': 'pe',
    'POL': 'pl', 'POR': 'pt', 'QAT': 'qa', 'ROU': 'ro', 'RUS': 'ru', 'KSA': 'sa',
    'SCO': 'gb', 'SEN': 'sn', 'SRB': 'rs', 'SVK': 'sk', 'SVN': 'si', 'RSA': 'za',
    'AFS': 'za', 'ESP': 'es', 'SWE': 'se', 'SUI': 'ch', 'SYR': 'sy', 'TUN': 'tn',
    'COD': 'cd', 'CPV': 'cv',
    'TUR': 'tr', 'UKR': 'ua', 'UAE': 'ae', 'USA': 'us', 'URU': 'uy', 'UZB': 'uz',
    'VEN': 've', 'WAL': 'gb', 'ZAM': 'zm', 'ZIM': 'zw',
}

# Largeurs supportées par flagcdn.com
_FLAGCDN_WIDTHS = (20, 40, 80, 160, 320)


def _normalize_flag_width(width: int) -> int:
    for w in _FLAGCDN_WIDTHS:
        if width <= w:
            return w
    return 320


def country_code_to_alpha2(code: str | None) -> str | None:
    if not code:
        return None
    normalized = code.strip().upper()
    if len(normalized) == 2:
        return normalized.lower()
    if len(normalized) == 3:
        return ALPHA3_TO_ALPHA2.get(normalized, normalized[:2].lower())
    return None


def get_country_flag_url(code: str | None, width: int = 40) -> str | None:
    alpha2 = country_code_to_alpha2(code)
    if not alpha2:
        return None
    w = _normalize_flag_width(width)
    return f'https://flagcdn.com/w{w}/{alpha2}.png'


def get_country_flag_emoji(code: str | None) -> str:
    alpha2 = country_code_to_alpha2(code)
    if not alpha2 or len(alpha2) != 2:
        return ''
    upper = alpha2.upper()
    return chr(0x1F1E6 + ord(upper[0]) - ord('A')) + chr(
        0x1F1E6 + ord(upper[1]) - ord('A')
    )
