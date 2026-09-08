<#
.SYNOPSIS
  Commande de vérification de référence d'Arness (ne modifie jamais le code du produit).
.DESCRIPTION
  Profils :
    quick : typecheck, tests unitaires, recherche de secrets (travail courant).
    full  : quick + couverture, compilation, lancement de la version compilée, historique Git, audit npm (livraison).
  Statuts par contrôle : RÉUSSI, ÉCHOUÉ, NON EXÉCUTÉ, NON APPLICABLE.
  Un contrôle OBLIGATOIRE échoué ou non exécuté empêche le succès global.
  Codes de sortie : 0 succès global · 1 au moins un contrôle obligatoire ÉCHOUÉ · 2 un contrôle obligatoire NON EXÉCUTÉ · 3 erreur d'usage.
  Rapports : reports/dev/check-<profil>-<horodatage>.md et .json, plus reports/dev/check-latest.json (dossier hors Git).
#>
[CmdletBinding()]
param(
    [ValidateSet("quick","full")][string]$Profile = "quick",
    [switch]$NoNetwork
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
$root = Get-ProjectRoot
Push-Location $root
try {
    if (-not (Test-Path "package.json")) { Write-Host "package.json introuvable : lancer depuis le projet Arness." -ForegroundColor Red; exit 3 }
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportDir = Join-Path $root "reports\dev"
    $logDir = Join-Path $reportDir "logs\$stamp"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    $script:results = New-Object System.Collections.Generic.List[object]
    $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json

    Write-Host "== Arness : vérification, profil '$Profile' ($stamp) ==" -ForegroundColor Cyan

    function Run {
        param([string]$Name, [string]$Command, [bool]$Mandatory = $true)
        $log = Join-Path $logDir ("{0}.log" -f ($Name -replace '[^a-z0-9-]', '-'))
        Write-Host ("-> {0} : {1}" -f $Name, $Command) -ForegroundColor DarkGray
        $r = Invoke-Step -Name $Name -Command $Command -LogPath $log -Mandatory $Mandatory
        $script:results.Add($r)
        Write-StatusLine $r.Status $Name ("code {0}, {1}s" -f $r.ExitCode, $r.DurationSec)
        return $r
    }
    function Skip {
        param([string]$Name, [string]$Command, [bool]$Mandatory, [string]$Status, [string]$Note)
        $r = New-StepResult -Name $Name -Command $Command -Mandatory $Mandatory -Status $Status -Note $Note
        $script:results.Add($r); Write-StatusLine $Status $Name $Note
    }

    # 0. Prérequis
    $depsOk = Test-Path "node_modules\vitest"
    if (-not $depsOk) { Skip "dependances" "npm ci" $true $script:StatusSkipped "node_modules absent : lancer npm ci" }

    # 1. Typage (obligatoire)
    if (Test-Path "node_modules\typescript") { Run "typecheck" "npm run typecheck" | Out-Null }
    else { Skip "typecheck" "npm run typecheck" $true $script:StatusSkipped "TypeScript non installé" }

    # 2. Tests unitaires (obligatoire) ; en profil full, la couverture remplace l'exécution simple
    if ($depsOk) {
        if ($Profile -eq "full") { Run "tests-couverture" "npm run test:coverage" | Out-Null } else { Run "tests" "npm test" | Out-Null }
    } else { Skip "tests" "npm test" $true $script:StatusSkipped "Vitest non installé" }

    # 3. Recherche de secrets (obligatoire) ; sorties toujours masquées (--redact)
    $gl = Resolve-Gitleaks
    if ($gl) {
        $glReport = Join-Path $logDir "gitleaks-report.json"
        $hasCommit = $false
        if (Test-Path ".git") { & cmd /c "git rev-parse --verify HEAD >nul 2>&1"; $hasCommit = ($LASTEXITCODE -eq 0) }
        Run "secrets-arborescence" "`"$gl`" dir . --config .gitleaks.toml --redact --no-banner --exit-code 1 --report-format json --report-path `"$glReport`"" | Out-Null
        if ($Profile -eq "full" -and $hasCommit) {
            $glReport2 = Join-Path $logDir "gitleaks-git-report.json"
            Run "secrets-historique-git" "`"$gl`" git . --config .gitleaks.toml --redact --no-banner --exit-code 1 --report-format json --report-path `"$glReport2`"" | Out-Null
        }
    } else { Skip "secrets-arborescence" "gitleaks dir ." $true $script:StatusSkipped "Gitleaks introuvable : winget install --id Gitleaks.Gitleaks --exact --scope user" }

    if ($Profile -eq "full") {
        # 4. Compilation (obligatoire)
        $build = Run "build" "npm run build"
        # 5. Lancement de la version compilée (obligatoire) : la version affichée doit être celle de package.json
        if ($build.Status -eq $script:StatusOk) {
            $smokeLog = Join-Path $logDir "dist-smoke.log"
            $out = & cmd /c "node dist/index.js --version 2>&1"
            $code = $LASTEXITCODE
            Set-Content -Path $smokeLog -Value ($out -join "`n") -Encoding utf8
            $last = (($out | Select-Object -Last 1) -as [string])
            if ($null -eq $last) { $last = "" }
            $ok = ($code -eq 0) -and ($last.Trim() -eq $pkg.version)
            $st = $script:StatusFail
            if ($ok) { $st = $script:StatusOk }
            $r = New-StepResult -Name "dist-smoke" -Command "node dist/index.js --version  (attendu : $($pkg.version))" -Mandatory $true -Status $st -Note $smokeLog
            $r.ExitCode = $code; $script:results.Add($r); Write-StatusLine $st "dist-smoke" ("sortie : {0}" -f $last)
        } else { Skip "dist-smoke" "node dist/index.js --version" $true $script:StatusSkipped "compilation échouée" }
        # 6. Audit des dépendances (informatif, réseau requis)
        if ($NoNetwork) { Skip "npm-audit" "npm audit --audit-level=high" $false $script:StatusSkipped "-NoNetwork" }
        else { Run "npm-audit" "npm audit --audit-level=high" $false | Out-Null }
    }

    # 7. Scénarios navigateur : aucune interface web dans le projet à ce stade
    Skip "scenarios-navigateur" "playwright test" $false $script:StatusNA "aucune interface web : Playwright non installé (voir docs/development/TOOLCHAIN.md)"

    # Bilan
    $mandatory = @($script:results | Where-Object { $_.Mandatory })
    $failed = @($mandatory | Where-Object { $_.Status -eq $script:StatusFail })
    $skipped = @($mandatory | Where-Object { $_.Status -eq $script:StatusSkipped })
    $exit = 0; $verdict = "SUCCÈS : tous les contrôles obligatoires sont RÉUSSIS"
    if ($failed.Count -gt 0) { $exit = 1; $verdict = "ÉCHEC : $($failed.Count) contrôle(s) obligatoire(s) ÉCHOUÉ(S)" }
    elseif ($skipped.Count -gt 0) { $exit = 2; $verdict = "NON VÉRIFIÉ : $($skipped.Count) contrôle(s) obligatoire(s) NON EXÉCUTÉ(S)" }

    $git = Get-GitState
    $glVersion = $null
    if ($gl) { $glVersion = (& $gl version) }
    $versions = [ordered]@{
        node = (Get-ToolVersion node); npm = (Get-ToolVersion npm)
        typescript = $pkg.devDependencies.typescript; vitest = $pkg.devDependencies.vitest; gitleaks = $glVersion
    }
    $steps = @($script:results | ForEach-Object { [ordered]@{ name=$_.Name; status=$_.Status; mandatory=$_.Mandatory; exitCode=$_.ExitCode; durationSec=$_.DurationSec; command=$_.Command; log=$_.Log } })
    $report = [ordered]@{
        project = $pkg.name; version = $pkg.version; profile = $Profile; date = (Get-Date).ToString("s")
        git = $git; versions = $versions; verdict = $verdict; exitCode = $exit; steps = $steps
    }
    $jsonPath = Join-Path $reportDir "check-$Profile-$stamp.json"
    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding utf8
    Copy-Item $jsonPath (Join-Path $reportDir "check-latest.json") -Force

    $md = New-Object System.Collections.Generic.List[string]
    $md.Add("# Vérification Arness : profil $Profile")
    $md.Add("")
    $md.Add("- Date : $($report.date)")
    $md.Add("- Version : $($pkg.name) $($pkg.version)")
    $md.Add("- Git : branche $($git.branch), commit $($git.commit), modifications non validées : $($git.dirty)")
    $md.Add("- Versions : node $($versions.node), npm $($versions.npm), typescript $($versions.typescript), vitest $($versions.vitest), gitleaks $($versions.gitleaks)")
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
    $md.Add("Note : les sorties Gitleaks sont masquées (--redact). Un scan réussi n'est pas un audit de sécurité complet.")
    $mdPath = Join-Path $reportDir "check-$Profile-$stamp.md"
    ($md -join "`n") | Set-Content -Path $mdPath -Encoding utf8

    Write-Host ""
    $color = "Yellow"; if ($exit -eq 0) { $color = "Green" } elseif ($exit -eq 1) { $color = "Red" }
    Write-Host $verdict -ForegroundColor $color
    Write-Host "Rapport : $mdPath"
    exit $exit
} finally { Pop-Location }
