# 🔗 Intégration Backend Django avec Flutter

## 📋 Vue d'ensemble

L'application Flutter Aya a été intégrée avec un backend Django complet pour remplacer les services locaux. Cette intégration fournit une authentification robuste, une gestion des données persistante et une API REST complète.

## 🏗️ Architecture

### Backend Django
- **URL de base** : `http://localhost:8000/api/`
- **Authentification** : JWT (JSON Web Tokens)
- **Base de données** : SQLite (développement) / PostgreSQL (production)
- **API** : REST avec Django REST Framework

### Frontend Flutter
- **Services Django** : Nouveaux services pour communiquer avec l'API
- **Authentification** : JWT avec refresh tokens
- **Gestion d'état** : Provider pattern maintenu
- **Compatibilité** : Interface identique aux services locaux

## 🔧 Services Intégrés

### 1. DjangoAuthService
**Fichier** : `lib/services/django_auth_service.dart`

**Fonctionnalités** :
- Connexion avec email/mot de passe
- Inscription d'utilisateurs
- Gestion des tokens JWT
- Rafraîchissement automatique des tokens
- Déconnexion avec blacklist

**Endpoints utilisés** :
- `POST /api/auth/login/` - Connexion
- `POST /api/auth/register/` - Inscription
- `POST /api/auth/token/refresh/` - Rafraîchir token
- `POST /api/auth/logout/` - Déconnexion

### 2. DjangoUserService
**Fichier** : `lib/services/django_user_service.dart`

**Fonctionnalités** :
- Récupération du profil utilisateur
- Mise à jour des points
- Gestion des QR codes personnels
- Statistiques utilisateur

**Endpoints utilisés** :
- `GET /api/auth/profile/` - Profil utilisateur
- `PUT /api/auth/profile/update/` - Mise à jour profil
- `GET /api/user-codes/` - QR codes scannés
- `GET /api/stats/` - Statistiques

### 3. DjangoQRValidationService
**Fichier** : `lib/services/django_qr_validation_service.dart`

**Fonctionnalités** :
- Validation des QR codes scannés
- Attribution automatique de points
- Vérification des QR codes déjà utilisés
- Gestion des erreurs de validation

**Endpoints utilisés** :
- `POST /api/validate/` - Valider QR code
- `GET /api/user-codes/` - Vérifier QR codes scannés

### 4. DjangoGameService
**Fichier** : `lib/services/django_game_service.dart`

**Fonctionnalités** :
- Jeux Scratch & Win et Roue de la Chance
- Limites quotidiennes de jeux
- Historique des parties
- Statistiques de jeux

**Endpoints utilisés** :
- `POST /api/games/play/` - Jouer à un jeu
- `GET /api/games/history/` - Historique des jeux
- `GET /api/games/available/` - Jeux disponibles

### 5. DjangoExchangeService
**Fichier** : `lib/services/django_exchange_service.dart`

**Fonctionnalités** :
- Création de demandes d'échange
- Validation des codes d'échange
- Confirmation des échanges
- Historique des échanges

**Endpoints utilisés** :
- `POST /api/exchanges/create/` - Créer demande
- `POST /api/exchanges/validate/` - Valider code
- `POST /api/exchanges/confirm/` - Confirmer échange
- `GET /api/exchanges/list/` - Liste des échanges

## 🔑 Configuration

### Variables d'environnement
Créer un fichier `.env` dans `aya_backend/` :
```env
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2
DATABASE_URL=sqlite:///db.sqlite3
```

### Configuration Flutter
**Fichier** : `lib/config/django_config.dart`

```dart
class DjangoConfig {
  static const String baseUrl = 'http://localhost:8000/api';
  static const int requestTimeout = 30;
  // ... autres configurations
}
```

## 🚀 Démarrage

### 1. Backend Django
```bash
cd aya_backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
python manage.py migrate
python create_test_data.py
python manage.py runserver
```

### 2. Application Flutter
```bash
cd ..  # Retour au dossier racine
flutter pub get
flutter run
```

## 🧪 Comptes de Test

### Utilisateur de Démonstration
- **Email** : `demo@example.com`
- **Mot de passe** : `password`
- **Points** : 100 points disponibles
- **QR codes** : 2 codes déjà scannés

### Utilisateur Test
- **Email** : `test@aya.com`
- **Mot de passe** : `test123`
- **Points** : 200 points disponibles

## 🎯 QR Codes de Test

- `VALID_QR_CODE` - 50 points
- `BONUS_QR_100` - 100 points
- `SMALL_QR_10` - 10 points
- `ALREADY_USED` - 30 points (déjà utilisé)
- `EXPIRED_QR` - 25 points (expiré)

## 💱 Codes d'Échange de Test

- `EXCH_DEMO_001` - 30 points (complété)
- `EXCH_DEMO_002` - 20 points (en attente)

## 🔄 Migration des Services

### Avant (Services Locaux)
```dart
final LocalAuthService _authService = LocalAuthService();
final LocalUserService _userService = LocalUserService();
```

### Après (Services Django)
```dart
final DjangoAuthService _authService = DjangoAuthService();
final DjangoUserService _userService = DjangoUserService(DjangoAuthService());
```

## 🛠️ Développement

### Ajout de nouveaux endpoints
1. Créer la vue dans Django (`views.py`)
2. Ajouter l'URL dans `urls.py`
3. Créer le serializer si nécessaire
4. Mettre à jour le service Flutter correspondant

### Gestion des erreurs
```dart
try {
  final response = await http.post(/* ... */);
  if (response.statusCode == 200) {
    // Succès
  } else {
    // Gérer l'erreur
  }
} catch (e) {
  // Erreur de connexion
}
```

### Authentification automatique
Les services Django gèrent automatiquement :
- L'ajout des headers d'authentification
- Le rafraîchissement des tokens
- La gestion des erreurs 401 (non authentifié)

## 📱 Test sur Appareil

### Configuration réseau
Pour tester sur un appareil physique :
1. Changer l'URL dans `DjangoConfig` vers l'IP de votre machine
2. Démarrer Django avec `python manage.py runserver 0.0.0.0:8000`
3. Mettre à jour `ALLOWED_HOSTS` dans les settings Django

### Exemple de configuration
```dart
// Dans django_config.dart
static const String baseUrl = 'http://192.168.1.100:8000/api';
```

## 🚨 Dépannage

### Erreurs courantes

1. **Connexion refusée**
   - Vérifier que Django est démarré
   - Vérifier l'URL dans la configuration
   - Vérifier les paramètres CORS

2. **Erreur 401 (Non authentifié)**
   - Vérifier que l'utilisateur est connecté
   - Vérifier la validité du token
   - Tenter une reconnexion

3. **Erreur 500 (Serveur)**
   - Vérifier les logs Django
   - Vérifier la base de données
   - Vérifier les migrations

### Logs utiles
```bash
# Logs Django
python manage.py runserver --verbosity=2

# Logs Flutter
flutter run --verbose
```

## 📊 Monitoring

### Endpoints de santé
- `GET /api/games/available/` - Test de connectivité
- `GET /api/auth/profile/` - Test d'authentification

### Métriques importantes
- Temps de réponse des API
- Taux d'erreur des requêtes
- Utilisation des tokens JWT

## 🔒 Sécurité

### Bonnes pratiques
- Utiliser HTTPS en production
- Valider toutes les entrées côté serveur
- Limiter les tentatives de connexion
- Chiffrer les données sensibles

### Configuration production
```python
# settings.py
DEBUG = False
ALLOWED_HOSTS = ['yourdomain.com']
CORS_ALLOWED_ORIGINS = ['https://yourdomain.com']
```

## 📈 Évolutions futures

### Fonctionnalités possibles
- Notifications push
- Géolocalisation des QR codes
- Analytics avancées
- Système de parrainage
- Intégration paiements

### Optimisations
- Cache Redis
- CDN pour les assets
- Base de données optimisée
- Compression des réponses

---

## ✅ Checklist d'intégration

- [x] Backend Django configuré
- [x] Modèles de données créés
- [x] API REST implémentée
- [x] Services Flutter créés
- [x] Authentification JWT
- [x] Gestion des QR codes
- [x] Système de jeux
- [x] Gestion des échanges
- [x] Données de test
- [x] Documentation complète

L'intégration Django est maintenant complète et prête pour le développement et les tests ! 🎉
