# 🌐 Implémentation du Deep Linking et Onboarding

## 📋 Vue d'ensemble

Cette implémentation gère les deux scénarios d'onboarding et de scan QR code :

### ✅ Scenario 1.1: Nouvel utilisateur scannant un QR code
- **Action** : Un nouvel utilisateur scanne un QR code sur une bouteille
- **Réponse** : Redirection automatique vers l'App Store/Google Play Store
- **Logique** : Le QR code contient une URL web qui détecte la plateforme et redirige

### ✅ Scenario 1.2: Utilisateur existant scannant un QR code
- **Action** : Un utilisateur ayant l'app installée scanne un QR code
- **Réponse** : L'app s'ouvre directement et redirige vers login/signup si nécessaire
- **Logique** : Le système d'exploitation reconnaît l'URL et ouvre l'application

## 🏗️ Architecture

### 1. **QR Codes générés**
```
https://aya-plus.orapide.shop/scan?code=ABC123
```

### 2. **Landing Page Web** (`landing_page/index.html`)
- Détecte la plateforme (iOS/Android)
- Essaie d'ouvrir l'app si elle est installée
- Redirige vers le store approprié si l'app n'est pas installée

### 3. **Deep Links de l'app**
```
aya-huile-app://qr?code=ABC123
```

### 4. **App Links Universels**
- **Android** : `https://aya-plus.orapide.shop/scan*`
- **iOS** : `applinks:aya-plus.orapide.shop`

## 📁 Fichiers modifiés/créés

### **Services Flutter**
- `lib/services/deep_link_service.dart` - Gestion des deep links
- `lib/services/qr_code_service.dart` - Génération et validation des QR codes

### **Configuration Android**
- `android/app/src/main/AndroidManifest.xml` - Intent filters pour App Links

### **Configuration iOS**
- `ios/Runner/Info.plist` - URL schemes et Associated Domains

### **Landing Page Web**
- `landing_page/index.html` - Page de redirection
- `landing_page/.well-known/apple-app-site-association` - Configuration iOS
- `landing_page/.well-known/assetlinks.json` - Configuration Android

## 🚀 Déploiement

### 1. **Héberger la landing page**
```bash
# Déployer sur votre serveur Hostinger
# Utilisez le gestionnaire de fichiers Hostinger ou FTP
# Déployez le contenu du dossier landing_page/ vers votre domaine
```

### 2. **Configurer les certificats**
- **iOS** : Remplacer `TEAMID` dans `apple-app-site-association`
- **Android** : Remplacer `SHA256_FINGERPRINT_HERE` dans `assetlinks.json`

### 3. **Tester les App Links**
```bash
# Android
adb shell am start -W -a android.intent.action.VIEW -d "https://aya-plus.orapide.shop/scan?code=TEST123" com.example.aya

# iOS (Simulator)
xcrun simctl openurl booted "https://aya-plus.orapide.shop/scan?code=TEST123"
```

## 🔧 Utilisation

### **Générer un QR code**
```dart
import 'package:aya/services/qr_code_service.dart';

// Générer une URL pour QR code
String qrUrl = QRCodeService.generateQRCodeUrl('ABC123');
// Résultat: https://aya-plus.orapide.shop/scan?code=ABC123

// Générer un code unique
String uniqueCode = QRCodeService.generateUniqueQRCode();
// Résultat: AYA_1703123456789_123456
```

### **Traiter un deep link**
```dart
import 'package:aya/services/deep_link_service.dart';

// Dans votre main.dart ou widget principal
DeepLinkService.handleDeepLink(uri, context);
```

## 🧪 Tests

### **Test Scenario 1.1 (Nouvel utilisateur)**
1. Désinstaller l'app
2. Scanner le QR code
3. Vérifier la redirection vers le store

### **Test Scenario 1.2 (Utilisateur existant)**
1. Avoir l'app installée
2. Scanner le QR code
3. Vérifier l'ouverture directe de l'app

## 📱 URLs de test

```
# QR Code de test
https://aya-plus.orapide.shop/scan?code=TEST123

# Deep link direct
aya-huile-app://qr?code=TEST123
```

## 🔍 Dépannage

### **L'app ne s'ouvre pas**
- Vérifier les certificats dans les fichiers `.well-known`
- Vérifier la configuration des intent filters
- Tester avec `adb shell dumpsys package domain-preferred-apps`

### **Redirection vers le store ne fonctionne pas**
- Vérifier que la landing page est accessible
- Vérifier la détection de plateforme
- Tester manuellement les URLs des stores

## 📚 Ressources

- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
- [Flutter Deep Linking](https://docs.flutter.dev/development/ui/navigation/deep-linking)
