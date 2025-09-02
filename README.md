# Aya HUILE VÉGÉTALE - Application Mobile

## 📱 Description

Application mobile Flutter pour la marque Aya HUILE VÉGÉTALE, permettant aux utilisateurs de collecter des points en scannant des codes QR et de participer à des mini-jeux pour gagner des récompenses.

## ✨ Fonctionnalités

### 🔐 Authentification
- **Connexion** : Connectez-vous à votre compte existant
- **Inscription** : Créez un nouveau compte gratuitement
- **Réinitialisation de mot de passe** : Fonctionnalité à venir

### 🏠 Page d'accueil
- **Affichage des points** : Points disponibles et échangés
- **Codes QR collectés** : Suivi de votre progression
- **Section bonus** : Offres spéciales et grand prix
- **Actions rapides** : Accès direct au scanner et aux jeux

### 🎮 Zone de jeux
- **Scratch & Win** : Grattez pour gagner des points
- **Spin a wheel** : Tournez la roue pour des récompenses
- **Règles des jeux** : Chaque jeu coûte 10 points

### 📱 Scanner QR
- **Scan de codes** : Utilisez votre caméra pour scanner
- **Collecte de points** : Gagnez entre 10 et 50 points par code
- **Suivi des codes** : Historique des codes collectés

### 👤 Profil utilisateur
- **Informations personnelles** : Nom, email, statistiques
- **Gestion du compte** : Modification des informations
- **Déconnexion** : Sécurisée avec confirmation

## 🎨 Design et UX

### Palette de couleurs
- **Vert principal** : #4CAF50 (Aya HUILE VÉGÉTALE)
- **Vert accent** : #66BB6A
- **Orange** : #FF9800 (Bonus et jeux)
- **Violet** : #9C27B0 (Spin a wheel)

### Interface utilisateur
- **Design moderne** : Cartes avec ombres et bordures arrondies
- **Responsive** : Adapté à tous les écrans mobiles
- **Animations** : Transitions fluides et feedback visuel
- **Navigation intuitive** : Barre de navigation en bas d'écran

## 🚀 Installation et configuration

### Prérequis
- Flutter SDK (version 3.0.0 ou supérieure)
- Dart SDK
- Android Studio / VS Code
- Émulateur Android ou appareil physique

### Étapes d'installation

1. **Cloner le projet**
   ```bash
   git clone [URL_DU_REPO]
   cd aya_huile_app
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   flutter run
   ```

### Configuration des dépendances

Le projet utilise les packages suivants :
- `qr_code_scanner` : Scanner de codes QR
- `shared_preferences` : Stockage local des données
- `provider` : Gestion d'état
- `http` : Appels API (à implémenter)
- `flutter_animate` : Animations avancées

## 📁 Structure du projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── models/                   # Modèles de données
│   ├── user.dart            # Modèle utilisateur
│   └── qr_code.dart         # Modèle code QR
├── providers/                # Gestion d'état
│   ├── auth_provider.dart   # Authentification
│   └── user_provider.dart   # Données utilisateur
├── screens/                  # Écrans de l'application
│   ├── splash_screen.dart   # Écran de démarrage
│   ├── auth_screen.dart     # Authentification
│   ├── home_screen.dart     # Page d'accueil
│   ├── games_screen.dart    # Zone de jeux
│   ├── qr_scanner_screen.dart # Scanner QR
│   └── profile_screen.dart  # Profil utilisateur
├── widgets/                  # Composants réutilisables
│   ├── auth_form.dart       # Formulaire d'authentification
│   ├── header_widget.dart   # En-tête avec logo
│   ├── points_display_widget.dart # Affichage des points
│   ├── collected_qr_display_widget.dart # Codes QR collectés
│   ├── bonus_section_widget.dart # Section bonus
│   └── navigation_bar_widget.dart # Barre de navigation
└── utils/                    # Utilitaires
    └── theme.dart           # Thème et styles
```

## 🔧 Configuration

### Variables d'environnement
Créez un fichier `.env` à la racine du projet :
```env
API_BASE_URL=https://api.ayahuile.com
API_KEY=your_api_key_here
```

### Configuration des polices
Les polices Poppins sont incluses dans le projet. Assurez-vous qu'elles sont correctement configurées dans `pubspec.yaml`.

## 📱 Fonctionnalités à implémenter

### Phase 2
- [ ] Intégration API réelle pour l'authentification
- [ ] Scanner QR avec caméra réelle
- [ ] Logique complète des mini-jeux
- [ ] Système de notifications push
- [ ] Mode hors ligne

### Phase 3
- [ ] Intégration avec un backend
- [ ] Système de récompenses avancé
- [ ] Partage social
- [ ] Analytics et suivi des performances
- [ ] Tests automatisés

## 🧪 Tests

### Tests unitaires
```bash
flutter test
```

### Tests d'intégration
```bash
flutter test integration_test/
```

## 📦 Build et déploiement

### Build Android
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

## 🤝 Contribution

1. Fork le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- Créez une issue sur GitHub
- Contactez l'équipe de développement
- Consultez la documentation Flutter

## 🙏 Remerciements

- Équipe Flutter pour le framework
- Communauté open source
- Équipe Aya HUILE VÉGÉTALE

---

**Développé avec ❤️ pour Aya HUILE VÉGÉTALE**
