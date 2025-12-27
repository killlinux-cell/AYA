# 🔧 Correction : Vidéo Uploadée Mais Introuvable

## 🐛 Problème Identifié

```python
MEDIA_ROOT = '/var/www/aya_backend/media/'  # ❌ Chemin Linux/Production
```

**Cause :**
- Vous êtes sur **Windows** en développement local
- `MEDIA_ROOT` était configuré pour un chemin **Linux de production** (`/var/www/...`)
- Django a uploadé votre vidéo dans `C:\var\www\aya_backend\media\` au lieu de `D:\aya\aya_backend\media\`
- L'application mobile cherche la vidéo au mauvais endroit

---

## ✅ Solution Appliquée

### Fichier : `aya_backend/aya_project/settings.py`

**Avant :**
```python
MEDIA_URL = '/media/'
MEDIA_ROOT = '/var/www/aya_backend/media/'  # ❌ Chemin Linux
```

**Après :**
```python
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'  # ✅ Chemin dynamique (Windows/Linux)
```

**`BASE_DIR / 'media'` signifie :**
- Windows : `D:\aya\aya_backend\media\`
- Linux : `/chemin/vers/aya_backend/media/`
- Fonctionne automatiquement sur les deux systèmes

---

## 🔄 Actions Requises

### 1. **Redémarrer Django** (IMPORTANT)
```bash
# Dans le terminal Django, appuyez sur Ctrl+C
# Puis relancez :
cd aya_backend
python manage.py runserver 0.0.0.0:8000
```

### 2. **Re-uploader la Vidéo**
Votre vidéo "OKPUB" a été uploadée au mauvais endroit. Il faut la re-uploader :

1. Allez sur le dashboard : `http://127.0.0.1:8000/dashboard/advertisements/`
2. **Supprimez** la vidéo "OKPUB" actuelle (icône poubelle rouge)
3. Cliquez sur **"+ Ajouter une Vidéo Publicitaire"**
4. Re-uploadez votre vidéo :
   - **Titre** : OKPUB
   - **Fichier vidéo** : Sélectionnez votre MP4
   - **Est active** : ✅ Cochez
   - **Durée** : 5 secondes
   - **Priorité** : 5 (pour plus de chances d'affichage)
5. Cliquez sur **"Créer"**

---

## 🧪 Vérification

### Après Re-Upload :

1. **Vérifiez que le fichier existe** :
   ```bash
   dir aya_backend\media\advertisements\videos
   ```
   Vous devriez voir un fichier (ex: `OKPUB_abc123.mp4`)

2. **Testez l'accès via navigateur** :
   ```
   http://192.168.1.57:8000/media/advertisements/videos/[NOM_FICHIER].mp4
   ```
   La vidéo devrait se télécharger ou se lire

3. **Sur le téléphone** :
   - Fermez l'app Aya+ complètement
   - Relancez-la
   - Allez sur la page d'accueil
   - **La vidéo devrait maintenant s'afficher et se lire ! 🎥**

---

## 📊 Logs Django Attendus

### Avant (404 - Vidéo Introuvable) :
```
❌ "GET /media/advertisements/videos/xxx.mp4 HTTP/1.1" 404 179
```

### Après (200 - Vidéo Trouvée) :
```
✅ "GET /media/advertisements/videos/xxx.mp4 HTTP/1.1" 200 1234567
```

---

## 💡 À Propos des Miniatures

Le dossier `media/advertisements/thumbnails` est **optionnel**. Les miniatures ne sont pas obligatoires pour que les vidéos fonctionnent.

**Si vous voulez des miniatures** :
1. Uploadez une image lors de la création de la publicité (champ "Miniature")
2. Ou Django peut générer automatiquement des miniatures (nécessite `ffmpeg`)

**Pour l'instant, concentrons-nous sur la vidéo elle-même.**

---

## 🎯 Résumé des Actions

| Action | Status | À Faire |
|--------|--------|---------|
| `MEDIA_ROOT` corrigé | ✅ | - |
| Django redémarré | ⏳ | **Redémarrer maintenant** |
| Ancienne vidéo supprimée | ⏳ | Supprimer via dashboard |
| Nouvelle vidéo uploadée | ⏳ | Re-uploader |
| Test sur téléphone | ⏳ | Tester après re-upload |

---

## 🚀 Prochaines Étapes (Dans l'Ordre)

1. ⏱️ **MAINTENANT** : Redémarrez Django (`Ctrl+C` puis `python manage.py runserver 0.0.0.0:8000`)
2. 🗑️ Supprimez la vidéo "OKPUB" actuelle via le dashboard
3. ➕ Re-uploadez votre vidéo via "+ Ajouter une Vidéo Publicitaire"
4. ✅ Vérifiez que le fichier apparaît dans `aya_backend\media\advertisements\videos\`
5. 📱 Testez sur le téléphone

---

## 🎬 Résultat Attendu

Une fois la vidéo re-uploadée au bon endroit :
- ✅ La vidéo sera accessible via HTTP
- ✅ L'application mobile pourra la télécharger
- ✅ ExoPlayer pourra la lire (très forte probabilité sur vrai téléphone)
- ✅ Lecture automatique, en boucle, muet sur la page d'accueil

---

**Date de correction :** 6 novembre 2025  
**Problème :** `MEDIA_ROOT` configuré pour Linux au lieu de Windows  
**Impact :** ✅ Vidéos maintenant uploadées au bon endroit

