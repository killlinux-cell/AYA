"""
Moteur de chat SARCI — 100 % gratuit (recherche locale, sans API payante).
"""

import re
import unicodedata

from .sarci_knowledge import (
    SARCI_KNOWLEDGE,
    WELCOME_MESSAGE,
    OFF_TOPIC_MESSAGE,
    NO_MATCH_MESSAGE,
)

# Mots indiquant une question hors périmètre SARCI
_OFF_TOPIC_SIGNALS = [
    'météo', 'meteo', 'politique', 'bitcoin', 'crypto', 'football',
    'match real', 'psg', 'iphone', 'android vs', 'recette de', 'comment cuisiner',
    'film', 'série', 'serie', 'netflix', 'chatgpt', 'openai', 'code python',
    'devise', 'dollar', 'euro cours', 'bourse',
]


def _normalize(text: str) -> str:
    text = unicodedata.normalize('NFD', text.lower())
    return ''.join(c for c in text if unicodedata.category(c) != 'Mn')


def _tokenize(text: str) -> set[str]:
    normalized = _normalize(text)
    tokens = re.findall(r"[a-z0-9']+", normalized)
    return {t for t in tokens if len(t) > 1}


def _score_entry(query_tokens: set[str], entry: dict) -> float:
    keywords = _tokenize(' '.join(entry['keywords']))
    content = _tokenize(entry['content'])
    title = _tokenize(entry['title'])

    score = 0.0
    for token in query_tokens:
        if token in keywords:
            score += 4.0
        if token in title:
            score += 2.0
        if token in content:
            score += 1.0
    return score


def _is_off_topic(query: str) -> bool:
    normalized = _normalize(query)
    return any(signal in normalized for signal in _OFF_TOPIC_SIGNALS)


def _is_greeting(query: str) -> bool:
    normalized = _normalize(query.strip())
    greetings = {
        'bonjour', 'bonsoir', 'salut', 'hello', 'hi', 'coucou',
        'hey', 'bonne journee', 'bonne soiree',
    }
    tokens = _tokenize(normalized)
    return bool(tokens & greetings) or normalized in greetings


def get_welcome_message() -> str:
    return WELCOME_MESSAGE


def generate_reply(user_message: str) -> dict:
    """
    Génère une réponse à partir de la base de connaissances SARCI.
    Retourne {'reply': str, 'topic': str|None, 'source': str}
    """
    message = (user_message or '').strip()
    if not message:
        return {'reply': WELCOME_MESSAGE, 'topic': 'welcome', 'source': 'sarci.ci'}

    if _is_greeting(message) and len(_tokenize(message)) <= 3:
        return {'reply': WELCOME_MESSAGE, 'topic': 'welcome', 'source': 'sarci.ci'}

    if _is_off_topic(message):
        return {'reply': OFF_TOPIC_MESSAGE, 'topic': 'off_topic', 'source': 'sarci.ci'}

    query_tokens = _tokenize(message)
    if not query_tokens:
        return {'reply': NO_MATCH_MESSAGE, 'topic': None, 'source': 'sarci.ci'}

    scored = [
        (_score_entry(query_tokens, entry), entry)
        for entry in SARCI_KNOWLEDGE
    ]
    scored.sort(key=lambda x: x[0], reverse=True)

    best_score, best_entry = scored[0]

    # Seuil minimal pour éviter les réponses hors sujet
    if best_score < 2.0:
        return {'reply': NO_MATCH_MESSAGE, 'topic': None, 'source': 'sarci.ci'}

    return {
        'reply': best_entry['content'],
        'topic': best_entry['id'],
        'source': 'https://sarci.ci',
        'title': best_entry['title'],
    }
