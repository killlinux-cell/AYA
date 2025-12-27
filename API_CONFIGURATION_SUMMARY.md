# Configuration API Aya+ - Résumé

## 🌐 URLs de Base

### Backend Django (Production)
- **URL principale**: `http://199.231.191.234/`
- **API Base**: `http://199.231.191.234/api`
- **Dashboard**: `http://199.231.191.234/dashboard/`
- **Admin Django**: `http://199.231.191.234/admin/`

## 📱 Configuration Flutter

### Fichier: `lib/config/django_config.dart`
```dart
static const String baseUrl = 'http://199.231.191.234/api';
static const String authUrl = '$baseUrl/auth';
static const String qrUrl = baseUrl;
static const bool isDevelopment = false;
```

## 🔗 Endpoints API Principaux

### Authentification
- **Connexion**: `POST /api/auth/login/`
- **Inscription**: `POST /api/auth/register/`
- **Profil**: `GET /api/auth/profile/`
- **Refresh Token**: `POST /api/auth/token/refresh/`
- **Déconnexion**: `POST /api/auth/logout/`

### QR Codes & Jeux
- **Validation QR**: `POST /api/validate/`
- **Validation & Claim**: `POST /api/validate-and-claim/`
- **Codes utilisateur**: `GET /api/user-codes/`
- **Jouer**: `POST /api/games/play/`
- **Historique jeux**: `GET /api/games/history/`
- **Jeux disponibles**: `GET /api/games/available/`

### Échanges
- **Créer échange**: `POST /api/exchanges/create/`
- **Liste échanges**: `GET /api/exchanges/list/`
- **Valider échange**: `POST /api/exchanges/validate/`
- **Confirmer échange**: `POST /api/exchanges/confirm/`

### Tokens d'échange
- **Créer token**: `POST /api/exchange-tokens/create/`
- **Valider token**: `POST /api/exchange-tokens/validate/`

### Statistiques
- **Stats utilisateur**: `GET /api/stats/`

### Vendeurs
- **Connexion vendeur**: `POST /api/vendor/login/`
- **Info client**: `GET /api/client/{id}/`

## 🛠️ Services Flutter Mis à Jour

### ✅ Services configurés correctement:
1. `DjangoAuthService` - Authentification principale
2. `QRPrizeService` - Validation des QR codes
3. `DjangoGameService` - Gestion des jeux
4. `DjangoExchangeService` - Gestion des échanges
5. `ExchangeTokenService` - Tokens d'échange
6. `ClientInfoService` - Informations clients (vendeurs)
7. `VendorAuthService` - Authentification vendeurs

### ✅ Écrans mis à jour:
1. `ScratchAndWinGameScreen` - Jeu scratch
2. `SpinWheelGameScreen` - Jeu roue

## 🔧 Configuration Serveur

### Nginx (Production)
```nginx
server {
    listen 80;
    server_name aya-plus.orapide.shop 199.231.191.234;

    location /static/ {
        alias /var/www/aya_backend/static/;
    }

    location /media/ {
        alias /var/www/aya_backend/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/aya_backend/aya_backend.sock;
    }
}
```

### Django Settings
```python
STATIC_URL = '/static/'
STATIC_ROOT = '/var/www/aya_backend/static/'
MEDIA_URL = '/media/'
MEDIA_ROOT = '/var/www/aya_backend/media/'
LOGIN_URL = '/accounts/login/'
LOGIN_REDIRECT_URL = '/dashboard/'
LOGOUT_REDIRECT_URL = '/accounts/login/'
```

## ✅ Problèmes Résolus

1. **URLs Flutter**: Mise à jour vers `http://199.231.191.234/api` (sans port 8000)
2. **Déconnexion Dashboard**: Redirection vers `/accounts/login/` après logout
3. **Fichiers statiques**: Configuration Nginx avec `alias` au lieu de `root`
4. **Authentification**: Backend personnalisé pour utiliser l'email

## 🧪 Test de Connectivité

Utilisez la classe `APITest` dans `lib/utils/api_test.dart` pour tester:
- Connectivité serveur
- Endpoints d'authentification
- Endpoints QR codes
- Configuration générale

## 📋 Checklist de Déploiement

- [x] URLs Flutter mises à jour
- [x] Configuration Nginx corrigée
- [x] Fichiers statiques collectés
- [x] Authentification dashboard configurée
- [x] Déconnexion fonctionnelle
- [x] Tous les services Flutter mis à jour
- [x] Permissions serveur correctes

## 🚀 Prochaines Étapes

1. Tester l'application Flutter avec la nouvelle configuration
2. Vérifier que tous les endpoints répondent correctement
3. Tester l'authentification et les fonctionnalités principales
4. Monitorer les logs pour détecter d'éventuelles erreurs
