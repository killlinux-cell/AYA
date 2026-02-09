# 🔧 Correction ITMS-90683 : Clé NSLocationAlwaysAndWhenInUseUsageDescription Manquante

## ❌ Problème Identifié

**Erreur Apple :** ITMS-90683
**Message :** Missing purpose string in Info.plist - `NSLocationAlwaysAndWhenInUseUsageDescription` key required

**Cause :** L'app ou une de ses dépendances (SDK/bibliothèque) référence des APIs qui nécessitent cette description, même si l'app n'utilise pas activement la localisation en arrière-plan.

---

## ✅ Solution Appliquée

### Clé Ajoutée dans Info.plist

**Fichier :** `ios/Runner/Info.plist`

**Clé ajoutée :**
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Mon univers AYA utilise votre localisation pour trouver les points de vente AYA près de chez vous et afficher la carte interactive des vendeurs.</string>
```

### Explication

Cette clé est requise même si l'app n'utilise que `NSLocationWhenInUseUsageDescription`, car :
- Certains SDKs Flutter peuvent référencer cette API
- Apple exige cette description si elle est référencée dans le code
- C'est une exigence de sécurité et de confidentialité

---

## ✅ Checklist de Vérification

### Info.plist - Toutes les Clés Requises

- [x] **NSCameraUsageDescription** ✅ Présente
- [x] **NSLocationWhenInUseUsageDescription** ✅ Présente
- [x] **NSLocationAlwaysAndWhenInUseUsageDescription** ✅ **AJOUTÉE**
- [x] **NSPhotoLibraryUsageDescription** ✅ Présente
- [x] **NSPhotoLibraryAddUsageDescription** ✅ Présente

---

## 🚀 Actions Suivantes

### 1. Rebuild l'App iOS

```bash
# Nettoyer
flutter clean

# Réinstaller les dépendances
flutter pub get

# Build iOS release
flutter build ios --release
```

### 2. Vérifier dans Xcode (Optionnel mais Recommandé)

1. Ouvrez `ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez le target "Runner"
3. Onglet "Info"
4. Vérifiez que "Privacy - Location Always and When In Use Usage Description" est présent avec la description

### 3. Archive et Upload

1. Dans Xcode : **Product** → **Archive**
2. Dans Organizer : **Distribute App** → **App Store Connect**
3. Upload la nouvelle build

### 4. Soumettre pour Examen

Dans App Store Connect :
- La nouvelle build devrait automatiquement passer la validation ITMS-90683
- Pas besoin de répondre à Apple pour cette erreur (c'est un avertissement)

---

## 📝 Notes Importantes

### Pourquoi Cette Clé est Nécessaire

1. **Exigence Apple** : Même si l'app n'utilise pas la localisation en arrière-plan, si le code ou une dépendance la référence, la clé est requise.

2. **SDKs Flutter** : Certains packages Flutter (comme `geolocator`, `google_maps_flutter`) peuvent référencer cette API.

3. **Sécurité** : Apple exige cette description pour protéger la vie privée des utilisateurs.

### Description Utilisée

La description est identique à `NSLocationWhenInUseUsageDescription` car :
- L'app n'utilise PAS la localisation en arrière-plan
- L'utilisation est uniquement lorsque l'app est active
- C'est une description cohérente avec l'utilisation réelle

### Si Vous Utilisez la Localisation en Arrière-Plan

**Actuellement :** Vous n'utilisez PAS la localisation en arrière-plan, donc la description actuelle est correcte.

**Si vous souhaitez l'utiliser plus tard :** Vous devrez modifier la description pour expliquer pourquoi vous avez besoin de la localisation même quand l'app est fermée.

---

## ✅ Vérification Finale

### Dans Info.plist, vous devriez avoir :

```xml
<!-- Localisation en utilisation active -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Mon univers AYA utilise votre localisation pour trouver les points de vente AYA près de chez vous et afficher la carte interactive des vendeurs.</string>

<!-- Localisation toujours et en utilisation (requis par Apple même si non utilisé) -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Mon univers AYA utilise votre localisation pour trouver les points de vente AYA près de chez vous et afficher la carte interactive des vendeurs.</string>
```

---

## 🎯 Résultat Attendu

Après avoir uploadé la nouvelle build :
- ✅ L'erreur ITMS-90683 ne devrait plus apparaître
- ✅ La validation App Store Connect devrait passer
- ✅ L'app peut être soumise pour examen

**Note :** Cette erreur était un **avertissement** (pas un rejet), donc l'app devrait déjà être soumise. Mais il est important de corriger pour éviter des problèmes futurs.

---

**Dernière mise à jour :** Janvier 2026
