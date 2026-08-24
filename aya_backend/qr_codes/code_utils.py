"""Utilitaires pour codes produit (QR historiques + codes 6 chiffres)."""
from __future__ import annotations

import random
import re
from typing import Iterable, List, Optional, Set

from django.db import IntegrityError

SIX_DIGIT_RE = re.compile(r'^\d{6}$')


def normalize_claim_code(raw: Optional[str]) -> str:
    """Nettoie le code saisi ou extrait d'une URL / deep link."""
    if raw is None:
        return ''
    value = str(raw).strip()
    if not value:
        return ''

    # URL web monuniversaya.com/scan?code=...
    if '://' in value or value.startswith('http'):
        try:
            from urllib.parse import parse_qs, urlparse

            parsed = urlparse(value)
            qs = parse_qs(parsed.query)
            if qs.get('code'):
                return qs['code'][0].strip()
        except Exception:
            pass

    # Deep link aya-huile-app://qr?code=...
    if value.startswith('aya-huile-app://'):
        try:
            from urllib.parse import parse_qs, urlparse

            parsed = urlparse(value)
            qs = parse_qs(parsed.query)
            if qs.get('code'):
                return qs['code'][0].strip()
        except Exception:
            pass

    # Espaces / tirets éventuels sur saisie manuelle
    compact = re.sub(r'[\s\-]', '', value)
    return compact


def is_six_digit_code(code: str) -> bool:
    return bool(SIX_DIGIT_RE.match(code or ''))


def generate_unique_six_digit_codes(count: int, reserved: Optional[Set[str]] = None) -> List[str]:
    """
    Génère `count` codes uniques sur 000000–999999.
    `reserved` = codes déjà pris (ex. en base).
    """
    if count < 1:
        return []
    if count > 100_000:
        raise ValueError('Maximum 100 000 codes par génération.')

    taken: Set[str] = set(reserved or set())
    available = 1_000_000 - len(taken)
    if count > available:
        raise ValueError(
            f'Seulement {available} codes à 6 chiffres encore disponibles '
            f'(besoin de {count}).'
        )

    generated: List[str] = []
    # Tirage aléatoire ; si le pool se remplit, bascule sur parcours exhaustif
    attempts = 0
    max_attempts = max(count * 20, 1000)

    while len(generated) < count and attempts < max_attempts:
        attempts += 1
        candidate = f'{random.randint(0, 999999):06d}'
        if candidate in taken:
            continue
        taken.add(candidate)
        generated.append(candidate)

    if len(generated) < count:
        # Fallback déterministe sur les codes restants
        for n in range(1_000_000):
            candidate = f'{n:06d}'
            if candidate in taken:
                continue
            taken.add(candidate)
            generated.append(candidate)
            if len(generated) >= count:
                break

    if len(generated) < count:
        raise ValueError('Impossible de générer assez de codes uniques.')

    return generated


def existing_code_set(queryset_values: Iterable[str]) -> Set[str]:
    return set(queryset_values)


def create_qr_with_retry(model, *, code: str, defaults: dict, max_retries: int = 5):
    """Crée un QRCode ; en cas de collision unique, relance (codes 6 chiffres)."""
    last_error = None
    current = code
    for _ in range(max_retries):
        try:
            return model.objects.create(code=current, **defaults)
        except IntegrityError as exc:
            last_error = exc
            if is_six_digit_code(current):
                current = generate_unique_six_digit_codes(
                    1,
                    reserved=existing_code_set(
                        model.objects.values_list('code', flat=True)
                    ),
                )[0]
            else:
                raise
    raise last_error or IntegrityError('Création impossible')
