<#
.SYNOPSIS
  Diagnostic horn-dev en lecture seule : disponibilité personnelle des outils, puis état d'un projet cible si -ProjectDir est fourni.
.DESCRIPTION
  Distingue trois niveaux : (1) outils disponibles pour l'utilisateur (Claude Code, plugin horn-dev, Superpowers,
  Context7, Gitleaks, Node, Git) ; (2) configuration du projet (.horn-dev.json, approbation, fichiers de suivi) ;
  (3) dépendances du projet (présence des exécutables des commandes déclarées, sans les installer).
  Code de sortie : 0 si les prérequis obligatoires sont présents, 1 sinon, 3 usage.
#>
[CmdletBinding()]
param([string]$ProjectDir, [switch]$SkipNetwork)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
$script:problems = 0

function Check-Tool {
    param([string]$Label, [string]$Cmd, [string[]]$ToolArgs = @("--version"), [bool]$Required = $true, [string]$Hint = "")
    $v = Get-ToolVersion -Command $Cmd -ToolArgs $ToolArgs
    if ($v) { Write-StatusLine $script:StatusOk $Label $v }
    elseif ($Required) { $script:problems++; Write-StatusLine $script:StatusFail $Label "introuvable. $Hint" }
    else { Write-StatusLine $script:StatusSkipped $Label "absent (optionnel). $Hint" }
}

Write-Host "== horn-dev doctor ($(Get-Date -Format 'yyyy-MM-dd HH:mm')) ==" -ForegroundColor Cyan
Write-Host "Plugin (copie exécutée) : $(Get-PluginRoot)"
Write-Host "`n-- 1. Disponibilité personnelle --"
Check-Tool "Git" "git"
Check-Tool "Node.js" "node" -Required $false
Check-Tool "Python" "python" -Required $false
Check-Tool "Claude Code CLI" "claude" -Required $false -Hint "npm install -g @anthropic-ai/claude-code"
$gl = Resolve-Gitleaks
if ($gl) { Write-StatusLine $script:StatusOk "Gitleaks" ("{0}  ({1})" -f (& $gl version), $gl) }
else { Write-StatusLine $script:StatusSkipped "Gitleaks" "absent : le contrôle secrets sera NON EXÉCUTÉ (winget install --id Gitleaks.Gitleaks --exact --scope user)" }

$pluginList = $null
try { $pluginList = (& cmd /c "claude plugin list 2>&1") -join "`n" } catch { }
if ($pluginList) {
    foreach ($p in @("horn-dev@horn-toolbox","superpowers@claude-plugins-official")) {
        if ($pluginList -match [regex]::Escape($p)) {
            $block = ($pluginList -split "❯")| Where-Object { $_ -match [regex]::Escape($p) } | Select-Object -First 1
            $ver = ""; $scope = ""
            if ($block -match "Version:\s*(\S+)") { $ver = $Matches[1] }
            if ($block -match "Scope:\s*(\S+)") { $scope = $Matches[1] }
            Write-StatusLine $script:StatusOk "plugin $p" "version $ver, portée $scope"
        } else { Write-StatusLine $script:StatusSkipped "plugin $p" "non installé selon claude plugin list" }
    }
} else { Write-StatusLine $script:StatusSkipped "plugins Claude Code" "claude plugin list indisponible" }

if ($SkipNetwork) { Write-StatusLine $script:StatusSkipped "Context7" "réseau ignoré (-SkipNetwork)" }
else {
    $who = Get-ToolVersion -Command "npx" -ToolArgs @("-y","ctx7@latest","whoami")
    if ($who) { Write-StatusLine $script:StatusOk "Context7 CLI" $who } else { Write-StatusLine $script:StatusSkipped "Context7 CLI" "non joignable ou non connecté (npx ctx7@latest login)" }
}
$approvals = Get-ApprovalFile
if (Test-Path -LiteralPath $approvals) { Write-StatusLine $script:StatusOk "projets approuvés" ("{0} entrée(s) dans {1}" -f @(Get-ApprovedProjects).Count, $approvals) }
else { Write-StatusLine $script:StatusSkipped "projets approuvés" "aucune liste ($approvals)" }

if ($ProjectDir) {
    $project = Resolve-ProjectDir $ProjectDir
    if (-not $project) { exit $script:ExitUsage }
    Write-Host "`n-- 2. Projet cible : $project --"
    $cfg = $null
    try { $cfg = Read-HornConfig $project } catch { $script:problems++; Write-StatusLine $script:StatusFail ".horn-dev.json" $_.Exception.Message }
    if ($cfg) {
        Write-StatusLine $script:StatusOk ".horn-dev.json" ("projet {0}, {1} contrôle(s)" -f $cfg.project.name, @($cfg.checks).Count)
        if (Test-ProjectApproved $project) { Write-StatusLine $script:StatusOk "approbation" "projet approuvé" } else { $script:problems++; Write-StatusLine $script:StatusFail "approbation" "horn-init.ps1 -ProjectDir `"$project`" -Approve" }
        foreach ($rel in @($cfg.paths.status, (Join-Path $cfg.paths.tasks "TEMPLATE.md"))) {
            if (Test-Path (Join-Path $project $rel)) { Write-StatusLine $script:StatusOk $rel } else { Write-StatusLine $script:StatusSkipped $rel "absent (horn-init -Apply le crée)" }
        }
        Write-Host "`n-- 3. Dépendances du projet (exécutables des commandes déclarées) --"
        $exes = @()
        foreach ($c in @($cfg.checks)) { if ($c.command) { $exes += ($c.command -split '\s+')[0] } }
        foreach ($e in ($exes | Select-Object -Unique)) {
            if (Get-Command $e -ErrorAction SilentlyContinue) { Write-StatusLine $script:StatusOk "exécutable $e" }
            else { $script:problems++; Write-StatusLine $script:StatusFail "exécutable $e" "introuvable dans le PATH : installer dans l'environnement du projet" }
        }
        if ($cfg.project.stack -contains "node" -and -not (Test-Path (Join-Path $project "node_modules"))) { Write-StatusLine $script:StatusSkipped "node_modules" "absent : lancer la commande install du projet ($($cfg.commands.install))" }
    } elseif (-not ($script:problems)) {
        Write-StatusLine $script:StatusSkipped ".horn-dev.json" "projet non initialisé (horn-init.ps1 -ProjectDir ... pour un aperçu)"
    }
    $g = Get-GitState $project
    if ($g.isRepo) { Write-StatusLine $script:StatusOk "Git" ("branche {0}, commit {1}, non validé : {2}" -f $g.branch, $g.commit, $g.dirty) } else { Write-StatusLine $script:StatusSkipped "Git" "aucun dépôt" }
}

Write-Host ""
if ($script:problems -eq 0) { Write-Host "Diagnostic : prérequis obligatoires présents." -ForegroundColor Green; exit $script:ExitOk }
Write-Host "Diagnostic : $($script:problems) problème(s)." -ForegroundColor Red; exit $script:ExitFailed
