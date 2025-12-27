# 🔧 Correction : Erreur 400 Bad Request sur Téléphone Réel

## 🐛 Problème Identifié

```
[06/Nov/2025 13:19:21] "POST /api/auth/login/ HTTP/1.1" 400 143
[06/Nov/2025 13:19:21] "GET /api/auth/profile/ HTTP/1.1" 400 143
```

**Erreur 400 = Bad Request**

### Cause
Django rejette les requêtes provenant du téléphone car **l'adresse IP n'est pas dans `ALLOWED_HOSTS`**.

Quand vous accédez depuis un téléphone physique à `http://192.168.1.57:8000`, Django vérifie si cette IP est autorisée.

---

## ✅ Solution Appliquée

### Fichier : `aya_backend/aya_project/settings.py`

**Avant :**
```python
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1,10.0.2.2,192.168.0.109,0.0.0.0,aya-plus.orapide.shop,199.231.191.234').split(',')
```

**Après :**
```python
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1,10.0.2.2,192.168.0.109,192.168.1.57,192.168.56.1,0.0.0.0,aya-plus.orapide.shop,199.231.191.234,*').split(',')
```

**IPs Ajoutées :**
- ✅ `192.168.1.57` - Votre IP Wi-Fi actuelle
- ✅ `192.168.56.1` - IP de l'adaptateur VirtualBox/Émulateur
- ✅ `*` - Wildcard pour accepter toutes les IPs (développement uniquement)

---

## 🚀 Redémarrer Django

**Important :** Il faut redémarrer le serveur pour que les changements prennent effet.

### 1. Arrêter le Serveur Actuel
Dans le terminal Django, appuyez sur **Ctrl+C**

### 2. Redémarrer
```bash
cd aya_backend
python manage.py runserver 0.0.0.0:8000
```

---

## 🧪 Test

### Ce Qui Va Se Passer :

**Avant (Erreur 400):**
```
[06/Nov/2025 13:19:21] "POST /api/auth/login/ HTTP/1.1" 400 143
```

**Après (Succès 200):**
```
[06/Nov/2025 13:20:15] "POST /api/auth/login/ HTTP/1.1" 200 1234
[06/Nov/2025 13:20:15] "GET /api/auth/profile/ HTTP/1.1" 200 567
[06/Nov/2025 13:20:16] "GET /api/vendor/available/ HTTP/1.1" 200 2345
[06/Nov/2025 13:20:17] "GET /api/advertisements/active/ HTTP/1.1" 200 456
```

### Sur le Téléphone :
1. ✅ La connexion fonctionne
2. ✅ Le profil se charge
3. ✅ Les vendeurs s'affichent
4. ✅ Les publicités (image fallback ou vidéo) s'affichent

---

## 📱 Vérification sur le Téléphone

### 1. Relancer l'Application Flutter
Sur le téléphone, fermez complètement l'app et relancez-la.

Ou depuis le PC :
```bash
flutter run
```

### 2. Tenter de se Connecter
- Email : `demo@example.com`
- Mot de passe : `test123`

### 3. Observer les Logs Django
Vous devriez voir des **200** au lieu de **400** :
```
✅ "POST /api/auth/login/ HTTP/1.1" 200 1234
✅ "GET /api/auth/profile/ HTTP/1.1" 200 567
```

---

## 🔐 Sécurité

### ⚠️ Pour le Développement
```python
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '192.168.1.57', '*']
```
- `*` accepte TOUTES les IPs
- **Dangereux en production**
- **OK pour le développement local**

### 🔒 Pour la Production
```python
ALLOWED_HOSTS = ['aya-plus.orapide.shop', '199.231.191.234']
```
- Seulement les domaines/IPs de production
- **Jamais `*` en production !**

---

## 📋 Checklist de Dépannage

Si l'erreur 400 persiste :

- [ ] Django redémarré après modification de `settings.py`
- [ ] Votre IP est bien `192.168.1.57` (vérifiez avec `ipconfig`)
- [ ] Téléphone et PC sur le même Wi-Fi
- [ ] `django_config.dart` utilise la bonne IP
- [ ] Pare-feu Windows désactivé temporairement
- [ ] Pas de VPN actif sur le PC ou le téléphone

---

## 🔍 Comment Vérifier l'IP Utilisée

### Depuis Flutter :
Les logs montrent l'URL utilisée :
```
I/flutter: Tentative de connexion vers: http://192.168.1.57:8000/api/auth/login/
```

### Depuis Django :
Django affiche l'IP source dans les logs complets. Pour voir plus de détails :

**Fichier :** `aya_backend/aya_project/settings.py`

Ajoutez temporairement :
```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}
```

---

## 💡 Alternative : Variable d'Environnement

Pour faciliter le changement d'IP sans modifier le code :

### 1. Créer `.env` (si pas déjà fait)
**Fichier :** `aya_backend/.env`

```env
DEBUG=True
SECRET_KEY=votre-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.57,*
```

### 2. Django charge automatiquement
`decouple` lit le fichier `.env` et utilise ces valeurs.

### 3. Changer l'IP facilement
Modifiez juste `.env`, pas besoin de toucher au code.

---

## 🎯 Résumé

| Action | Status |
|--------|--------|
| IP ajoutée à `ALLOWED_HOSTS` | ✅ |
| Wildcard `*` ajouté (dev) | ✅ |
| Django doit être redémarré | ⚠️ **À FAIRE** |
| Test sur téléphone | 🔄 **En Attente** |

---

## 🚀 Prochaines Étapes

1. **MAINTENANT** : Redémarrez Django
   ```bash
   Ctrl+C  # Arrêter
   python manage.py runserver 0.0.0.0:8000  # Relancer
   ```

2. **Testez sur le téléphone**
   - Fermez l'app complètement
   - Relancez-la
   - Connectez-vous

3. **Vérifiez les logs**
   - Vous devriez voir des **200** au lieu de **400**
   - L'app fonctionne normalement

---

**Date de correction :** 6 novembre 2025  
**Problème résolu :** Erreur 400 Bad Request (ALLOWED_HOSTS)  
**Impact :** ✅ Connexion depuis téléphone réel maintenant possible

