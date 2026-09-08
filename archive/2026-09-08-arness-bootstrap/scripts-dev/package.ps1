<#
.SYNOPSIS
  Prépare une version locale distribuable d'Arness (archive npm .tgz). Ne publie jamais.
.DESCRIPTION
  1. Exécute la vérification complète (scripts/dev/check.ps1 -Profile full) ; s'arrête si elle n'est pas RÉUSSIE
     (sauf -SkipChecks, déconseillé : la version est alors marquée NON validée).
  2. Recompile dist/ à neuf.
  3. Produit dist-packages/<nom>-<version>.tgz via `npm pack`, son empreinte SHA-256 et une notice INSTALL-<version>.md
     (installation, vérification, retour arrière).
  Ce script n'exécute ni npm publish, ni git push, ni signature, ni déploiement.
  Codes de sortie : 0 paquet produit · 1 vérification ou compilation échouée · 2 vérification non exécutée.
#>
[CmdletBinding()]
param([switch]$SkipChecks)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
$root = Get-ProjectRoot
Push-Location $root
try {
    $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
    $git = Get-GitState
    Write-Host "== Arness : préparation du paquet $($pkg.name) $($pkg.version) ==" -ForegroundColor Cyan
    if ($git.dirty) { Write-Host "Attention : modifications non validées dans Git. Le paquet ne correspondra pas à un commit précis." -ForegroundColor Yellow }

    $checkState = "RÉUSSIE (voir reports/dev/check-latest.json)"
    if ($SkipChecks) {
        $checkState = "IGNORÉE (-SkipChecks) : version NON validée"
        Write-Host "Vérification complète IGNORÉE (-SkipChecks) : la version ne peut pas être déclarée validée." -ForegroundColor Yellow
    } else {
        & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\check.ps1" -Profile full
        if ($LASTEXITCODE -ne 0) { Write-Host "Vérification complète non concluante (code $LASTEXITCODE) : paquet non produit." -ForegroundColor Red; exit $LASTEXITCODE }
    }

    if (Test-Path "dist") { Remove-Item "dist" -Recurse -Force -Confirm:$false }
    & cmd /c "npm run build"
    if ($LASTEXITCODE -ne 0) { Write-Host "Compilation échouée." -ForegroundColor Red; exit 1 }

    $outDir = Join-Path $root "dist-packages"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    $packOut = & cmd /c "npm pack --pack-destination `"$outDir`" 2>&1"
    if ($LASTEXITCODE -ne 0) { Write-Host ($packOut -join "`n") -ForegroundColor Red; exit 1 }
    $tgzName = (($packOut | Where-Object { $_ -like "*.tgz" } | Select-Object -Last 1) -as [string])
    if (-not $tgzName) { Write-Host "npm pack n'a pas indiqué de fichier .tgz." -ForegroundColor Red; exit 1 }
    $tgz = Join-Path $outDir $tgzName.Trim()
    if (-not (Test-Path $tgz)) { Write-Host "Archive introuvable après npm pack : $tgz" -ForegroundColor Red; exit 1 }
    $hash = (Get-FileHash $tgz -Algorithm SHA256).Hash
    Set-Content -Path "$tgz.sha256" -Value "$hash  $(Split-Path $tgz -Leaf)" -Encoding ascii

    $notes = New-Object System.Collections.Generic.List[string]
    $notes.Add("# Installation d'Arness $($pkg.version)")
    $notes.Add("")
    $notes.Add("Paquet : $(Split-Path $tgz -Leaf)")
    $notes.Add("SHA-256 : $hash")
    $notes.Add("Construit le $((Get-Date).ToString('s')) depuis la branche $($git.branch), commit $($git.commit) (modifications non validées : $($git.dirty)).")
    $notes.Add("Vérification complète avant construction : $checkState")
    $notes.Add("")
    $notes.Add("## Prérequis")
    $notes.Add("- Node.js >= 24")
    $notes.Add("")
    $notes.Add("## Installer")
    $notes.Add('```powershell')
    $notes.Add("npm install -g `"$tgz`"")
    $notes.Add("arness --version   # doit afficher $($pkg.version)")
    $notes.Add('```')
    $notes.Add("")
    $notes.Add("## Vérifier l'intégrité")
    $notes.Add('```powershell')
    $notes.Add("Get-FileHash `"$tgz`" -Algorithm SHA256   # comparer avec le fichier .sha256")
    $notes.Add('```')
    $notes.Add("")
    $notes.Add("## Retour arrière")
    $notes.Add('```powershell')
    $notes.Add("npm uninstall -g $($pkg.name)")
    $notes.Add("# ou réinstaller l'archive de la version précédente conservée dans dist-packages/")
    $notes.Add('```')
    $notes.Add("")
    $notes.Add("Une compilation et un paquet réussis ne suffisent pas à déclarer la version validée : consulter le rapport de vérification et les limites notées dans docs/development/STATUS.md.")
    ($notes -join "`n") | Set-Content -Path (Join-Path $outDir "INSTALL-$($pkg.version).md") -Encoding utf8

    Write-Host ""
    Write-Host "Paquet produit : $tgz" -ForegroundColor Green
    Write-Host "SHA-256        : $hash"
    Write-Host "Notice         : $(Join-Path $outDir "INSTALL-$($pkg.version).md")"
    exit 0
} finally { Pop-Location }
