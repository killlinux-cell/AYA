# 🗑️ Comment Retirer la Déclaration de Localisation en Arrière-Plan

## 📋 Problème

Google Play Console détecte encore `ACCESS_BACKGROUND_LOCATION` et demande une explication. Cette permission a été retirée du manifeste, mais Google Play Console utilise encore l'ancien bundle.

---

## ✅ Solution : Retirer la Déclaration dans Google Play Console

### Étape 1 : Accéder aux Autorisations

1. **Google Play Console** → Votre application **"monuniversaya"**
2. **Politique de l'application** → **Données de l'application**
3. **Autorisations et API ayant accès aux informations sensibles**
4. **Chercher** "Autorisations d'accéder à la position" ou **"Location access permissions"**

### Étape 2 : Retirer la Permission ACCESS_BACKGROUND_LOCATION

Dans la section "Autorisations d'accéder à la position", vous verrez :

- ✅ `android.permission.ACCESS_FINE_LOCATION` (à garder)
- ✅ `android.permission.ACCESS_COARSE_LOCATION` (à garder)
- ❌ `android.permission.ACCESS_BACKGROUND_LOCATION` (à retirer)

**Actions à faire** :

1. **Cliquez sur** `android.permission.ACCESS_BACKGROUND_LOCATION`
2. **Sélectionnez** "Retirer" ou **"Supprimer"** ou **"Ne pas utiliser"**
3. **Confirmez** la suppression

### Étape 3 : Si Google Demande une Explication

Si Google affiche "Expliquez-nous pourquoi votre application accède aux données de localisation en arrière-plan" :

**Réponse recommandée** :

```
Cette application n'utilise PAS la localisation en arrière-plan.

La permission ACCESS_BACKGROUND_LOCATION a été retirée du manifeste Android dans la dernière version.
L'application utilise uniquement la localisation en premier plan (ACCESS_FINE_LOCATION et ACCESS_COARSE_LOCATION)
pour :
- Obtenir la position de l'utilisateur lors de l'inscription
- Afficher les vendeurs à proximité sur une carte (fonctionnalité utilisée uniquement quand l'application est ouverte)

Aucun service en arrière-plan n'utilise la localisation.
```

### Étape 4 : Téléverser le Nouveau Bundle

**IMPORTANT** : Assurez-vous que le nouveau bundle **sans** `ACCESS_BACKGROUND_LOCATION` est téléversé :

1. **Google Play Console** → **Tester et publier** → **Tests fermés - Alpha**
2. **Créer une nouvelle version**
3. **Téléverser** le fichier `build/app/outputs/bundle/release/app-release.aab` (celui que vous venez de build)
4. **Notes de version** :
   ```
   Correction des permissions :
   - Retrait de la permission ACCESS_BACKGROUND_LOCATION non utilisée
   - L'application utilise uniquement la localisation en premier plan
   ```

---

## 🔍 Vérification

### Vérifier que la Permission est Retirée du Manifeste

Le fichier `android/app/src/main/AndroidManifest.xml` ne doit **PAS** contenir :

```xml
<!-- ❌ NE DOIT PAS ÊTRE PRÉSENT -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

Il doit contenir uniquement :

```xml
<!-- ✅ CORRECT -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<!-- ACCESS_BACKGROUND_LOCATION retiré : non utilisé dans l'application -->
```

### Vérifier dans Google Play Console

Après avoir téléversé le nouveau bundle :

1. **Google Play Console** → **Politique de l'application**
2. **Données de l'application**
3. **Autorisations et API ayant accès aux informations sensibles**
4. **Vérifier** que `ACCESS_BACKGROUND_LOCATION` n'apparaît plus dans la liste

---

## 📝 Si Google Play Console Ne Permet Pas de Retirer

Si Google Play Console ne permet pas de retirer directement la permission :

### Option A : Attendre le Nouveau Bundle

1. **Téléversez** le nouveau bundle **sans** `ACCESS_BACKGROUND_LOCATION`
2. **Attendez** 24-48 heures que Google Play analyse le nouveau bundle
3. La déclaration devrait disparaître automatiquement

### Option B : Modifier la Déclaration

Si vous devez remplir le formulaire :

1. **Cliquez sur** "Ajouter une raison" ou le champ de justification
2. **Sélectionnez** "Autre" ou "Non applicable"
3. **Expliquez** :
   ```
   Cette permission a été retirée du manifeste Android.
   L'application n'utilise pas la localisation en arrière-plan.
   Seule la localisation en premier plan est utilisée.
   ```

### Option C : Contacter le Support

Si le problème persiste :

1. **Google Play Console** → **Aide** → **Contacter le support**
2. **Expliquez** :
   - Vous avez retiré `ACCESS_BACKGROUND_LOCATION` du manifeste
   - Le nouveau bundle ne contient plus cette permission
   - Vous souhaitez retirer la déclaration de la console

---

## ✅ Checklist

- [ ] ✅ Permission retirée du manifeste (`AndroidManifest.xml`)
- [ ] ✅ Nouveau bundle build (`flutter build appbundle --release`)
- [ ] ✅ Nouveau bundle téléversé sur Google Play Console
- [ ] ✅ Déclaration retirée dans Google Play Console (si possible)
- [ ] ✅ Explication fournie (si demandée)
- [ ] ✅ Vérification après 24-48h que la déclaration a disparu

---

## 🎯 Résultat Attendu

Après ces actions :

1. ✅ `ACCESS_BACKGROUND_LOCATION` ne sera plus dans la liste des permissions déclarées
2. ✅ Google Play ne demandera plus d'explication pour la localisation en arrière-plan
3. ✅ Seules `ACCESS_FINE_LOCATION` et `ACCESS_COARSE_LOCATION` seront déclarées

---

## ⏱️ Délais

- **Téléversement** : 5 minutes
- **Analyse Google Play** : 24-48 heures
- **Mise à jour de la console** : Peut prendre jusqu'à 48 heures

---

## 🆘 Si le Problème Persiste

1. Vérifiez que le nouveau bundle est bien téléversé
2. Vérifiez que le manifeste ne contient plus la permission
3. Attendez 48 heures pour que Google Play mette à jour
4. Contactez le support Google Play si nécessaire

