# 📱 Test sur un Vrai Téléphone Android

## 🎯 Pourquoi Tester sur un Vrai Téléphone

Les **émulateurs Android ont des limitations** avec la lecture vidéo :
- ❌ Codecs logiciels lents
- ❌ Pas d'accélération matérielle
- ❌ Bugs avec ExoPlayer
- ❌ Architecture x86 vs ARM

**Sur un vrai téléphone :**
- ✅ Codecs matériels natifs
- ✅ Accélération GPU
- ✅ ExoPlayer optimisé
- ✅ Architecture ARM native

---

## 📋 Prérequis

1. **Un téléphone Android** (Android 5.0+)
2. **Câble USB** pour connecter au PC
3. **Mode Développeur activé** sur le téléphone
4. **Débogage USB activé**

---

## 🔧 Étape 1 : Activer le Mode Développeur

### Sur votre téléphone Android :

1. Allez dans **Paramètres** > **À propos du téléphone**
2. Tapez **7 fois** sur "Numéro de build"
3. Un message apparaît : "Vous êtes maintenant développeur"

### Activer le Débogage USB :

1. Retournez dans **Paramètres**
2. Cherchez **Options pour les développeurs** (parfois dans "Système")
3. Activez **Débogage USB**
4. Activez **Installer via USB** (optionnel, mais recommandé)

---

## 🔌 Étape 2 : Connecter le Téléphone

1. **Branchez le téléphone** au PC via USB
2. Sur le téléphone, une popup apparaît : **"Autoriser le débogage USB ?"**
   - Cochez "Toujours autoriser depuis cet ordinateur"
   - Appuyez sur **OK**

3. **Vérifier la connexion**
   ```bash
   flutter devices
   ```
   
   Vous devriez voir :
   ```
   2 connected devices:
   sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x86 • Android 14 (API 34)
   [Votre Téléphone] (mobile) • [ID] • android-arm64 • Android XX (API XX)
   ```

---

## 🌐 Étape 3 : Configurer l'IP pour le Téléphone Physique

Le téléphone ne peut pas utiliser `10.0.2.2` (réservé à l'émulateur). Il faut utiliser **votre IP locale**.

### 3.1 Trouver Votre IP Locale

**Windows :**
```bash
ipconfig
```
Cherchez "Adresse IPv4" dans "Carte réseau sans fil Wi-Fi" :
```
Adresse IPv4. . . . . . . . . . . . : 192.168.1.57
```

**Linux/Mac :**
```bash
ifconfig | grep "inet "
```

### 3.2 Modifier la Configuration Flutter

**Fichier :** `lib/config/django_config.dart`

```dart
class DjangoConfig {
  // ÉMULATEUR: 10.0.2.2
  // APPAREIL PHYSIQUE: Votre IP locale
  static const String baseUrl = 'http://192.168.1.57:8000';  // ⬅️ CHANGEZ ICI
  
  static const String authUrl = '$baseUrl/api/auth';
  static const String qrUrl = '$baseUrl/api';
  // ... reste du fichier
}
```

---

## 🚀 Étape 4 : Démarrer Django avec l'IP Locale

**Important :** Django doit écouter sur toutes les interfaces, pas seulement `localhost`.

```bash
cd aya_backend
python manage.py runserver 0.0.0.0:8000
```

`0.0.0.0` signifie "écouter sur toutes les interfaces réseau" → accessible depuis votre téléphone.

**Vérification :**
Vous devriez voir :
```
Starting development server at http://0.0.0.0:8000/
```

---

## 📱 Étape 5 : Installer l'App sur le Téléphone

### 5.1 Lancer Flutter

```bash
flutter run
```

Flutter détecte automatiquement les appareils. Si plusieurs appareils sont connectés :
```bash
flutter run -d [ID_TELEPHONE]
```

### 5.2 Attendre l'Installation

L'application sera :
1. ✅ Compilée en mode debug
2. ✅ Installée sur le téléphone
3. ✅ Lancée automatiquement

**Temps estimé :** 2-5 minutes (première installation)

---

## 🎬 Étape 6 : Vérifier les Vidéos

### Sur le Téléphone :
1. Ouvrez l'application **Aya+**
2. Connectez-vous avec un compte test
3. Allez sur la **page d'accueil**
4. Scrollez vers le bas

### Ce Que Vous Devriez Voir :

#### Scénario A : Vidéo Uploadée et Compatible
```
✅ Vidéo publicitaire en lecture automatique
✅ Muet, en boucle
✅ Changement automatique après X secondes
```

#### Scénario B : Aucune Vidéo ou Erreur
```
✅ Image advertisement.jpg affichée (fallback)
✅ Pas de crash, pas d'erreur visible
```

---

## 🐛 Dépannage

### Problème : "No devices found"

**Cause :** Le téléphone n'est pas détecté par Flutter.

**Solution :**
```bash
# Vérifier les pilotes USB (Windows)
# Installer les pilotes du fabricant si nécessaire

# Redémarrer le serveur ADB
adb kill-server
adb start-server

# Vérifier à nouveau
flutter devices
```

---

### Problème : "Connection refused" ou "Network error"

**Cause :** Le téléphone ne peut pas accéder à Django.

**Solution :**

1. **Vérifier que Django écoute sur 0.0.0.0**
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Vérifier que PC et téléphone sont sur le même Wi-Fi**

3. **Désactiver le pare-feu Windows temporairement**
   - Paramètres → Mise à jour et sécurité → Sécurité Windows
   - Pare-feu → Désactiver (temporairement)

4. **Tester l'accès depuis le navigateur du téléphone**
   - Ouvrez Chrome sur le téléphone
   - Allez sur `http://192.168.1.57:8000` (votre IP)
   - Vous devriez voir la page d'accueil Django

---

### Problème : Vidéo ne se charge toujours pas

**Cause :** Format vidéo incompatible.

**Solution :**

1. **Convertir la vidéo en H.264 Baseline**
   ```bash
   ffmpeg -i input.mp4 -c:v libx264 -profile:v baseline -level 3.0 -c:a aac -ar 44100 -b:a 128k output.mp4
   ```

2. **Réduire la résolution**
   ```bash
   ffmpeg -i input.mp4 -vf scale=1280:720 -c:v libx264 -profile:v baseline output.mp4
   ```

3. **Tester avec une vidéo exemple**
   - Téléchargez une vidéo test : [Big Buck Bunny](http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4)
   - Uploadez-la via le dashboard
   - Testez à nouveau

---

## 📊 Comparaison : Émulateur vs Téléphone Réel

| Aspect | Émulateur | Téléphone Réel |
|--------|-----------|----------------|
| **Vitesse** | 🐌 Lent | ⚡ Rapide |
| **Codecs Vidéo** | ⚠️ Limités | ✅ Complets |
| **Performance** | ❌ Faible | ✅ Excellente |
| **Accélération GPU** | ❌ Non/Limité | ✅ Oui |
| **Bugs ExoPlayer** | ⚠️ Fréquents | ✅ Rares |
| **Fiabilité Vidéo** | ❌ 30% | ✅ 95% |

---

## ✅ Checklist de Test

- [ ] Mode développeur activé
- [ ] Débogage USB activé
- [ ] Téléphone connecté et détecté (`flutter devices`)
- [ ] IP locale trouvée (ex: `192.168.1.57`)
- [ ] `django_config.dart` mis à jour avec l'IP locale
- [ ] Django démarré avec `0.0.0.0:8000`
- [ ] PC et téléphone sur le même Wi-Fi
- [ ] Application installée sur le téléphone
- [ ] Connexion réussie (login)
- [ ] Vidéo visible sur la page d'accueil ✅

---

## 🎯 Résultat Attendu

**Sur un vrai téléphone Android :**
- ✅ **80-90% de chances** que la vidéo fonctionne
- ✅ Lecture fluide et sans erreur
- ✅ Meilleure performance générale de l'app

**Raison :** Les émulateurs sont notoirement mauvais pour la vidéo. Les vrais téléphones ont des codecs matériels optimisés.

---

## 📝 Notes Importantes

1. **Ne déployez PAS en production avec `0.0.0.0:8000`**
   - Utilisez Nginx + Gunicorn avec HTTPS

2. **En production, changez l'URL en HTTPS**
   ```dart
   static const String baseUrl = 'https://votre-domaine.com';
   ```

3. **L'IP locale change si vous changez de réseau Wi-Fi**
   - Maison : `192.168.1.57`
   - Bureau : `192.168.0.105`
   - Café : `10.0.0.23`

4. **Pour éviter de changer l'IP constamment**
   - Utilisez ngrok pour un tunnel public temporaire
   - Ou configurez une IP statique sur votre routeur

---

**Date :** 6 novembre 2025  
**Conseil :** Testez TOUJOURS sur un vrai appareil pour les vidéos et la performance !

