<#
.SYNOPSIS
  Prépare un projet cible pour la boîte à outils horn-dev (léger, idempotent, jamais silencieux).
.DESCRIPTION
  Sans -Apply : audit en lecture seule et aperçu de la configuration proposée ; rien n'est écrit.
  Avec -Apply : crée uniquement les fichiers absents (.horn-dev.json, STATUS.md, modèle de fiche,
  .gitleaks.toml, section horn-dev dans CLAUDE.md, entrée reports/ dans .gitignore). Ne remplace jamais
  un fichier existant ni une adaptation manuelle : une deuxième exécution ne change rien.
  Avec -Approve : enregistre le projet dans la liste locale des projets approuvés
  (%USERPROFILE%\.horn-dev\approved-projects.json, ou HORN_DEV_HOME), condition pour que horn-check
  exécute ses commandes.
  Aucune dépendance de développement n'est installée, aucune modification fonctionnelle du produit.
  Codes de sortie : 0 ok · 3 usage.
#>
[CmdletBinding()]
param(
    [string]$ProjectDir,
    [switch]$Apply,
    [switch]$Approve
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

$project = Resolve-ProjectDir $ProjectDir
if (-not $project) { exit $script:ExitUsage }
$templates = Join-Path (Get-PluginRoot) "templates"
$actions = New-Object System.Collections.Generic.List[string]

Write-Host "== horn-dev init : $project ==" -ForegroundColor Cyan
$audit = Get-ProjectAudit $project
Write-Host ("Technologies : {0}" -f ($(if ($audit.stack.Count) { $audit.stack -join ", " } else { "non identifiées" })))
Write-Host ("Manifestes   : {0}" -f ($(if ($audit.manifests.Count) { $audit.manifests -join ", " } else { "aucun" })))
foreach ($k in $audit.commands.Keys) { Write-Host ("Commande     : {0} = {1}" -f $k, $audit.commands[$k]) }
foreach ($n in $audit.notes) { Write-Host "Note         : $n" -ForegroundColor DarkYellow }

$existingCfg = $null
try { $existingCfg = Read-HornConfig $project } catch { Write-Host "Configuration existante invalide : $($_.Exception.Message)" -ForegroundColor Red; exit $script:ExitUsage }

if ($existingCfg) {
    Write-Host "`n$script:ConfigFileName déjà présent : conservé tel quel (adaptations manuelles respectées)." -ForegroundColor Green
    $actions.Add("EXISTANT $script:ConfigFileName")
} else {
    $proposed = New-ProposedConfig -ProjectDir $project -Audit $audit
    $json = $proposed | ConvertTo-Json -Depth 6
    if ($Apply) {
        Write-Utf8NoBom -Path (Join-Path $project $script:ConfigFileName) -Content $json
        $actions.Add("CRÉÉ $script:ConfigFileName")
    } else {
        Write-Host "`nConfiguration proposée ($script:ConfigFileName), non écrite (aperçu) :" -ForegroundColor Yellow
        Write-Host $json
        $actions.Add("APERÇU $script:ConfigFileName")
    }
}

# Chemins déclarés (ou par défaut)
$cfgForPaths = $existingCfg
if (-not $cfgForPaths) { $cfgForPaths = [pscustomobject]@{ paths = [pscustomobject]@{ reports = "reports/dev"; status = "docs/development/STATUS.md"; tasks = "docs/development/tasks" } } }
$paths = $cfgForPaths.paths
$statusRel = "docs/development/STATUS.md"; if ($paths.PSObject.Properties.Name -contains "status" -and $paths.status) { $statusRel = $paths.status }
$tasksRel = "docs/development/tasks"; if ($paths.PSObject.Properties.Name -contains "tasks" -and $paths.tasks) { $tasksRel = $paths.tasks }
$reportsRel = "reports/dev"; if ($paths.PSObject.Properties.Name -contains "reports" -and $paths.reports) { $reportsRel = $paths.reports }

function Ensure-File {
    param([string]$RelPath, [string]$TemplateName, [scriptblock]$Transform)
    $dest = Join-Path $project $RelPath
    if (Test-Path -LiteralPath $dest) { $script:actions.Add("EXISTANT $RelPath"); return }
    if (-not $Apply) { $script:actions.Add("À CRÉER $RelPath"); return }
    $content = Get-Content -LiteralPath (Join-Path $templates $TemplateName) -Raw -Encoding UTF8
    if ($Transform) { $content = & $Transform $content }
    Write-Utf8NoBom -Path $dest -Content $content
    $script:actions.Add("CRÉÉ $RelPath")
}

$projName = Split-Path $project -Leaf
Ensure-File $statusRel "STATUS.md" { param($c) $c.Replace("{{PROJECT}}", $projName).Replace("{{DATE}}", (Get-Date -Format "yyyy-MM-dd")) }
Ensure-File "$tasksRel/TEMPLATE.md" "TASK.md" $null
Ensure-File ".gitleaks.toml" "gitleaks.toml" { param($c) $c.Replace("{{PROJECT}}", $projName) }

# CLAUDE.md : section horn-dev ajoutée une seule fois (marqueurs), fichier créé s'il n'existe pas.
$claudeMd = Join-Path $project "CLAUDE.md"
$marker = "<!-- horn-dev:begin -->"
$section = (Get-Content -LiteralPath (Join-Path $templates "CLAUDE-section.md") -Raw -Encoding UTF8).Replace("{{STATUS}}", $statusRel).Replace("{{TASKS}}", $tasksRel)
if ((Test-Path -LiteralPath $claudeMd) -and ((Get-Content -LiteralPath $claudeMd -Raw -Encoding UTF8) -like "*$marker*")) { $actions.Add("EXISTANT CLAUDE.md (section horn-dev présente)") }
elseif ($Apply) {
    if (Test-Path -LiteralPath $claudeMd) { Append-Utf8NoBom -Path $claudeMd -Content "`n$section"; $actions.Add("COMPLÉTÉ CLAUDE.md (section horn-dev ajoutée)") }
    else { Write-Utf8NoBom -Path $claudeMd -Content "# $projName`n`n$section"; $actions.Add("CRÉÉ CLAUDE.md") }
} else { $actions.Add("À COMPLÉTER CLAUDE.md (section horn-dev)") }

# .gitignore : rapports hors Git (ajout d'une ligne seulement si un .gitignore existe et ne la contient pas)
$gitignore = Join-Path $project ".gitignore"
$ignoreLine = ($reportsRel.TrimEnd('/')) + "/"
if (Test-Path -LiteralPath $gitignore) {
    $lines = Get-Content -LiteralPath $gitignore -Encoding UTF8
    if ($lines -contains $ignoreLine -or $lines -contains ("/" + $ignoreLine) -or $lines -contains ($ignoreLine.Split('/')[0] + "/")) { $actions.Add("EXISTANT .gitignore ($ignoreLine)") }
    elseif ($Apply) { Append-Utf8NoBom -Path $gitignore -Content "`n# horn-dev : rapports de vérification (régénérables)`n$ignoreLine`n"; $actions.Add("COMPLÉTÉ .gitignore ($ignoreLine)") }
    else { $actions.Add("À COMPLÉTER .gitignore ($ignoreLine)") }
} else { $actions.Add("ABSENT .gitignore : non créé (à décider dans le projet)") }

# Approbation locale (jamais dans le projet ni dans le plugin)
if ($Approve) {
    if (Add-ProjectApproval $project) { $actions.Add("APPROUVÉ (liste locale $(Get-ApprovalFile))") } else { $actions.Add("DÉJÀ APPROUVÉ") }
} else {
    if (Test-ProjectApproved $project) { $actions.Add("DÉJÀ APPROUVÉ") } else { $actions.Add("NON APPROUVÉ : ajouter -Approve pour autoriser horn-check à exécuter les commandes du projet") }
}

Write-Host "`nActions :" -ForegroundColor Cyan
foreach ($a in $actions) { Write-Host "  $a" }
if (-not $Apply) { Write-Host "`nMode aperçu : rien n'a été écrit. Relancer avec -Apply (et -Approve) après validation du périmètre." -ForegroundColor Yellow }
exit $script:ExitOk
