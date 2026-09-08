<#
.SYNOPSIS
  Diagnostic de l'environnement de développement Arness (lecture seule).
.DESCRIPTION
  Vérifie la présence et la version des outils, l'état des dépendances, la configuration Claude Code
  (plugins, skills, règles) et l'accès à Context7. N'installe rien et ne modifie aucun fichier.
  Code de sortie : 0 si tous les prérequis obligatoires sont présents, 1 sinon.
#>
[CmdletBinding()]
param([switch]$SkipNetwork)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
$root = Get-ProjectRoot
Push-Location $root
$script:problems = 0
try {
    Write-Host "== Arness : diagnostic de l'environnement ($(Get-Date -Format 'yyyy-MM-dd HH:mm')) ==" -ForegroundColor Cyan

    function Check-Tool {
        param([string]$Label, [string]$Cmd, [string[]]$ToolArgs = @("--version"), [bool]$Required = $true, [string]$Hint = "")
        $v = Get-ToolVersion -Command $Cmd -Arguments $ToolArgs
        if ($v) { Write-StatusLine $script:StatusOk $Label $v }
        elseif ($Required) { $script:problems++; Write-StatusLine $script:StatusFail $Label "introuvable. $Hint" }
        else { Write-StatusLine $script:StatusSkipped $Label "absent (optionnel). $Hint" }
    }

    Write-Host "`n-- Outils --"
    Check-Tool "Node.js"  "node"
    Check-Tool "npm"      "npm"
    Check-Tool "Git"      "git"
    Check-Tool "Claude Code CLI" "claude" -Required $false -Hint "npm install -g @anthropic-ai/claude-code"
    Check-Tool "typescript-language-server (navigation LSP)" "typescript-language-server" -Required $false -Hint "npm install -g typescript-language-server@6.0.0"
    $gl = Resolve-Gitleaks
    if ($gl) { Write-StatusLine $script:StatusOk "Gitleaks" ("{0}  ({1})" -f (& $gl version), $gl) }
    else { $script:problems++; Write-StatusLine $script:StatusFail "Gitleaks" "introuvable. winget install --id Gitleaks.Gitleaks --exact --scope user" }

    Write-Host "`n-- Projet --"
    if (Test-Path "node_modules\vitest") { Write-StatusLine $script:StatusOk "Dépendances installées (node_modules)" }
    else { $script:problems++; Write-StatusLine $script:StatusFail "Dépendances" "lancer : npm ci" }
    foreach ($f in @("package.json","package-lock.json","tsconfig.json","tsconfig.build.json","vitest.config.ts",".gitleaks.toml","CLAUDE.md")) {
        if (Test-Path $f) { Write-StatusLine $script:StatusOk $f } else { $script:problems++; Write-StatusLine $script:StatusFail $f "manquant" }
    }

    Write-Host "`n-- Claude Code (portée projet) --"
    $settingsPath = ".claude\settings.json"
    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            Write-StatusLine $script:StatusOk ".claude/settings.json valide"
            $plugins = @()
            if ($settings.PSObject.Properties.Name -contains "enabledPlugins") { $plugins = @($settings.enabledPlugins.PSObject.Properties.Name) }
            foreach ($p in @("superpowers@claude-plugins-official","typescript-lsp@claude-plugins-official")) {
                if ($plugins -contains $p) { Write-StatusLine $script:StatusOk "plugin activé : $p" }
                else { $script:problems++; Write-StatusLine $script:StatusFail "plugin $p" "non déclaré. claude plugin install $p --scope project" }
            }
        } catch { $script:problems++; Write-StatusLine $script:StatusFail ".claude/settings.json" "JSON invalide : $($_.Exception.Message)" }
    } else { $script:problems++; Write-StatusLine $script:StatusFail ".claude/settings.json" "manquant" }
    foreach ($s in @("horn-feature","horn-bugfix","horn-check","horn-review","horn-release","horn-resume","find-docs")) {
        if (Test-Path ".claude\skills\$s\SKILL.md") { Write-StatusLine $script:StatusOk "skill /$s" } else { $script:problems++; Write-StatusLine $script:StatusFail "skill /$s" "SKILL.md manquant" }
    }
    foreach ($r in @("workflow.md","testing.md","safety.md","context7.md")) {
        if (Test-Path ".claude\rules\$r") { Write-StatusLine $script:StatusOk "règle $r" } else { $script:problems++; Write-StatusLine $script:StatusFail "règle $r" "manquante" }
    }
    $cache = Join-Path $env:USERPROFILE ".claude\plugins\cache\claude-plugins-official"
    if (Test-Path (Join-Path $cache "superpowers")) { Write-StatusLine $script:StatusOk "cache global Superpowers" $cache }
    else { Write-StatusLine $script:StatusSkipped "cache global Superpowers" "absent : relancer claude plugin install superpowers@claude-plugins-official --scope project" }

    Write-Host "`n-- Context7 (documentation) --"
    if ($SkipNetwork) { Write-StatusLine $script:StatusSkipped "Context7" "réseau ignoré (-SkipNetwork)" }
    else {
        $who = Get-ToolVersion -Command "npx" -Arguments @("-y","ctx7@0.5.10","whoami")
        if ($who) { Write-StatusLine $script:StatusOk "Context7 CLI" $who }
        else { Write-StatusLine $script:StatusSkipped "Context7 CLI" "non joignable ou non connecté (optionnel). npx ctx7@latest login" }
    }

    Write-Host "`n-- Git --"
    $g = Get-GitState
    if ($g.branch) { Write-StatusLine $script:StatusOk "dépôt Git" ("branche {0}, commit {1}, modifications non validées : {2}" -f $g.branch, ($g.commit -as [string]), $g.dirty) }
    else { Write-StatusLine $script:StatusSkipped "dépôt Git" "aucun dépôt" }

    Write-Host ""
    if ($script:problems -eq 0) { Write-Host "Diagnostic : tous les prérequis obligatoires sont présents." -ForegroundColor Green; exit 0 }
    else { Write-Host "Diagnostic : $($script:problems) problème(s) obligatoire(s)." -ForegroundColor Red; exit 1 }
} finally { Pop-Location }
