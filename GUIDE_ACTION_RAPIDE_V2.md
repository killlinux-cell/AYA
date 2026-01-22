# ⚡ Guide d'Action Rapide V2 - Nouveaux Problèmes Google Play

## 🚨 Nouveaux Problèmes Identifiés

1. ⚠️ **"L'appli doit prendre en charge les tailles de page de mémoire de 16 ko"**
2. ⚠️ **"Exigences de Play Console : Violation des exigences de Play Console"**

---

## ✅ CORRECTIONS APPLIQUÉES

### 1. Support des Pages Mémoire de 16 KB

**Aucune modification nécessaire** : Flutter 3.24+ et les plugins récents supportent automatiquement les 16 KB pages.

**Vérifications** :
- ✅ Flutter 3.24+ (recommandé)
- ✅ Plugins à jour (`flutter pub upgrade`)
- ✅ NDK version récente (déjà configuré dans `build.gradle.kts`)

---

## 🔨 ÉTAPE 1 : Vérifier/Mettre à Jour Flutter

```bash
flutter --version
```

**Si votre version est < 3.24.0** :

```bash
flutter upgrade
flutter pub upgrade
```

**Durée estimée** : 5-15 minutes

---

## 🔨 ÉTAPE 2 : Rebuild le Bundle

```bash
cd D:\aya
flutter clean
flutter build appbundle --release
```

**Durée estimée** : 5-10 minutes

**Fichier généré** : `build/app/outputs/bundle/release/app-release.aab`

---

## 📤 ÉTAPE 3 : Téléverser sur Google Play Console

1. **Google Play Console** → Votre application **"monuniversaya"**
2. **Tester et publier** → **Tests fermés - Alpha**
3. **Créer une nouvelle version**
4. **Téléverser** le fichier `app-release.aab`
5. **Notes de version** :
   ```
   Corrections de conformité Google Play :
   - Support des pages mémoire de 16 KB (exigence nov. 2025)
   - Retrait de la permission ACCESS_BACKGROUND_LOCATION non utilisée
   - Correction des problèmes de conformité
   - Informations de connexion complétées
   ```

**Durée estimée** : 5 minutes

---

## 🔐 ÉTAPE 4 : Fournir les Informations de Connexion (CRITIQUE)

1. **Google Play Console** → **Tester et publier** → **Tests fermés - Alpha**
2. **Gérer les tests** → **Configuration**
3. **Informations de connexion** → **Modifier**

### Informations à Fournir :

**Type de compte** : Compte de test

**Email** : [Votre email de test]
**Mot de passe** : [Votre mot de passe]

**Instructions** (COPIER-COLLER) :
```
INSTRUCTIONS POUR L'EXAMEN DE L'APPLICATION :

1. CONNEXION :
   - Email : [Votre email de test]
   - Mot de passe : [Votre mot de passe]
   - Ou créez un nouveau compte via l'écran d'inscription

2. FONCTIONNALITÉS PRINCIPALES À TESTER :
   - Scanner des QR codes (bouton QR en bas de l'écran d'accueil)
   - Jouer aux jeux (Roue de la Chance, Scratch & Win)
   - Consulter les vendeurs à proximité (nécessite la permission de localisation)
   - Échanger des points contre des récompenses
   - Consulter l'historique des échanges

3. PERMISSIONS :
   - Localisation : Demandée lors de l'inscription et pour trouver les vendeurs (premier plan uniquement)
   - Appels téléphoniques : Pour appeler les vendeurs depuis l'app

4. NOTES IMPORTANTES :
   - L'application est un programme de fidélité pour les produits AYA
   - Les points sont gagnés en scannant des QR codes sur les produits
   - Les points peuvent être échangés contre des récompenses chez les vendeurs partenaires
   - La localisation est utilisée uniquement en premier plan (pas en arrière-plan)
   - Toutes les fonctionnalités sont accessibles avec le compte de test fourni
```

**Durée estimée** : 10 minutes

---

## 🗑️ ÉTAPE 5 : Vérifier les Déclarations de Permissions

1. **Google Play Console** → **Politique de l'application**
2. **Données de l'application**
3. **Autorisations et API ayant accès aux informations sensibles**
4. **Vérifier** :
   - ❌ Aucune déclaration de "Localisation en arrière-plan" ne doit être présente
   - ✅ Seulement "Localisation en premier plan" (si nécessaire)

**Si "Localisation en arrière-plan" est déclarée** :
- **Retirer** la déclaration complètement

**Durée estimée** : 5 minutes

---

## ✅ Checklist Finale

Avant de soumettre :

- [ ] ✅ Flutter vérifié/mis à jour (version 3.24+ recommandée)
- [ ] ✅ Configuration 16 KB pages ajoutée dans `gradle.properties`
- [ ] ✅ Bundle Android rebuild (`flutter clean && flutter build appbundle --release`)
- [ ] ✅ Bundle téléversé sur Google Play Console
- [ ] ✅ **Informations de connexion complètes fournies** (CRITIQUE)
- [ ] ✅ Déclarations de permissions vérifiées (pas de localisation en arrière-plan)
- [ ] ✅ Notes de version remplies
- [ ] ✅ Application testée localement avec le nouveau build

---

## ⏱️ Délais Totaux

- **Actions techniques** : 20-40 minutes
- **Révision Google Play** : 1-3 jours ouvrables

---

## 🎯 Résultat Attendu

Après ces corrections :

1. ✅ **Support 16 KB pages** : Configuration ajoutée, Flutter gère automatiquement
2. ✅ **Violation Play Console** : Résolu avec informations de connexion complètes
3. ✅ **ACCESS_BACKGROUND_LOCATION** : Déjà résolu précédemment

**Votre application devrait être approuvée dans 1-3 jours ouvrables.**

---

## 🆘 Si Problèmes Persistants

### Pour le Support 16 KB Pages :

1. Vérifiez que Flutter est à jour (`flutter upgrade`)
2. Vérifiez que tous les plugins sont à jour (`flutter pub upgrade`)
3. Contactez le support Google Play si le problème persiste

### Pour la Violation Play Console :

1. **Vérifiez que les informations de connexion sont complètes et fonctionnelles**
2. Testez vous-même avec les identifiants fournis
3. Vérifiez que toutes les déclarations de permissions sont correctes
4. Contactez le support Google Play avec les détails

---

## 📞 Support

Pour plus de détails, consultez :
- `RESOLUTION_NOUVEAUX_PROBLEMES.md` - Guide détaillé
- `RESOLUTION_PROBLEMES_GOOGLE_PLAY.md` - Problèmes précédents
- `GUIDE_ACTION_RAPIDE.md` - Guide d'action précédent

