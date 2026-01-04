# 📊 Affichage des Versions dans Google Play Console

## 📱 Format d'Affichage

Dans Google Play Console, les versions sont affichées comme suit :

```
versionCode (versionName)
```

---

## 🔢 Votre Cas

### Version Actuelle (Déjà Téléversée)

**Dans `pubspec.yaml`** :
```yaml
version: 1.0.0+1
```

**Dans Google Play Console** :
```
1 (1.0.0)
```

**Signification** :
- `1` = versionCode (numéro interne)
- `1.0.0` = versionName (affiché aux utilisateurs)

---

### Nouvelle Version (À Téléverser)

**Dans `pubspec.yaml`** (déjà modifié) :
```yaml
version: 1.0.0+2
```

**Dans Google Play Console** (après téléversement) :
```
2 (1.0.0)
```

**Signification** :
- `2` = versionCode (incrémenté de 1 → 2)
- `1.0.0` = versionName (reste le même)

---

## 📋 Comparaison

| Version | pubspec.yaml | Google Play Console | VersionCode | VersionName |
|---------|--------------|---------------------|-------------|-------------|
| **Actuelle** | `1.0.0+1` | `1 (1.0.0)` | 1 | 1.0.0 |
| **Nouvelle** | `1.0.0+2` | `2 (1.0.0)` | 2 | 1.0.0 |

---

## 🎯 Exemples de Versions Futures

### Si vous gardez le même versionName :

| pubspec.yaml | Google Play Console |
|--------------|---------------------|
| `1.0.0+1` | `1 (1.0.0)` |
| `1.0.0+2` | `2 (1.0.0)` |
| `1.0.0+3` | `3 (1.0.0)` |
| `1.0.0+4` | `4 (1.0.0)` |

### Si vous changez le versionName :

| pubspec.yaml | Google Play Console |
|--------------|---------------------|
| `1.0.0+1` | `1 (1.0.0)` |
| `1.0.0+2` | `2 (1.0.0)` |
| `1.0.1+3` | `3 (1.0.1)` |
| `1.1.0+4` | `4 (1.1.0)` |
| `2.0.0+5` | `5 (2.0.0)` |

---

## ✅ Règles Importantes

### 1. VersionCode DOIT Toujours Augmenter

- ✅ `1` → `2` → `3` → `4` (OK)
- ❌ `1` → `1` (IMPOSSIBLE - Google Play refuse)
- ❌ `2` → `1` (IMPOSSIBLE - Google Play refuse)

### 2. VersionName Peut Rester le Même

- ✅ `1.0.0` → `1.0.0` (OK)
- ✅ `1.0.0` → `1.0.1` (OK)
- ✅ `1.0.0` → `2.0.0` (OK)

### 3. Format dans pubspec.yaml

```yaml
version: versionName+versionCode
```

**Exemples** :
- `1.0.0+1` = versionName 1.0.0, versionCode 1
- `1.0.0+2` = versionName 1.0.0, versionCode 2
- `1.0.1+3` = versionName 1.0.1, versionCode 3

---

## 📱 Ce que Voient les Utilisateurs

### Dans Google Play Store :

Les utilisateurs voient uniquement le **versionName** :
- Version actuelle : `1.0.0`
- Nouvelle version : `1.0.0` (même affichage)

### Dans l'Application :

Dans les paramètres de l'app, ils peuvent voir :
- Version : `1.0.0`
- Build : `2` (parfois affiché)

---

## 🔍 Vérification dans Google Play Console

### Où Voir les Versions :

1. **Google Play Console** → Votre application
2. **Tests fermés - Alpha** → **Versions**
3. Vous verrez :
   ```
   Version 1 (1.0.0) - Publiée le [date]
   Version 2 (1.0.0) - En attente de publication
   ```

### Après Téléversement :

Vous verrez deux versions :
- ✅ `1 (1.0.0)` - Version précédente
- ✅ `2 (1.0.0)` - Nouvelle version (active)

---

## 💡 Recommandations

### Pour les Corrections (Comme Maintenant) :

```yaml
version: 1.0.0+2  # ✅ Bon choix
```

**Affichage** : `2 (1.0.0)`

### Pour les Nouvelles Fonctionnalités :

```yaml
version: 1.0.1+3  # ✅ Indique une mise à jour mineure
```

**Affichage** : `3 (1.0.1)`

### Pour les Mises à Jour Majeures :

```yaml
version: 1.1.0+4  # ✅ Indique une mise à jour importante
```

**Affichage** : `4 (1.1.0)`

---

## ✅ Résumé pour Votre Cas

**Version actuelle** :
- pubspec.yaml : `1.0.0+1`
- Google Play : `1 (1.0.0)`

**Nouvelle version** :
- pubspec.yaml : `1.0.0+2` ✅ (déjà modifié)
- Google Play : `2 (1.0.0)` ✅ (après téléversement)

**Résultat** : La version sera affichée comme **`2 (1.0.0)`** dans Google Play Console.

