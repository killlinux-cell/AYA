# Guide de Gestion des Tokens d'Échange

## Problème Résolu

**Problème initial** : Quand un token d'échange expire, les points restaient débités chez l'utilisateur, ce qui n'est pas logique car l'échange n'a pas eu lieu.

**Solution implémentée** : Système automatique de restauration des points lors de l'expiration des tokens.

## Fonctionnalités Ajoutées

### 1. Restauration Automatique des Points
- ✅ Les points sont automatiquement restaurés quand un token expire
- ✅ Les tokens expirés sont supprimés de la base de données
- ✅ Logs détaillés pour le suivi des opérations

### 2. Nettoyage Automatique
- ✅ Nettoyage automatique lors de la validation des tokens
- ✅ Signaux Django pour déclencher le nettoyage
- ✅ Commande de gestion pour nettoyage manuel

### 3. API Améliorée
- ✅ Nouvelle endpoint `/api/exchange-tokens/status/` pour vérifier l'état des tokens
- ✅ Messages d'erreur améliorés avec information sur la restauration des points
- ✅ Gestion des erreurs robuste

## Utilisation

### Nettoyage Automatique
Le nettoyage se fait automatiquement :
- Lors de la création d'un nouveau token
- Lors de la validation d'un token
- Via les signaux Django

### Nettoyage Manuel
```bash
# Nettoyage normal
cd aya_backend
python cleanup_tokens.py

# Mode simulation (sans modifications)
python cleanup_tokens.py --dry-run

# Via la commande Django
python manage.py cleanup_expired_tokens
```

### Vérification de l'État des Tokens
```bash
# Vérifier l'état des tokens d'un utilisateur
curl -H "Authorization: Bearer <token>" \
     http://localhost:8000/api/exchange-tokens/status/
```

## Structure des Fichiers Modifiés

### Backend
- `qr_codes/models.py` - Méthode `restore_user_points()` améliorée
- `qr_codes/views.py` - Nouvelles vues et logique de nettoyage
- `qr_codes/tasks.py` - Tâches de nettoyage automatique
- `qr_codes/signals.py` - Signaux Django pour nettoyage automatique
- `qr_codes/apps.py` - Configuration des signaux
- `qr_codes/urls.py` - Nouvelle route pour l'état des tokens
- `qr_codes/management/commands/cleanup_expired_tokens.py` - Commande de nettoyage

### Scripts de Test
- `test_token_restoration.py` - Test de la restauration des points
- `cleanup_tokens.py` - Script de nettoyage manuel

## Logique de Fonctionnement

1. **Création d'un token** :
   - Les points sont débités immédiatement
   - Un token unique est généré avec expiration (3 minutes)
   - Nettoyage automatique des anciens tokens expirés

2. **Expiration d'un token** :
   - Le token devient invalide après 3 minutes
   - Les points sont automatiquement restaurés
   - Le token est supprimé de la base de données

3. **Validation d'un token** :
   - Nettoyage automatique des tokens expirés
   - Si le token est expiré, restauration des points
   - Si le token est valide, création de la demande d'échange

## Surveillance et Maintenance

### Logs
Les opérations sont loggées dans les logs Django :
- Création de tokens
- Restauration de points
- Suppression de tokens expirés

### Monitoring
- Vérifier régulièrement les logs pour les erreurs
- Surveiller l'utilisation des tokens via l'API de statut
- Exécuter le nettoyage manuel si nécessaire

## Tests

Le système a été testé avec succès :
- ✅ Restauration des points lors de l'expiration
- ✅ Suppression des tokens expirés
- ✅ Gestion des erreurs
- ✅ API de statut fonctionnelle

## Impact sur les Utilisateurs

- **Avant** : Perte de points lors de l'expiration des tokens
- **Après** : Points automatiquement restaurés, aucun impact négatif
- **Transparence** : Messages clairs sur la restauration des points
- **Sécurité** : Tokens expirés supprimés automatiquement
