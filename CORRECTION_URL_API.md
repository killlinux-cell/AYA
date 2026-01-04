# ✅ Correction URLs API - Erreur de Connexion

## 🔧 Problème Identifié

**Erreur** : Les jeux ne peuvent pas se connecter au backend lors des tests Play Store.

**Cause** : URLs incorrectes dans les écrans de jeux - il manquait `/api` dans le chemin.

---

## ✅ Corrections Appliquées

### 1. `lib/screens/spin_wheel_game_screen.dart`

**Avant** :
```dart
Uri.parse('${DjangoConfig.baseUrl}/games/play/')
// → https://monuniversaya.com/games/play/ ❌
```

**Après** :
```dart
Uri.parse('${DjangoConfig.baseUrl}/api/games/play/')
// → https://monuniversaya.com/api/games/play/ ✅
```

### 2. `lib/screens/scratch_and_win_game_screen.dart`

**Avant** :
```dart
Uri.parse('${DjangoConfig.baseUrl}/games/play/')
// → https://monuniversaya.com/games/play/ ❌
```

**Après** :
```dart
Uri.parse('${DjangoConfig.baseUrl}/api/games/play/')
// → https://monuniversaya.com/api/games/play/ ✅
```

---

## 📋 URLs Correctes

### Configuration dans `django_config.dart`

```dart
static const String baseUrl = 'https://monuniversaya.com';
static const String authUrl = '$baseUrl/api/auth';
static const String qrUrl = '$baseUrl/api';
```

### Endpoints Corrects

- ✅ **Jeux** : `https://monuniversaya.com/api/games/play/`
- ✅ **Authentification** : `https://monuniversaya.com/api/auth/login/`
- ✅ **QR Codes** : `https://monuniversaya.com/api/validate/`
- ✅ **Statistiques** : `https://monuniversaya.com/api/stats/`

---

## 🚀 Prochaines Étapes

### 1. Rebuild l'Application

```bash
cd D:\aya
flutter clean
flutter build appbundle --release
```

### 2. Téléverser le Nouveau Bundle

1. **Google Play Console** → Votre application
2. **Tests fermés - Alpha** → **Créer une version**
3. **Téléverser** le nouveau bundle AAB
4. **Enregistrer** et **publier**

### 3. Tester

1. **Téléchargez** l'application depuis Play Store (test fermé)
2. **Testez** les jeux (Roue de la Chance, Scratch & Win)
3. **Vérifiez** que la connexion fonctionne

---

## ✅ Vérification

### Test Rapide

1. **Ouvrez** l'application
2. **Allez** dans les jeux
3. **Essayez** de jouer
4. **Vérifiez** :
   - ✅ Pas d'erreur de connexion
   - ✅ Le jeu fonctionne
   - ✅ Les points sont débités/crédités

### Si Ça Ne Fonctionne Toujours Pas

Vérifiez que le backend est accessible :

1. **Testez depuis un navigateur** :
   ```
   https://monuniversaya.com/api/games/available/
   ```

2. **Vérifiez les logs du serveur** :
   - Les requêtes arrivent-elles ?
   - Y a-t-il des erreurs ?

3. **Vérifiez CORS** dans `settings.py` :
   ```python
   CORS_ALLOW_ALL_ORIGINS = True  # Temporairement pour tester
   ```

---

## 📝 Notes

- Les autres services utilisent déjà `DjangoConfig.qrUrl` qui inclut `/api`
- Seuls les écrans de jeux avaient le problème
- La correction est maintenant appliquée

---

## ✅ Résumé

**Problème** : URLs incorrectes (manquait `/api`)  
**Solution** : Ajout de `/api` dans les URLs des jeux  
**Action** : Rebuild et retéléverser le bundle

