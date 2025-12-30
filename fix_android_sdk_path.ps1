# Script pour déplacer le SDK Android vers un chemin sans espaces
# Exécuter en tant qu'administrateur si nécessaire

Write-Host "🔧 Correction du chemin Android SDK" -ForegroundColor Cyan
Write-Host ""

$oldPath = "$env:LOCALAPPDATA\Android\Sdk"
$newPath = "C:\Android\Sdk"

# Vérifier si l'ancien chemin existe
if (-not (Test-Path $oldPath)) {
    Write-Host "❌ Le SDK Android n'a pas été trouvé à : $oldPath" -ForegroundColor Red
    Write-Host "Vérifiez votre installation Android SDK." -ForegroundColor Yellow
    exit 1
}

# Vérifier si le nouveau chemin existe déjà
if (Test-Path $newPath) {
    Write-Host "⚠️  Le dossier $newPath existe déjà." -ForegroundColor Yellow
    $response = Read-Host "Voulez-vous continuer et écraser ? (O/N)"
    if ($response -ne "O" -and $response -ne "o") {
        Write-Host "Opération annulée." -ForegroundColor Yellow
        exit 0
    }
} else {
    # Créer le nouveau dossier
    Write-Host "📁 Création du dossier : $newPath" -ForegroundColor Green
    New-Item -ItemType Directory -Path $newPath -Force | Out-Null
}

# Déplacer le contenu
Write-Host "📦 Déplacement du SDK Android..." -ForegroundColor Green
Write-Host "   De : $oldPath" -ForegroundColor Gray
Write-Host "   Vers : $newPath" -ForegroundColor Gray
Write-Host ""

try {
    # Copier d'abord (plus sûr)
    Write-Host "⏳ Copie en cours (cela peut prendre plusieurs minutes)..." -ForegroundColor Yellow
    Copy-Item -Path "$oldPath\*" -Destination $newPath -Recurse -Force
    
    # Vérifier que la copie a réussi
    if (Test-Path "$newPath\platform-tools") {
        Write-Host "✅ Copie réussie !" -ForegroundColor Green
        
        # Supprimer l'ancien dossier (optionnel)
        Write-Host ""
        $deleteOld = Read-Host "Supprimer l'ancien SDK ? (O/N)"
        if ($deleteOld -eq "O" -or $deleteOld -eq "o") {
            Remove-Item -Path $oldPath -Recurse -Force
            Write-Host "✅ Ancien SDK supprimé." -ForegroundColor Green
        }
    } else {
        Write-Host "❌ Erreur lors de la copie." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Erreur : $_" -ForegroundColor Red
    exit 1
}

# Instructions pour mettre à jour les variables d'environnement
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "📝 PROCHAINES ÉTAPES MANUELLES" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Mettre à jour la variable d'environnement ANDROID_HOME :" -ForegroundColor White
Write-Host "   - Ouvrir 'Variables d'environnement' dans Windows" -ForegroundColor Gray
Write-Host "   - Modifier ANDROID_HOME = $newPath" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Mettre à jour PATH pour inclure :" -ForegroundColor White
Write-Host "   - $newPath\platform-tools" -ForegroundColor Gray
Write-Host "   - $newPath\tools" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Redémarrer votre terminal et exécuter :" -ForegroundColor White
Write-Host "   flutter doctor -v" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Reconstruire l'application :" -ForegroundColor White
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter build appbundle --release" -ForegroundColor Gray
Write-Host ""

