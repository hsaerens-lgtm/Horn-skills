<#
.SYNOPSIS
  Vérification de référence horn-dev d'un projet cible, pilotée par son fichier .horn-dev.json.
.DESCRIPTION
  N'exécute que les commandes déclarées par le projet lui-même, et seulement si le projet a été
  explicitement approuvé (horn-init.ps1 -Approve). Ne modifie jamais le code du produit ; écrit
  uniquement des rapports dans <projet>/<paths.reports> (reports/dev par défaut).
  Profils : quick (travail courant) · full (préparation de livraison).
  Statuts : RÉUSSI, ÉCHOUÉ, NON EXÉCUTÉ, NON APPLICABLE.
  Codes de sortie : 0 succès · 1 contrôle obligatoire ÉCHOUÉ · 2 contrôle obligatoire NON EXÉCUTÉ ·
  3 usage · 4 projet non approuvé · 5 projet non initialisé (audit lecture seule affiché).
.EXAMPLE
  horn-check.ps1 -ProjectDir C:\chemin\projet -Profile quick
#>
[CmdletBinding()]
param(
    [string]$ProjectDir,
    [ValidateSet("quick","full")][string]$Profile = "quick",
    [switch]$NoNetwork
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

$project = Resolve-ProjectDir $ProjectDir
if (-not $project) { exit $script:ExitUsage }

try { $cfg = Read-HornConfig $project } catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit $script:ExitUsage }
if (-not $cfg) {
    Write-Host "Projet non initialisé pour horn-dev : $project" -ForegroundColor Yellow
    Write-Host "Aucune commande n'est exécutée. Audit en lecture seule :" -ForegroundColor Yellow
    $audit = Get-ProjectAudit $project
    Write-Host ("  Technologies détectées : {0}" -f ($(if ($audit.stack.Count) { $audit.stack -join ", " } else { "aucune" })))
    Write-Host ("  Manifestes : {0}" -f ($(if ($audit.manifests.Count) { $audit.manifests -join ", " } else { "aucun" })))
    foreach ($k in $audit.commands.Keys) { Write-Host ("  Commande déclarée {0} : {1}" -f $k, $audit.commands[$k]) }
    foreach ($n in $audit.notes) { Write-Host "  Note : $n" }
    Write-Host "Pour initialiser : horn-init.ps1 -ProjectDir `"$project`" (aperçu) puis -Apply -Approve après validation." -ForegroundColor Yellow
    exit $script:ExitNotInitialized
}
if (-not (Test-ProjectApproved $project)) {
    Write-Host "Projet non approuvé : $project" -ForegroundColor Red
    Write-Host "Les commandes d'un fichier de configuration ne sont exécutées qu'après approbation explicite :" -ForegroundColor Red
    Write-Host "  horn-init.ps1 -ProjectDir `"$project`" -Approve"
    exit $script:ExitNotApproved
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportsRel = "reports/dev"
if ($cfg.PSObject.Properties.Name -contains "paths" -and $cfg.paths.PSObject.Properties.Name -contains "reports" -and $cfg.paths.reports) { $reportsRel = $cfg.paths.reports }
$reportDir = Join-Path $project $reportsRel
$logDir = Join-Path $reportDir "logs\$stamp"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$script:results = New-Object System.Collections.Generic.List[object]
$projectName = Split-Path $project -Leaf
if ($cfg.PSObject.Properties.Name -contains "project" -and $cfg.project.PSObject.Properties.Name -contains "name") { $projectName = $cfg.project.name }

Write-Host "== horn-dev check : $projectName ($project), profil '$Profile', $stamp ==" -ForegroundColor Cyan

function Run {
    param([string]$Name, [string]$Command, [bool]$Mandatory = $true)
    $log = Join-Path $logDir ("{0}.log" -f ($Name -replace '[^A-Za-z0-9-]', '-'))
    Write-Host ("-> {0} : {1}" -f $Name, $Command) -ForegroundColor DarkGray
    $r = Invoke-Step -Name $Name -Command $Command -LogPath $log -WorkingDirectory $project -Mandatory $Mandatory
    $script:results.Add($r)
    Write-StatusLine $r.Status $Name ("code {0}, {1}s" -f $r.ExitCode, $r.DurationSec)
    return $r
}
function Skip {
    param([string]$Name, [string]$Command, [bool]$Mandatory, [string]$Status, [string]$Note)
    $r = New-StepResult -Name $Name -Command $Command -Mandatory $Mandatory -Status $Status -Note $Note
    $script:results.Add($r); Write-StatusLine $Status $Name $Note
}

# 1. Contrôles déclarés par le projet
$declared = @($cfg.checks)
if ($declared.Count -eq 0) { Skip "controles-declares" "-" $true $script:StatusSkipped "aucun contrôle déclaré dans .horn-dev.json" }
foreach ($c in $declared) {
    $profiles = @("quick","full"); if ($c.PSObject.Properties.Name -contains "profiles") { $profiles = @($c.profiles) }
    if (-not ($profiles -contains $Profile)) { continue }
    $mandatory = $true; if ($c.PSObject.Properties.Name -contains "mandatory") { $mandatory = [bool]$c.mandatory }
    if ($NoNetwork -and ($c.PSObject.Properties.Name -contains "network") -and $c.network) { Skip $c.id $c.command $mandatory $script:StatusSkipped "-NoNetwork"; continue }
    if (-not $c.command) { Skip $c.id "-" $mandatory $script:StatusSkipped "commande vide : à définir dans .horn-dev.json"; continue }
    $r = Run $c.id $c.command $mandatory
    if (($c.PSObject.Properties.Name -contains "expectOutput") -and $c.expectOutput -and $r.Status -eq $script:StatusOk) {
        $last = ((Get-Content -LiteralPath $r.Log -ErrorAction SilentlyContinue | Where-Object { $_ -ne "" } | Select-Object -Last 1) -as [string])
        if ($null -eq $last) { $last = "" }
        if ($last.Trim() -ne [string]$c.expectOutput) {
            $r.Status = $script:StatusFail
            Write-StatusLine $r.Status $c.id ("sortie « {0} » différente de l'attendu « {1} »" -f $last.Trim(), $c.expectOutput)
        }
    }
}

# 2. Recherche de secrets (sorties masquées)
$secretsEnabled = $true; $secretsMandatory = $true; $secretsProfiles = @("quick","full"); $secretsConfig = $null
if ($cfg.PSObject.Properties.Name -contains "secrets") {
    $s = $cfg.secrets
    if ($s.PSObject.Properties.Name -contains "enabled") { $secretsEnabled = [bool]$s.enabled }
    if ($s.PSObject.Properties.Name -contains "mandatory") { $secretsMandatory = [bool]$s.mandatory }
    if ($s.PSObject.Properties.Name -contains "profiles") { $secretsProfiles = @($s.profiles) }
    if ($s.PSObject.Properties.Name -contains "config" -and $s.config) { $secretsConfig = $s.config }
}
if ($secretsEnabled -and ($secretsProfiles -contains $Profile)) {
    $gl = Resolve-Gitleaks
    if ($gl) {
        $cfgArg = ""
        if ($secretsConfig -and (Test-Path (Join-Path $project $secretsConfig))) { $cfgArg = "--config `"$secretsConfig`"" }
        $rep = Join-Path $logDir "gitleaks-dir.json"
        Run "secrets-arborescence" "`"$gl`" dir . $cfgArg --redact --no-banner --exit-code 1 --report-format json --report-path `"$rep`"" $secretsMandatory | Out-Null
        $git = Get-GitState $project
        if ($Profile -eq "full" -and $git.isRepo -and $git.commit -ne "(aucun commit)") {
            $rep2 = Join-Path $logDir "gitleaks-git.json"
            Run "secrets-historique-git" "`"$gl`" git . $cfgArg --redact --no-banner --exit-code 1 --report-format json --report-path `"$rep2`"" $secretsMandatory | Out-Null
        }
    } else { Skip "secrets-arborescence" "gitleaks dir ." $secretsMandatory $script:StatusSkipped "Gitleaks introuvable (winget install --id Gitleaks.Gitleaks --exact --scope user)" }
} elseif (-not $secretsEnabled) { Skip "secrets" "-" $false $script:StatusNA "désactivé dans .horn-dev.json" }

# 3. Non applicables déclarés
if ($cfg.PSObject.Properties.Name -contains "notApplicable") {
    foreach ($na in @($cfg.notApplicable)) { Skip $na.id "-" $false $script:StatusNA $na.reason }
}

# Bilan
$mandatoryResults = @($script:results | Where-Object { $_.Mandatory })
$failed = @($mandatoryResults | Where-Object { $_.Status -eq $script:StatusFail })
$skipped = @($mandatoryResults | Where-Object { $_.Status -eq $script:StatusSkipped })
$exit = $script:ExitOk; $verdict = "SUCCÈS : tous les contrôles obligatoires sont RÉUSSIS"
if ($failed.Count -gt 0) { $exit = $script:ExitFailed; $verdict = "ÉCHEC : $($failed.Count) contrôle(s) obligatoire(s) ÉCHOUÉ(S)" }
elseif ($skipped.Count -gt 0) { $exit = $script:ExitNotVerified; $verdict = "NON VÉRIFIÉ : $($skipped.Count) contrôle(s) obligatoire(s) NON EXÉCUTÉ(S)" }

$gitState = Get-GitState $project
$fingerprint = Get-TreeFingerprint $project
$glv = $null; $glp = Resolve-Gitleaks; if ($glp) { $glv = (& $glp version) }
$pluginVersion = (Get-Content (Join-Path (Get-PluginRoot) ".claude-plugin\plugin.json") -Raw | ConvertFrom-Json).version
$steps = @($script:results | ForEach-Object { [ordered]@{ name=$_.Name; status=$_.Status; mandatory=$_.Mandatory; exitCode=$_.ExitCode; durationSec=$_.DurationSec; command=$_.Command; log=$_.Log } })
$report = [ordered]@{
    tool = "horn-dev check $pluginVersion"; project = $projectName; projectDir = $project; profile = $Profile
    date = (Get-Date).ToString("s"); git = $gitState; treeFingerprint = $fingerprint
    versions = [ordered]@{ node = (Get-ToolVersion node); python = (Get-ToolVersion python); gitleaks = $glv }
    verdict = $verdict; exitCode = $exit; steps = $steps
}
$jsonPath = Join-Path $reportDir "check-$Profile-$stamp.json"
Write-Utf8NoBom -Path $jsonPath -Content ($report | ConvertTo-Json -Depth 6)
Copy-Item -LiteralPath $jsonPath -Destination (Join-Path $reportDir "check-latest.json") -Force

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Vérification horn-dev : $projectName, profil $Profile")
$md.Add("")
$md.Add("- Date : $($report.date) · Outil : $($report.tool)")
$md.Add("- Projet : $project")
$md.Add("- Git : branche $($gitState.branch), commit $($gitState.commit), modifications non validées : $($gitState.dirty)")
$md.Add("- Empreinte du code vérifié : ``$fingerprint`` (comparer avec horn-fingerprint.ps1 : une empreinte différente périme ces preuves)")
$md.Add("- Versions : node $($report.versions.node), python $($report.versions.python), gitleaks $glv")
$md.Add("")
$md.Add("| Contrôle | Obligatoire | Statut | Code | Durée (s) | Commande |")
$md.Add("|---|---|---|---|---|---|")
foreach ($r in $script:results) {
    $m = "non"; if ($r.Mandatory) { $m = "oui" }
    $md.Add("| $($r.Name) | $m | $($r.Status) | $($r.ExitCode) | $($r.DurationSec) | ``$($r.Command)`` |")
}
$md.Add("")
$md.Add("**Verdict : $verdict** (code de sortie $exit)")
$md.Add("")
$md.Add("Journaux : $logDir")
$md.Add("")
$md.Add("Les sorties Gitleaks sont masquées (--redact). Un scan sans détection n'est pas un audit de sécurité complet. Un test simulé ne prouve pas qu'un service réel fonctionne.")
$mdPath = Join-Path $reportDir "check-$Profile-$stamp.md"
Write-Utf8NoBom -Path $mdPath -Content ($md -join "`n")

Write-Host ""
$color = "Yellow"; if ($exit -eq 0) { $color = "Green" } elseif ($exit -eq 1) { $color = "Red" }
Write-Host $verdict -ForegroundColor $color
Write-Host "Rapport : $mdPath"
Write-Host "Empreinte du code vérifié : $fingerprint"
exit $exit
