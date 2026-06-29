const Map<String, String> _alpha3ToAlpha2 = {
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
  'TUR': 'tr', 'UKR': 'ua', 'UAE': 'ae', 'USA': 'us', 'URU': 'uy', 'UZB': 'uz',
  'VEN': 've', 'WAL': 'gb', 'ZAM': 'zm', 'ZIM': 'zw',
};

/// Largeurs supportées par flagcdn.com
int _normalizeFlagWidth(int width) {
  if (width <= 20) return 20;
  if (width <= 40) return 40;
  if (width <= 80) return 80;
  if (width <= 160) return 160;
  return 320;
}

String? countryCodeToAlpha2(String? code) {
  if (code == null || code.trim().isEmpty) return null;
  final normalized = code.trim().toUpperCase();
  if (normalized.length == 2) return normalized.toLowerCase();
  if (normalized.length == 3) {
    return _alpha3ToAlpha2[normalized] ?? normalized.substring(0, 2).toLowerCase();
  }
  return null;
}

String? countryFlagUrl(String? code, {int width = 40}) {
  final alpha2 = countryCodeToAlpha2(code);
  if (alpha2 == null) return null;
  final w = _normalizeFlagWidth(width);
  return 'https://flagcdn.com/w$w/$alpha2.png';
}

/// Emoji drapeau de secours (ex. 🇧🇷)
String? countryFlagEmoji(String? code) {
  final alpha2 = countryCodeToAlpha2(code);
  if (alpha2 == null || alpha2.length != 2) return null;
  final upper = alpha2.toUpperCase();
  return String.fromCharCodes([
    upper.codeUnitAt(0) + 0x1F1A5,
    upper.codeUnitAt(1) + 0x1F1A5,
  ]);
}
