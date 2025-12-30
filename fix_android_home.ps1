# Script pour forcer la mise à jour de ANDROID_HOME
# Exécuter dans PowerShell

Write-Host "🔧 Mise à jour de ANDROID_HOME" -ForegroundColor Cyan
Write-Host ""

$newSdkPath = "C:\Android\Sdk"

# Vérifier que le SDK existe
if (-not (Test-Path $newSdkPath)) {
    Write-Host "❌ Le SDK Android n'existe pas à : $newSdkPath" -ForegroundColor Red
    Write-Host "Vérifiez que vous avez bien déplacé le SDK." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ SDK trouvé à : $newSdkPath" -ForegroundColor Green
Write-Host ""

# Mettre à jour pour l'utilisateur
Write-Host "📝 Mise à jour de ANDROID_HOME (utilisateur)..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $newSdkPath, "User")
Write-Host "OK - ANDROID_HOME mis a jour pour l'utilisateur" -ForegroundColor Green

# Mettre à jour pour le système (nécessite les droits admin)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "📝 Mise à jour de ANDROID_HOME (système)..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("ANDROID_HOME", $newSdkPath, "Machine")
    Write-Host "✅ ANDROID_HOME mis à jour pour le système" -ForegroundColor Green
} else {
    Write-Host "⚠️  Droits administrateur nécessaires pour mettre à jour la variable système" -ForegroundColor Yellow
    Write-Host "   La variable utilisateur a été mise à jour." -ForegroundColor Gray
}

# Mettre à jour PATH
Write-Host ""
Write-Host "📝 Mise à jour de PATH..." -ForegroundColor Yellow

$pathUser = [Environment]::GetEnvironmentVariable("PATH", "User")
$newPaths = @(
    "$newSdkPath\platform-tools",
    "$newSdkPath\tools",
    "$newSdkPath\cmdline-tools\latest\bin"
)

$updated = $false
foreach ($newPath in $newPaths) {
    if (Test-Path $newPath) {
        if ($pathUser -notlike "*$newPath*") {
            $pathUser = "$pathUser;$newPath"
            $updated = $true
            Write-Host "   ✅ Ajouté : $newPath" -ForegroundColor Green
        } else {
            Write-Host "   ℹ️  Déjà présent : $newPath" -ForegroundColor Gray
        }
    }
}

if ($updated) {
    [Environment]::SetEnvironmentVariable("PATH", $pathUser, "User")
    Write-Host "✅ PATH mis à jour" -ForegroundColor Green
}

# Mettre à jour la session actuelle
$env:ANDROID_HOME = $newSdkPath
$env:PATH = "$env:PATH;$newSdkPath\platform-tools;$newSdkPath\tools"

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "✅ MISE À JOUR TERMINÉE" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  IMPORTANT :" -ForegroundColor Yellow
Write-Host "   1. FERMEZ et ROUVREZ votre terminal PowerShell" -ForegroundColor White
Write-Host "   2. Exécutez : flutter doctor -v" -ForegroundColor White
Write-Host "   3. Si le problème persiste, redémarrez votre ordinateur" -ForegroundColor White
Write-Host ""

