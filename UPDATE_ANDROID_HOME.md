# 🔧 Mettre à Jour la Variable d'Environnement ANDROID_HOME

## ❌ Problème Actuel

Flutter cherche le SDK à l'ancien emplacement :
```
✗ ANDROID_HOME = C:\Users\HP OMEN 16\AppData\Local\Android\Sdk
  but Android SDK not found at this location.
```

## ✅ Solution : Mettre à Jour ANDROID_HOME

### Méthode 1 : Via l'Interface Windows (RECOMMANDÉ)

1. **Ouvrir les Variables d'Environnement** :
   - Appuyer sur `Win + R`
   - Taper `sysdm.cpl` et appuyer sur Entrée
   - Aller dans l'onglet **"Avancé"**
   - Cliquer sur **"Variables d'environnement"**

2. **Modifier ANDROID_HOME** :
   - Dans "Variables système" ou "Variables utilisateur", trouver `ANDROID_HOME`
   - Cliquer sur **"Modifier"**
   - Changer la valeur de :
     ```
     C:\Users\HP OMEN 16\AppData\Local\Android\Sdk
     ```
     vers :
     ```
     C:\Android\Sdk
     ```
   - Cliquer sur **"OK"**

3. **Mettre à Jour PATH** :
   - Trouver la variable `PATH` dans la même liste
   - Cliquer sur **"Modifier"**
   - Chercher les entrées contenant l'ancien chemin :
     - `C:\Users\HP OMEN 16\AppData\Local\Android\Sdk\platform-tools`
     - `C:\Users\HP OMEN 16\AppData\Local\Android\Sdk\tools`
   - Les remplacer par :
     - `C:\Android\Sdk\platform-tools`
     - `C:\Android\Sdk\tools`
   - Cliquer sur **"OK"** partout

4. **Redémarrer le terminal** (fermer et rouvrir PowerShell)

### Méthode 2 : Via PowerShell (Temporaire - Session Actuelle)

```powershell
# Pour la session actuelle seulement
$env:ANDROID_HOME = "C:\Android\Sdk"
$env:PATH = "$env:PATH;C:\Android\Sdk\platform-tools;C:\Android\Sdk\tools"
```

⚠️ **Note** : Cette méthode ne persiste qu'à la session actuelle. Utilisez la Méthode 1 pour une solution permanente.

### Méthode 3 : Via PowerShell (Permanent - Utilisateur)

```powershell
# Mettre à jour ANDROID_HOME pour l'utilisateur actuel
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Android\Sdk", "User")

# Ajouter au PATH utilisateur
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$newPaths = @(
    "C:\Android\Sdk\platform-tools",
    "C:\Android\Sdk\tools"
)

foreach ($newPath in $newPaths) {
    if ($currentPath -notlike "*$newPath*") {
        $currentPath = "$currentPath;$newPath"
    }
}

[Environment]::SetEnvironmentVariable("PATH", $currentPath, "User")
```

**Redémarrer le terminal après cette commande.**

## ✅ Vérification

Après avoir mis à jour les variables, **fermer et rouvrir PowerShell**, puis :

```powershell
# Vérifier ANDROID_HOME
echo $env:ANDROID_HOME
# Devrait afficher : C:\Android\Sdk

# Vérifier avec Flutter
flutter doctor -v
```

## 🔍 Si le SDK n'est pas à C:\Android\Sdk

Si vous avez déplacé le SDK ailleurs, remplacez `C:\Android\Sdk` par votre chemin réel dans toutes les instructions ci-dessus.

Pour trouver où se trouve votre SDK :
```powershell
Get-ChildItem -Path "C:\" -Recurse -Directory -Filter "Sdk" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*Android*" } | Select-Object FullName
```

