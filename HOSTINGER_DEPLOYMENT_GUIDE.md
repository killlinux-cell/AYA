# 🚀 Guide de déploiement sur Hostinger

## 📋 Prérequis

- Compte Hostinger avec le domaine `aya-plus.orapide.shop`
- Accès au gestionnaire de fichiers Hostinger
- Application Flutter compilée

## 🌐 Déploiement de la landing page

### 1. **Accéder au gestionnaire de fichiers Hostinger**

1. Connectez-vous à votre compte Hostinger
2. Allez dans **"Gestionnaire de fichiers"** ou **"File Manager"**
3. Naviguez vers le dossier `public_html` de votre domaine

### 2. **Télécharger les fichiers de la landing page**

1. Téléchargez le contenu du dossier `landing_page/` depuis votre projet local
2. Uploadez les fichiers suivants dans `public_html/` :
   ```
   public_html/
   ├── index.html
   └── .well-known/
       ├── apple-app-site-association
       └── assetlinks.json
   ```

### 3. **Vérifier la structure des fichiers**

Assurez-vous que la structure est correcte :
```
https://aya-plus.orapide.shop/
├── index.html (page principale)
└── .well-known/
    ├── apple-app-site-association (pour iOS)
    └── assetlinks.json (pour Android)
```

## 🔧 Configuration des App Links

### 1. **Pour iOS (apple-app-site-association)**

Le fichier `apple-app-site-association` doit être accessible à :
```
https://aya-plus.orapide.shop/.well-known/apple-app-site-association
```

**Important** : Remplacez `TEAMID` par votre vrai Team ID Apple :
```json
{
  "applinks": {
    "details": [
      {
        "appIDs": [
          "VOTRE_TEAM_ID.com.example.aya"
        ],
        "components": [
          {
            "/": "/scan*",
            "comment": "Matches any URL whose path starts with /scan"
          }
        ]
      }
    ]
  }
}
```

### 2. **Pour Android (assetlinks.json)**

Le fichier `assetlinks.json` doit être accessible à :
```
https://aya-plus.orapide.shop/.well-known/assetlinks.json
```

**Important** : Remplacez `SHA256_FINGERPRINT_HERE` par votre empreinte SHA256 :
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.aya",
      "sha256_cert_fingerprints": [
        "VOTRE_EMPREINTE_SHA256"
      ]
    }
  }
]
```

## 🧪 Tests de déploiement

### 1. **Tester la landing page**

Visitez : `https://aya-plus.orapide.shop/scan?code=TEST123`

Vous devriez voir :
- ✅ Page de téléchargement avec logo Aya+
- ✅ Boutons Google Play et App Store
- ✅ Détection automatique de la plateforme

### 2. **Tester les fichiers de configuration**

Vérifiez que ces URLs sont accessibles :
- ✅ `https://aya-plus.orapide.shop/.well-known/apple-app-site-association`
- ✅ `https://aya-plus.orapide.shop/.well-known/assetlinks.json`

### 3. **Tester les App Links**

#### Android :
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://aya-plus.orapide.shop/scan?code=TEST123" com.example.aya
```

#### iOS (Simulator) :
```bash
xcrun simctl openurl booted "https://aya-plus.orapide.shop/scan?code=TEST123"
```

## 🔍 Dépannage

### **Problème : Les fichiers .well-known ne sont pas accessibles**

**Solution** :
1. Vérifiez que le dossier `.well-known` est dans `public_html/`
2. Vérifiez les permissions des fichiers (644)
3. Vérifiez que les fichiers ne sont pas vides

### **Problème : La landing page ne se charge pas**

**Solution** :
1. Vérifiez que `index.html` est dans `public_html/`
2. Vérifiez les permissions du fichier (644)
3. Vérifiez les logs d'erreur dans Hostinger

### **Problème : Les App Links ne fonctionnent pas**

**Solution** :
1. Vérifiez que les certificats sont corrects
2. Attendez 24h pour la propagation des App Links
3. Testez avec des outils de validation :
   - [Apple App Site Association Validator](https://branch.io/resources/aasa-validator/)
   - [Android App Links Validator](https://developers.google.com/digital-asset-links/tools/generator)

## 📱 URLs de production

Une fois déployé, vos QR codes utiliseront :
```
https://aya-plus.orapide.shop/scan?code=VOTRE_CODE_QR
```

## 🎯 Prochaines étapes

1. **Déployer la landing page** sur Hostinger
2. **Configurer les certificats** iOS et Android
3. **Tester les deux scénarios** :
   - Nouvel utilisateur → Redirection vers stores
   - Utilisateur existant → Ouverture directe de l'app
4. **Générer des QR codes** avec les nouvelles URLs
5. **Déployer l'app** sur les stores avec la nouvelle configuration

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs d'erreur Hostinger
2. Testez les URLs manuellement
3. Vérifiez la configuration des App Links
4. Contactez le support Hostinger si nécessaire
