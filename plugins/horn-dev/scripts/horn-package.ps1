<#
.SYNOPSIS
  Prépare une version locale distribuable d'un projet cible : vérification complète puis commande `package` du projet.
.DESCRIPTION
  1. Exécute horn-check.ps1 -Profile full ; s'arrête si le verdict n'est pas SUCCÈS (sauf -SkipChecks, la version
     est alors marquée NON validée).
  2. Exécute la commande `commands.package` déclarée dans .horn-dev.json, dans le dossier du projet.
  3. Écrit un compte rendu dans <projet>/<paths.reports>/release-<horodatage>.md (commit, verdict, sortie).
  Ne publie pas, ne pousse pas, ne signe pas, ne déploie pas.
  Codes de sortie : 0 · 1 échec · 2 non vérifié · 3 usage · 4 non approuvé · 5 non initialisé · 6 aucune commande package.
#>
[CmdletBinding()]
param([string]$ProjectDir, [switch]$SkipChecks)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
$project = Resolve-ProjectDir $ProjectDir
if (-not $project) { exit $script:ExitUsage }
try { $cfg = Read-HornConfig $project } catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit $script:ExitUsage }
if (-not $cfg) { Write-Host "Projet non initialisé : horn-init.ps1 -ProjectDir `"$project`"" -ForegroundColor Yellow; exit $script:ExitNotInitialized }
if (-not (Test-ProjectApproved $project)) { Write-Host "Projet non approuvé : horn-init.ps1 -ProjectDir `"$project`" -Approve" -ForegroundColor Red; exit $script:ExitNotApproved }
$packageCmd = $null
if ($cfg.PSObject.Properties.Name -contains "commands" -and $cfg.commands.PSObject.Properties.Name -contains "package") { $packageCmd = $cfg.commands.package }
if (-not $packageCmd) { Write-Host "Aucune commande 'package' déclarée dans .horn-dev.json : rien à construire (non inventé)." -ForegroundColor Yellow; exit 6 }

$git = Get-GitState $project
Write-Host "== horn-dev package : $($cfg.project.name) ($project) ==" -ForegroundColor Cyan
if ($git.dirty) { Write-Host "Attention : modifications non validées ; le paquet ne correspondra pas à un commit précis." -ForegroundColor Yellow }
$checkState = "RÉUSSIE"
if ($SkipChecks) { $checkState = "IGNORÉE (-SkipChecks) : version NON validée"; Write-Host $checkState -ForegroundColor Yellow }
else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\horn-check.ps1" -ProjectDir $project -Profile full
    if ($LASTEXITCODE -ne 0) { Write-Host "Vérification complète non concluante (code $LASTEXITCODE) : paquet non produit." -ForegroundColor Red; exit $LASTEXITCODE }
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportsRel = "reports/dev"; if ($cfg.paths.PSObject.Properties.Name -contains "reports" -and $cfg.paths.reports) { $reportsRel = $cfg.paths.reports }
$reportDir = Join-Path $project $reportsRel
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$log = Join-Path $reportDir "release-$stamp.log"
$r = Invoke-Step -Name "package" -Command $packageCmd -LogPath $log -WorkingDirectory $project
Write-StatusLine $r.Status "package" ("code {0}, {1}s" -f $r.ExitCode, $r.DurationSec)
$notes = @(
    "# Version locale : $($cfg.project.name)", "",
    "- Date : $((Get-Date).ToString('s'))", "- Projet : $project",
    "- Git : branche $($git.branch), commit $($git.commit), modifications non validées : $($git.dirty)",
    "- Vérification complète : $checkState (voir $reportsRel/check-latest.json)",
    "- Commande : ``$packageCmd`` → $($r.Status) (code $($r.ExitCode))", "- Journal : $log", "",
    "Une compilation réussie ne suffit pas à déclarer la version validée : lister les validations manuelles restantes dans STATUS.md.",
    "Retour arrière : réinstaller l'artefact de la version précédente conservé par le projet, ou revenir au commit précédent."
)
Write-Utf8NoBom -Path (Join-Path $reportDir "release-$stamp.md") -Content ($notes -join "`n")
Write-Host "Compte rendu : $(Join-Path $reportDir "release-$stamp.md")"
if ($r.Status -ne $script:StatusOk) { exit $script:ExitFailed }
exit $script:ExitOk
