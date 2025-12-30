# 🔐 Signer le Bundle Android pour Google Play

## ❌ Problème Actuel

**Erreur** : "Tous les app bundles importés doivent être signés"

Votre bundle `app-release.aab` n'est pas signé avec votre clé de release.

## ✅ Solution

### Étape 1 : Vérifier la Configuration

Votre fichier `key.properties` existe et contient :
```
storePassword=ANAKOisrael1@
keyPassword=ANAKOisrael1@
keyAlias=upload
storeFile=app/upload-keystore.jks
```

**⚠️ Problème** : Le chemin `storeFile=app/upload-keystore.jks` est incorrect.

### Étape 2 : Corriger le Chemin dans key.properties

Le fichier `build.gradle.kts` résout les chemins depuis `android/app/`, donc le chemin doit être relatif à ce répertoire.

**Option A** : Chemin relatif (recommandé)
```properties
storeFile=upload-keystore.jks
```

**Option B** : Chemin absolu
```properties
storeFile=D:\\aya\\android\\app\\upload-keystore.jks
```

### Étape 3 : Rebuild le Bundle Signé

Après avoir corrigé `key.properties`, reconstruisez le bundle :

```powershell
cd D:\aya
flutter clean
flutter build appbundle --release
```

Le bundle sera automatiquement signé avec votre keystore.

### Étape 4 : Vérifier la Signature

Pour vérifier que le bundle est signé, utilisez `jarsigner` (inclus avec le JDK) :

```powershell
# Trouver le JDK
$jdkPath = "C:\Program Files\Android\Android Studio2\jbr\bin"
& "$jdkPath\jarsigner.exe" -verify -verbose -certs "D:\aya\build\app\outputs\bundle\release\app-release.aab"
```

Si le bundle est signé, vous verrez :
```
jar verified.
```

## 🔍 Diagnostic

### Vérifier que le Keystore Existe

```powershell
Test-Path "D:\aya\android\app\upload-keystore.jks"
```

### Vérifier le Contenu de key.properties

Le fichier doit être dans `android/app/key.properties` et contenir :
```properties
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=upload
storeFile=upload-keystore.jks
```

## 📝 Notes Importantes

1. **Gardez votre keystore en sécurité** : Si vous le perdez, vous ne pourrez plus mettre à jour votre app sur Google Play
2. **Sauvegardez** : Faites une copie de `upload-keystore.jks` et de `key.properties` dans un endroit sûr
3. **Ne commitez jamais** : Ajoutez `key.properties` et `*.jks` à `.gitignore`

## 🚀 Après la Correction

Une fois le bundle signé correctement :
1. Téléversez le nouveau bundle sur Google Play Console
2. L'erreur "Tous les app bundles importés doivent être signés" disparaîtra
3. Vous pourrez continuer avec la publication

