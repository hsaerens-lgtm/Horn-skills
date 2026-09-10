<#
.SYNOPSIS
  Crée la mini application de démonstration des tests (unitaires Vitest + bout en bout Playwright) dans un dossier cible vide.
.DESCRIPTION
  Copie templates/testing-demo/ du plugin vers -TargetDir. Ne touche jamais un dossier non vide (sauf -Force, qui
  n'écrase que les fichiers du modèle). Avec -Install : `npm install` puis `npx playwright install chromium`
  (téléchargement d'un navigateur, réseau requis). Avec -Run : exécute les deux familles de tests et affiche les
  résultats ; un échec volontaire est attendu dans chaque famille tant que `npm run demo:clean` n'a pas été lancé.
  Codes de sortie : 0 · 1 installation ou exécution en erreur · 3 usage (dossier absent, non vide, ou dossier du plugin).
.EXAMPLE
  horn-testing-demo.ps1 -TargetDir C:\Temp\demo-tests -Install -Run
#>
[CmdletBinding()]
param(
    [string]$TargetDir,
    [switch]$Install,
    [switch]$Run,
    [switch]$Force
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

if (-not $TargetDir) { Write-Host "Paramètre -TargetDir obligatoire (dossier vide où créer la démonstration)." -ForegroundColor Red; exit $script:ExitUsage }
$source = Join-Path (Get-PluginRoot) "templates\testing-demo"
if (-not (Test-Path -LiteralPath $source)) { Write-Host "Modèle introuvable : $source" -ForegroundColor Red; exit $script:ExitUsage }
if (-not (Test-Path -LiteralPath $TargetDir)) { New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null }
$target = Resolve-ProjectDir $TargetDir
if (-not $target) { exit $script:ExitUsage }
$existing = @(Get-ChildItem -LiteralPath $target -Force -ErrorAction SilentlyContinue)
$pkgPath = Join-Path $target "package.json"
$alreadyDemo = (Test-Path -LiteralPath $pkgPath) -and ((Get-Content -LiteralPath $pkgPath -Raw) -match '"name":\s*"horn-testing-demo"')
if ($existing.Count -gt 0 -and -not $alreadyDemo -and -not $Force) {
    Write-Host "Le dossier cible n'est pas vide ($($existing.Count) élément(s)) et n'est pas une démonstration existante. Choisir un dossier vide ou ajouter -Force pour n'écraser que les fichiers du modèle." -ForegroundColor Red
    exit $script:ExitUsage
}

Write-Host "== horn-dev : démonstration des tests dans $target ==" -ForegroundColor Cyan
if ($alreadyDemo -and -not $Force) {
    Write-Host "Démonstration déjà présente : fichiers conservés (ajouter -Force pour les réécrire depuis le modèle)." -ForegroundColor DarkGray
} else {
    Copy-Item -Path (Join-Path $source "*") -Destination $target -Recurse -Force
    # Copy-Item avec * omet parfois les dossiers cachés : s'assurer de .github et .gitignore.
    foreach ($hidden in @(".github", ".gitignore")) {
        $src = Join-Path $source $hidden
        if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $target $hidden) -Recurse -Force }
    }
    $copied = @(Get-ChildItem -LiteralPath $target -Recurse -File -Force | Where-Object { $_.FullName -notmatch '\\node_modules\\' })
    Write-Host ("{0} fichier(s) copiés." -f $copied.Count)
    foreach ($f in $copied) { Write-Host ("  " + $f.FullName.Substring($target.Length + 1)) -ForegroundColor DarkGray }
}

if ($Install) {
    Write-Host "`n-> npm install (Vitest, Playwright)" -ForegroundColor DarkGray
    Push-Location -LiteralPath $target
    try {
        & cmd /c "npm install --no-fund --no-audit 2>&1"
        if ($LASTEXITCODE -ne 0) { Write-Host "npm install a échoué (code $LASTEXITCODE)." -ForegroundColor Red; exit $script:ExitFailed }
        Write-Host "-> npx playwright install chromium (téléchargement du navigateur)" -ForegroundColor DarkGray
        & cmd /c "npx playwright install chromium 2>&1"
        if ($LASTEXITCODE -ne 0) { Write-Host "Installation du navigateur échouée (code $LASTEXITCODE)." -ForegroundColor Red; exit $script:ExitFailed }
    } finally { Pop-Location }
}

if ($Run) {
    Push-Location -LiteralPath $target
    try {
        Write-Host "`n== Tests unitaires (Vitest) : attendu 6 réussis, 1 échec volontaire ==" -ForegroundColor Cyan
        & cmd /c "npm run test:unit 2>&1"
        $unit = $LASTEXITCODE
        Write-Host "`n== Tests de bout en bout (Playwright) : attendu 4 réussis, 1 échec volontaire ==" -ForegroundColor Cyan
        & cmd /c "npm run test:e2e 2>&1"
        $e2e = $LASTEXITCODE
        Write-Host ""
        Write-Host ("Codes de sortie : unitaires {0}, bout en bout {1}. Un code différent de 0 signale au moins un échec : c'est attendu tant que les tests de démonstration sont présents." -f $unit, $e2e) -ForegroundColor Yellow
        Write-Host "Rapport HTML : npm run test:e2e:report · Captures d'échec : test-results\ · Nettoyage : npm run demo:clean"
    } finally { Pop-Location }
}
exit $script:ExitOk
