# Guide du Système de Chargement Aya+

## Vue d'ensemble

Le système de chargement Aya+ utilise l'image `loading.png` pour afficher des indicateurs de chargement cohérents dans toute l'application. Le système est conçu pour être facilement utilisable et personnalisable.

## Composants principaux

### 1. LoadingWidget (`lib/widgets/loading_widget.dart`)

Widget de base pour afficher l'image de chargement avec animations.

```dart
LoadingWidget(
  message: 'Chargement...',
  size: 80.0,
  backgroundColor: Colors.black.withOpacity(0.8),
  fullScreen: true,
)
```

### 2. LoadingService (`lib/services/loading_service.dart`)

Service global pour gérer l'affichage/masquage du chargement.

```dart
// Afficher le chargement d'API
LoadingService.instance.showApiLoading(
  context: context,
  message: 'Chargement des données...',
);

// Masquer le chargement
LoadingService.instance.hideLoading();
```

### 3. LoadingMixin (`lib/utils/loading_mixin.dart`)

Mixin pour faciliter l'utilisation du chargement dans les écrans.

```dart
class MyScreenState extends State<MyScreen> with LoadingMixin {
  void _loadData() async {
    await executeWithApiLoading(() async {
      // Votre logique de chargement
    }, message: 'Chargement des données...');
  }
}
```

## Types de chargement

### 1. Chargement au lancement de l'application

Intégré dans `SplashScreen` avec l'image `loading.png` et un message "Initialisation...".

### 2. Chargement des appels API

Utilisé lors des requêtes vers le backend Django :

```dart
// Dans bonus_section_widget.dart
LoadingService.instance.showApiLoading(
  context: context,
  message: 'Vérification du Grand Prix...',
);
```

### 3. Chargement de navigation

Utilisé lors de la navigation entre écrans :

```dart
// Utilisation du mixin
navigateWithLoading(
  const NextScreen(),
  message: 'Chargement de l\'écran suivant...',
);
```

## Utilisation dans les écrans

### Méthode 1 : Utilisation du mixin (Recommandée)

```dart
class MyScreenState extends State<MyScreen> with LoadingMixin {
  void _navigateToNextScreen() {
    navigateWithLoading(
      const NextScreen(),
      message: 'Chargement...',
    );
  }

  void _loadData() async {
    await executeWithApiLoading(() async {
      // Logique de chargement
    }, message: 'Chargement des données...');
  }
}
```

### Méthode 2 : Utilisation directe du service

```dart
void _loadData() async {
  LoadingService.instance.showApiLoading(
    context: context,
    message: 'Chargement...',
  );
  
  try {
    // Votre logique
  } finally {
    LoadingService.instance.hideLoading();
  }
}
```

## Personnalisation

### Messages de chargement

- **API** : "Chargement des données...", "Vérification du Grand Prix..."
- **Navigation** : "Chargement des jeux...", "Chargement de la connexion vendeur..."
- **Lancement** : "Initialisation..."

### Couleurs et styles

- **API** : Fond noir semi-transparent
- **Navigation** : Fond vert Aya+ (#4CAF50)
- **Lancement** : Fond transparent sur le splash screen

## Intégration dans les widgets existants

### BonusSectionWidget

Le widget de bonus utilise maintenant le chargement lors de la vérification du Grand Prix :

```dart
LoadingService.instance.showApiLoading(
  context: context,
  message: 'Vérification du Grand Prix...',
);
```

### Écrans de navigation

Les écrans `HomeScreen` et `GamesScreen` utilisent le mixin pour la navigation :

```dart
navigateWithLoading(
  const GamesScreen(),
  message: 'Chargement des jeux...',
);
```

## Bonnes pratiques

1. **Toujours masquer le chargement** : Utilisez `finally` ou `LoadingMixin` pour s'assurer que le chargement est masqué
2. **Messages descriptifs** : Utilisez des messages clairs pour informer l'utilisateur
3. **Cohérence** : Utilisez le même style de chargement dans toute l'application
4. **Performance** : Le chargement utilise des animations optimisées

## Dépannage

### Le chargement ne s'affiche pas
- Vérifiez que le contexte est valide
- Assurez-vous que `LoadingService.instance.hideLoading()` est appelé

### Le chargement ne se masque pas
- Vérifiez que `hideLoading()` est appelé dans tous les cas (succès et erreur)
- Utilisez `LoadingMixin` pour une gestion automatique

### Animations lentes
- Les animations sont optimisées pour la performance
- L'image `loading.png` est mise en cache automatiquement

## Fichiers modifiés

- `lib/widgets/loading_widget.dart` - Widget de base
- `lib/services/loading_service.dart` - Service global
- `lib/utils/loading_mixin.dart` - Mixin d'aide
- `lib/screens/splash_screen.dart` - Intégration au lancement
- `lib/widgets/bonus_section_widget.dart` - Chargement API
- `lib/screens/home_screen.dart` - Navigation avec chargement
- `lib/screens/games_screen.dart` - Navigation avec chargement
- `lib/screens/auth_screen.dart` - Préparation pour le chargement
