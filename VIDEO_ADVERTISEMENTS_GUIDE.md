# 📺 Guide Complet : Publicités Vidéo

## ✅ État Actuel du Système

### Ce qui fonctionne :
1. ✅ API Backend configurée (`/api/advertisements/active/`)
2. ✅ Dashboard web pour gérer les vidéos
3. ✅ Widget Flutter avec fallback intelligent
4. ✅ Configuration réseau Android (HTTP autorisé pour développement)
5. ✅ Dossiers créés : `media/advertisements/videos/` et `media/advertisements/thumbnails/`
6. ✅ Affichage des vendeurs opérationnel
7. ✅ Toutes les routes API corrigées

### Fonctionnalité de Fallback :
- Si aucune vidéo n'est uploadée → Affiche `advertisement.jpg`
- Si une vidéo échoue à charger → Affiche `advertisement.jpg`
- Si le réseau est coupé → Affiche un gradient vert avec l'icône "Publicité Aya+"

---

## 🎥 Comment Ajouter des Vidéos

### Étape 1 : Préparer vos Vidéos

#### Format Recommandé
```
Format: MP4
Codec vidéo: H.264
Codec audio: AAC
Résolution: 1280x720 (HD) ou 1920x1080 (Full HD)
Durée: 5-15 secondes
Taille: < 10 MB par vidéo
```

#### Convertir une Vidéo (si nécessaire)
Si vous avez `ffmpeg` installé :
```bash
ffmpeg -i input.mp4 -c:v libx264 -c:a aac -vf scale=1280:720 -b:v 1M output.mp4
```

Sinon, utilisez des outils en ligne :
- [CloudConvert](https://cloudconvert.com/mp4-converter)
- [Online-Convert](https://www.online-convert.com/)

---

### Étape 2 : Uploader via le Dashboard

1. **Démarrer Django**
   ```bash
   cd aya_backend
   python manage.py runserver
   ```

2. **Accéder au Dashboard**
   - Ouvrez: `http://localhost:8000/dashboard/`
   - Connectez-vous avec vos identifiants admin

3. **Aller dans "Publicités Vidéo"**
   - Menu de gauche → "Publicités Vidéo"
   - Ou directement: `http://localhost:8000/dashboard/advertisements/`

4. **Créer une Nouvelle Publicité**
   - Cliquez sur "Créer une nouvelle publicité"
   - Remplissez le formulaire :
     - **Titre** : Nom de la publicité (ex: "Promo Aya Huile")
     - **Description** : Description courte
     - **Fichier vidéo** : Sélectionnez votre MP4
     - **Miniature** (optionnel) : Image de prévisualisation
     - **Est active** : ✅ Cochez pour activer
     - **Date de début** : Date actuelle
     - **Date de fin** : Laisser vide pour illimité
     - **Durée (secondes)** : Durée d'affichage (ex: 10)
     - **Priorité** : Plus le chiffre est élevé, plus la vidéo est affichée souvent (ex: 5)

5. **Enregistrer**
   - Cliquez sur "Créer"
   - La vidéo est maintenant disponible pour l'application mobile

---

### Étape 3 : Vérifier dans l'Application

1. **Relancer l'Application Flutter**
   ```bash
   flutter run
   ```

2. **Observer les Logs**
   Recherchez :
   ```
   I/flutter: 📺 AdvertisementService: Récupération des publicités actives...
   I/flutter: ✅ 1 publicités récupérées
   I/flutter: 🎬 Chargement vidéo: [Titre] ([URL])
   I/flutter: ✅ Vidéo initialisée et en lecture
   ```

3. **Vérifier l'Affichage**
   - La vidéo doit apparaître en bas de la page d'accueil
   - Lecture automatique, en boucle, muet
   - Changement automatique toutes les X secondes (selon durée configurée)

---

## 🐛 Dépannage

### Problème : "Aucune publicité active disponible"

**Cause possible :**
- Aucune vidéo uploadée
- Vidéos désactivées dans le dashboard
- Dates de début/fin incorrectes

**Solution :**
1. Accédez au dashboard : `http://localhost:8000/dashboard/advertisements/`
2. Vérifiez que "Est active" est coché
3. Vérifiez les dates de début et fin
4. Cliquez sur "Activer" si nécessaire

---

### Problème : "Erreur initialisation vidéo: PlatformException"

**Causes possibles :**
1. **Vidéo non compatible**
   - Format incorrect (pas MP4/H.264)
   - Vidéo corrompue
   - Taille trop grande

2. **Serveur Django non démarré**
   - Vérifiez : `http://localhost:8000/media/advertisements/videos/`
   - Vous devriez voir votre vidéo ou un listing de fichiers

3. **Permissions réseau Android**
   - Vérifiez que `network_security_config.xml` existe
   - Vérifiez que `usesCleartextTraffic="true"` est dans le Manifest

**Solutions :**
```bash
# 1. Convertir la vidéo
ffmpeg -i input.mp4 -c:v libx264 -c:a aac -vf scale=1280:720 -b:v 1M output.mp4

# 2. Rebuild Flutter
flutter clean
flutter pub get
flutter run

# 3. Vérifier le serveur Django
cd aya_backend
python manage.py runserver
```

---

### Problème : Vidéo ne s'affiche pas, mais pas d'erreur

**Solution : Fallback actif**

C'est normal ! Le système affiche `advertisement.jpg` en attendant que :
1. Une vidéo soit uploadée
2. Le serveur Django soit démarré
3. La vidéo soit correctement formatée

**Pour désactiver le fallback :**
- Uploadez au moins une vidéo valide via le dashboard
- Redémarrez l'application Flutter

---

## 📊 Gestion des Publicités

### Priorité des Vidéos

La **priorité** détermine la fréquence d'affichage :
- **Priorité 1** : Affiché rarement
- **Priorité 5** : Affiché fréquemment (recommandé)
- **Priorité 10** : Affiché très souvent

**Exemple :**
- Vidéo A (priorité 5) + Vidéo B (priorité 1) = A affichée 5 fois plus souvent que B

### Dates d'Affichage

- **Date de début** : La vidéo commence à être affichée à cette date
- **Date de fin** : (Optionnel) La vidéo cesse d'être affichée après cette date
- Si **Date de fin** est vide, la vidéo est affichée indéfiniment

### Rotation Automatique

- Les vidéos changent automatiquement selon la **durée** configurée
- Si plusieurs vidéos sont actives, elles sont affichées aléatoirement (pondérées par priorité)

---

## 🔐 Production

### Avant de Déployer en Production

1. **Configurer HTTPS**
   - Le serveur Django doit utiliser HTTPS (via Nginx avec SSL)
   - Les vidéos doivent être servies via HTTPS

2. **Mise à Jour de la Configuration Flutter**
   ```dart
   // lib/config/django_config.dart
   static const String baseUrl = 'https://votre-domaine.com';
   ```

3. **Modifier `network_security_config.xml`**
   ```xml
   <!-- Retirer les domaines de développement -->
   <base-config cleartextTrafficPermitted="false">
       <trust-anchors>
           <certificates src="system" />
       </trust-anchors>
   </base-config>
   ```

4. **Optimiser les Vidéos**
   - Compresser pour réduire la taille (< 5 MB recommandé)
   - Utiliser un CDN si possible pour une meilleure performance

---

## 📈 Statistiques

Le système enregistre automatiquement :
- **Nombre de vues** : Combien de fois la vidéo a été vue
- **Date de création** : Quand la vidéo a été uploadée
- **Date de mise à jour** : Dernière modification

**Accès aux stats :**
- Dashboard → Publicités Vidéo
- Colonne "Vues" affiche le nombre de vues par vidéo

---

## 🎯 Résumé des Fichiers Modifiés/Créés

| Fichier | Statut | Description |
|---------|--------|-------------|
| `lib/widgets/api_video_widget.dart` | ✅ Modifié | Widget avec fallback intelligent |
| `lib/services/advertisement_service.dart` | ✅ Créé | Service pour récupérer les vidéos |
| `aya_backend/dashboard/models_ads.py` | ✅ Créé | Modèle Django pour les publicités |
| `aya_backend/dashboard/serializers_ads.py` | ✅ Créé | Serializer pour l'API |
| `aya_backend/dashboard/views_ads.py` | ✅ Créé | Vues dashboard et API |
| `aya_backend/dashboard/templates/dashboard/advertisements.html` | ✅ Créé | Template liste des publicités |
| `aya_backend/dashboard/templates/dashboard/create_advertisement.html` | ✅ Créé | Template création publicité |
| `android/app/src/main/res/xml/network_security_config.xml` | ✅ Créé | Config réseau Android |
| `android/app/src/main/AndroidManifest.xml` | ✅ Modifié | Permissions HTTP |
| `media/advertisements/videos/` | ✅ Créé | Dossier vidéos |
| `media/advertisements/thumbnails/` | ✅ Créé | Dossier miniatures |

---

## 🚀 Actions Recommandées Maintenant

1. ✅ **Préparer 2-3 vidéos MP4** (format H.264, < 10 MB)
2. ✅ **Uploader via le dashboard** (`http://localhost:8000/dashboard/advertisements/`)
3. ✅ **Activer les vidéos** (cocher "Est active")
4. ✅ **Relancer l'application Flutter** (`flutter run`)
5. ✅ **Vérifier l'affichage** sur la page d'accueil

---

## 📞 Support

Si les vidéos ne s'affichent toujours pas après avoir suivi ce guide :

1. Vérifiez les logs Flutter pour les erreurs spécifiques
2. Vérifiez les logs Django : `python manage.py runserver`
3. Testez l'accès à la vidéo dans un navigateur : `http://localhost:8000/media/advertisements/videos/votre_video.mp4`
4. Vérifiez le format de la vidéo avec `ffprobe` ou VLC

---

**Date de création :** 6 novembre 2025  
**Version du système :** 2.0  
**Status :** ✅ Prêt pour le développement et les tests

