# 📱 Guide de Gestion des Versions - Google Play

## ✅ Réponse Rapide

**OUI**, vous devez changer la version dans `pubspec.yaml`.  
**NON**, cela ne cassera pas le processus actuel sur Google Play.

---

## 📋 Règles de Versionnement Google Play

### Version Actuelle

```yaml
version: 1.0.0+1
```

- **1.0.0** = `versionName` (affiché aux utilisateurs)
- **+1** = `versionCode` (numéro interne, OBLIGATOIRE d'incrémenter)

### Règle Google Play

**Le `versionCode` (nombre après le `+`) DOIT être supérieur à la version précédente.**

Si vous avez déjà téléversé `1.0.0+1`, vous devez passer à `1.0.0+2` minimum.

---

## 🔄 Impact sur le Processus Actuel

### ✅ Ce qui NE sera PAS cassé :

1. **Tests fermés existants** : Continuent de fonctionner
2. **Testeurs inscrits** : Restent inscrits
3. **Période de 14 jours** : Continue de s'accumuler
4. **Données utilisateurs** : Conservées
5. **Historique** : Préservé

### ✅ Ce qui va changer :

1. **Nouvelle version** : Les testeurs devront mettre à jour l'app
2. **VersionCode** : Passera de 1 à 2
3. **Corrections** : Les bugs seront corrigés dans la nouvelle version

---

## 🎯 Recommandation pour Votre Cas

### Option 1 : Correction Mineure (RECOMMANDÉ)

```yaml
version: 1.0.0+2
```

**Avantages** :
- ✅ Correction des URLs API
- ✅ Même versionName (1.0.0)
- ✅ VersionCode incrémenté (+2)
- ✅ Indique une mise à jour de correction

### Option 2 : Version Mineure

```yaml
version: 1.0.1+2
```

**Avantages** :
- ✅ Indique une nouvelle version mineure
- ✅ VersionName et VersionCode incrémentés
- ✅ Plus clair pour les utilisateurs

---

## 📝 Étapes à Suivre

### 1. Modifier `pubspec.yaml`

**Changez** :
```yaml
version: 1.0.0+1
```

**Vers** :
```yaml
version: 1.0.0+2
```

### 2. Rebuild le Bundle

```bash
cd D:\aya
flutter clean
flutter build appbundle --release
```

### 3. Téléverser sur Google Play

1. **Google Play Console** → Votre application
2. **Tests fermés - Alpha** → **Créer une version**
3. **Téléverser** le nouveau bundle (`app-release.aab`)
4. **Notes de version** : "Correction des erreurs de connexion API"
5. **Enregistrer** et **publier**

---

## ⚠️ Points Importants

### 1. VersionCode DOIT être Supérieur

- ❌ **1.0.0+1** → Ne peut pas téléverser (déjà utilisé)
- ✅ **1.0.0+2** → Peut téléverser
- ✅ **1.0.1+2** → Peut téléverser
- ✅ **1.1.0+2** → Peut téléverser

### 2. VersionName Peut Rester le Même

- ✅ **1.0.0+1** → **1.0.0+2** (OK)
- ✅ **1.0.0+1** → **1.0.1+2** (OK)
- ✅ **1.0.0+1** → **2.0.0+2** (OK)

### 3. Les Testeurs Devront Mettre à Jour

- Les testeurs avec la version `1.0.0+1` verront une notification de mise à jour
- Ils devront télécharger la version `1.0.0+2`
- **C'est normal et attendu**

---

## 🔄 Processus de Mise à Jour pour les Testeurs

### Ce qui se passe :

1. **Vous téléversez** la version `1.0.0+2`
2. **Google Play** détecte la nouvelle version
3. **Les testeurs** reçoivent une notification de mise à jour
4. **Ils téléchargent** la nouvelle version
5. **L'application** se met à jour automatiquement

### Impact sur les 14 Jours :

- ✅ **Les jours déjà écoulés** : Conservés
- ✅ **Les testeurs actifs** : Restent actifs
- ✅ **Le compteur** : Continue de s'accumuler
- ✅ **Aucun impact négatif**

---

## 📊 Exemple de Timeline

### Scénario Actuel :

- **Jour 1** : Version `1.0.0+1` téléversée
- **Jours 1-5** : Testeurs utilisent l'app
- **Jour 6** : Vous corrigez les URLs et créez `1.0.0+2`
- **Jour 6** : Vous téléversez `1.0.0+2`
- **Jour 7** : Testeurs mettent à jour vers `1.0.0+2`
- **Jours 7-14** : Testeurs continuent d'utiliser l'app
- **Jour 15** : Vous pouvez demander l'accès production

**Résultat** : ✅ Les 14 jours sont toujours comptabilisés

---

## ✅ Checklist

- [ ] Modifier `pubspec.yaml` : `version: 1.0.0+2`
- [ ] Rebuild : `flutter build appbundle --release`
- [ ] Téléverser le nouveau bundle
- [ ] Ajouter des notes de version
- [ ] Publier dans les tests fermés
- [ ] Informer les testeurs de la mise à jour (optionnel)

---

## 💡 Conseils

### 1. Notes de Version

Ajoutez des notes claires :

```
Corrections :
- Correction des erreurs de connexion API pour les jeux
- Amélioration de la stabilité de l'application
```

### 2. Communication avec les Testeurs

Envoyez un email (optionnel) :

```
Bonjour,

Une nouvelle version de l'application est disponible avec des corrections 
importantes. Veuillez mettre à jour l'application depuis Google Play.

Merci !
```

### 3. Suivi des Versions

Gardez un journal :

```
v1.0.0+1 - Version initiale (tests fermés)
v1.0.0+2 - Correction URLs API (tests fermés)
```

---

## 🎯 Résumé

**Question** : Dois-je changer la version ?  
**Réponse** : ✅ **OUI**, obligatoire pour téléverser une nouvelle version

**Question** : Est-ce que ça va casser le processus ?  
**Réponse** : ❌ **NON**, c'est normal et nécessaire

**Action** : Changez `1.0.0+1` → `1.0.0+2` dans `pubspec.yaml`

---

## 📞 Références

- **Documentation Flutter** : https://docs.flutter.dev/deployment/android
- **Google Play Versioning** : https://developer.android.com/studio/publish/versioning

