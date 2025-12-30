# 🔧 Correction du Chemin Android SDK avec Espaces

## ❌ Problème Identifié

```
✗ Android SDK location currently contains spaces, which is not supported by the Android SDK 
   as it causes problems with NDK tools.
```

**Chemin actuel** : `C:\Users\HP OMEN 16\AppData\Local\Android\Sdk`  
**Problème** : L'espace dans "HP OMEN 16" cause des erreurs avec les outils NDK

## ✅ Solution : Déplacer le SDK Android

### Option 1 : Déplacer vers C:\Android\Sdk (RECOMMANDÉ)

1. **Créer le nouveau dossier** :
   ```powershell
   New-Item -ItemType Directory -Path "C:\Android\Sdk" -Force
   ```

2. **Déplacer le contenu du SDK** :
   ```powershell
   Move-Item -Path "$env:LOCALAPPDATA\Android\Sdk\*" -Destination "C:\Android\Sdk\" -Force
   ```

3. **Mettre à jour la variable d'environnement ANDROID_HOME** :
   - Ouvrir "Variables d'environnement" dans Windows
   - Modifier `ANDROID_HOME` : `C:\Android\Sdk`
   - Modifier `PATH` : Remplacer l'ancien chemin par `C:\Android\Sdk\platform-tools` et `C:\Android\Sdk\tools`

4. **Redémarrer le terminal** et vérifier :
   ```powershell
   flutter doctor -v
   ```

### Option 2 : Créer un lien symbolique (Alternative)

Si vous ne pouvez pas déplacer le SDK :

```powershell
# Créer un lien symbolique sans espaces
New-Item -ItemType SymbolicLink -Path "C:\Android\Sdk" -Target "$env:LOCALAPPDATA\Android\Sdk"
```

Puis mettre à jour `ANDROID_HOME` vers `C:\Android\Sdk`

### Option 3 : Réinstaller le SDK dans un nouveau chemin

1. Télécharger Android Studio
2. Lors de l'installation, spécifier un chemin sans espaces : `C:\Android\Sdk`
3. Mettre à jour les variables d'environnement

## 🔄 Après le Déplacement

1. **Vérifier la configuration** :
   ```powershell
   flutter doctor -v
   ```

2. **Nettoyer et reconstruire** :
   ```powershell
   cd D:\aya
   flutter clean
   flutter pub get
   flutter build appbundle --release
   ```

## 📝 Variables d'Environnement à Mettre à Jour

- `ANDROID_HOME` = `C:\Android\Sdk`
- `PATH` doit contenir :
  - `C:\Android\Sdk\platform-tools`
  - `C:\Android\Sdk\tools`
  - `C:\Android\Sdk\cmdline-tools\latest\bin` (si disponible)

## ⚠️ Note

Après le déplacement, vous devrez peut-être :
- Redémarrer Android Studio
- Redémarrer votre IDE
- Redémarrer votre terminal/PowerShell

