# ⚡ Guide d'Action Rapide - Correction Google Play

## 🎯 Objectif

Corriger tous les problèmes Google Play pour que votre application soit approuvée rapidement.

---

## ✅ ÉTAPE 1 : Permission Retirée (DÉJÀ FAIT)

La permission `ACCESS_BACKGROUND_LOCATION` a été retirée du manifeste.

**Fichier modifié** : `android/app/src/main/AndroidManifest.xml`

---

## 🔨 ÉTAPE 2 : Rebuild le Bundle (À FAIRE MAINTENANT)

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
   Correction des permissions Android :
   - Retrait de la permission ACCESS_BACKGROUND_LOCATION non utilisée
   - L'application utilise uniquement la localisation en premier plan
   - Correction des problèmes de conformité Google Play
   ```

**Durée estimée** : 5 minutes

---

## 🔐 ÉTAPE 4 : Fournir les Informations de Connexion

1. **Google Play Console** → **Tester et publier** → **Tests fermés - Alpha**
2. **Gérer les tests** → **Configuration**
3. **Informations de connexion** → **Modifier**

### Informations à Fournir :

**Type de compte** : Compte de test

**Email** : [Votre email de test]
**Mot de passe** : [Votre mot de passe]

**Instructions** :
```
INSTRUCTIONS POUR L'EXAMEN DE L'APPLICATION :

1. CONNEXION :
   - Email : [Votre email de test]
   - Mot de passe : [Votre mot de passe]

2. FONCTIONNALITÉS PRINCIPALES :
   - Scanner des QR codes (section QR dans l'app)
   - Jouer aux jeux (Roue de la Chance, Scratch & Win)
   - Consulter les vendeurs à proximité (nécessite la permission de localisation)
   - Échanger des points contre des récompenses

3. PERMISSIONS :
   - Localisation : Demandée lors de l'inscription et pour trouver les vendeurs (premier plan uniquement)
   - Appels téléphoniques : Pour appeler les vendeurs depuis l'app

4. NOTES IMPORTANTES :
   - L'application est un programme de fidélité pour les produits AYA
   - Les points sont gagnés en scannant des QR codes
   - Les points peuvent être échangés contre des récompenses
   - La localisation est utilisée uniquement en premier plan (pas en arrière-plan)
```

**Durée estimée** : 10 minutes

---

## 🗑️ ÉTAPE 5 : Retirer la Déclaration de Localisation en Arrière-Plan

1. **Google Play Console** → **Politique de l'application**
2. **Données de l'application**
3. **Autorisations et API ayant accès aux informations sensibles**
4. **Chercher "Localisation en arrière-plan"** ou **"Background location"**
5. **Si déclaré** → **Retirer la déclaration** ou **Modifier** pour indiquer que vous n'utilisez plus cette permission

**Durée estimée** : 5 minutes

---

## 📹 ÉTAPE 6 : Vidéo (Si Nécessaire)

**Si Google Play exige toujours une vidéo** après avoir retiré la déclaration :

### Option A : Retirer la Déclaration (Recommandé)

Si vous retirez complètement la déclaration de localisation en arrière-plan, la vidéo ne sera plus nécessaire.

### Option B : Créer une Vidéo Simple (Si Nécessaire)

**Contenu de la vidéo** (30-60 secondes) :

1. Ouvrir l'application
2. Aller à la section "Vendeurs" ou "Carte"
3. Montrer la demande de permission de localisation (premier plan)
4. Accepter la permission
5. Montrer la carte avec les vendeurs à proximité

**Format** : MP4, 720p minimum

**Durée estimée** : 15-30 minutes (si nécessaire)

---

## ✅ Checklist Finale

Avant de soumettre :

- [ ] ✅ Bundle Android rebuild (`flutter build appbundle --release`)
- [ ] ✅ Bundle téléversé sur Google Play Console
- [ ] ✅ Informations de connexion fournies (email, mot de passe, instructions)
- [ ] ✅ Déclaration de localisation en arrière-plan retirée (si présente)
- [ ] ✅ Notes de version remplies
- [ ] ✅ Application testée localement avec le nouveau build

---

## ⏱️ Délais Totaux

- **Actions techniques** : 20-30 minutes
- **Révision Google Play** : 1-3 jours ouvrables

---

## 🎯 Résultat Attendu

Après ces corrections, tous les problèmes devraient être résolus :

1. ✅ **ACCESS_BACKGROUND_LOCATION** : Permission retirée
2. ✅ **Divulgation bien visible** : Plus nécessaire
3. ✅ **Vidéo** : Plus nécessaire si déclaration retirée
4. ✅ **Informations de connexion** : Fournies

**Votre application devrait être approuvée dans 1-3 jours ouvrables.**

---

## 🆘 Si Problèmes Persistants

1. Vérifiez que le nouveau bundle ne contient plus la permission
2. Attendez 24-48h pour que Google Play mette à jour son analyse
3. Contactez le support Google Play si nécessaire

---

## 📞 Support

Pour plus de détails, consultez : `RESOLUTION_PROBLEMES_GOOGLE_PLAY.md`

