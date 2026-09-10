# Fonctions partagées des scripts horn-dev (dot-source : . "$PSScriptRoot\_common.ps1").
# Compatible Windows PowerShell 5.1 et PowerShell 7. Aucun chemin absolu propre à une machine ici.
Set-StrictMode -Version 2.0
# Sortie console en UTF-8 : les statuts accentués doivent rester lisibles par les outils qui capturent la sortie (Node, Claude Code).
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$script:StatusOk      = "RÉUSSI"
$script:StatusFail    = "ÉCHOUÉ"
$script:StatusSkipped = "NON EXÉCUTÉ"
$script:StatusNA      = "NON APPLICABLE"
$script:ConfigFileName = ".horn-dev.json"
$script:ConfigVersion  = 1

# Codes de sortie communs
$script:ExitOk = 0; $script:ExitFailed = 1; $script:ExitNotVerified = 2; $script:ExitUsage = 3
$script:ExitNotApproved = 4; $script:ExitNotInitialized = 5

function Get-HornHome {
    # Réglages locaux non partagés (approbations de projets). Redirigeable via HORN_DEV_HOME (tests).
    if ($env:HORN_DEV_HOME) { return $env:HORN_DEV_HOME }
    return (Join-Path $env:USERPROFILE ".horn-dev")
}

function Get-PluginRoot { return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path }

function Normalize-Path {
    param([string]$Path)
    if (-not $Path) { return $null }
    $full = [System.IO.Path]::GetFullPath($Path)
    return $full.TrimEnd('\', '/')
}

function Resolve-ProjectDir {
    param([string]$ProjectDir)
    if (-not $ProjectDir) {
        Write-Host "Paramètre -ProjectDir obligatoire : le dossier cible doit être explicite (jamais le dossier du plugin par défaut)." -ForegroundColor Red
        return $null
    }
    if (-not (Test-Path -LiteralPath $ProjectDir -PathType Container)) {
        Write-Host "Dossier cible introuvable : $ProjectDir" -ForegroundColor Red
        return $null
    }
    $norm = Normalize-Path (Resolve-Path -LiteralPath $ProjectDir).Path
    $plugin = Normalize-Path (Get-PluginRoot)
    if ($norm -ieq $plugin) {
        Write-Host "Refus : le dossier cible est le dossier du plugin lui-même." -ForegroundColor Red
        return $null
    }
    return $norm
}

function Resolve-Gitleaks {
    $cmd = Get-Command gitleaks -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if ($env:LOCALAPPDATA) {
        $pkgRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
        if (Test-Path $pkgRoot) {
            $candidate = Get-ChildItem $pkgRoot -Directory -Filter "Gitleaks.Gitleaks_*" -ErrorAction SilentlyContinue |
                ForEach-Object { Join-Path $_.FullName "gitleaks.exe" } | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($candidate) { return $candidate }
        }
    }
    return $null
}

function Get-ToolVersion {
    param([string]$Command, [string[]]$ToolArgs = @("--version"))
    try {
        $out = & cmd /c "$Command $($ToolArgs -join ' ') 2>&1"
        if ($LASTEXITCODE -ne 0) { return $null }
        return (($out | Select-Object -First 1) -as [string]).Trim()
    } catch { return $null }
}

function Get-GitState {
    param([string]$Path)
    $state = [ordered]@{ isRepo = $false; branch = $null; commit = $null; dirty = $null }
    if (-not (Test-Path (Join-Path $Path ".git"))) { return $state }
    $state.isRepo = $true
    $branch = & cmd /c "git -C `"$Path`" symbolic-ref --short HEAD 2>nul"
    if ($LASTEXITCODE -eq 0) { $state.branch = ($branch -as [string]).Trim() } else { $state.branch = "(détaché)" }
    $commit = & cmd /c "git -C `"$Path`" rev-parse --short HEAD 2>nul"
    if ($LASTEXITCODE -eq 0) { $state.commit = ($commit -as [string]).Trim() } else { $state.commit = "(aucun commit)" }
    $porcelain = & cmd /c "git -C `"$Path`" status --porcelain 2>nul"
    $state.dirty = [bool]$porcelain
    return $state
}

function Read-HornConfig {
    # Renvoie l'objet de configuration du projet, ou $null si absent. Lève une erreur si invalide.
    param([string]$ProjectDir)
    $path = Join-Path $ProjectDir $script:ConfigFileName
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    $cfg = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not ($cfg.PSObject.Properties.Name -contains "version") -or $cfg.version -ne $script:ConfigVersion) {
        throw "Fichier $script:ConfigFileName : champ 'version' attendu = $script:ConfigVersion"
    }
    if (-not ($cfg.PSObject.Properties.Name -contains "checks")) { throw "Fichier $script:ConfigFileName : tableau 'checks' manquant" }
    return $cfg
}

function Write-Utf8NoBom {
    # Écrit un fichier texte en UTF-8 sans BOM (Set-Content -Encoding UTF8 ajoute un BOM en PowerShell 5.1,
    # ce qui rend le JSON illisible pour Node et d'autres outils).
    param([Parameter(Mandatory)][string]$Path, [AllowEmptyString()][string]$Content)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Append-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [string]$Content)
    [System.IO.File]::AppendAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-ApprovalFile { return (Join-Path (Get-HornHome) "approved-projects.json") }

function Get-ApprovedProjects {
    $file = Get-ApprovalFile
    if (-not (Test-Path -LiteralPath $file)) { return @() }
    try {
        $data = Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($data.PSObject.Properties.Name -contains "projects") { return @($data.projects) }
    } catch { }
    return @()
}

function Test-ProjectApproved {
    param([string]$ProjectDir)
    $norm = Normalize-Path $ProjectDir
    foreach ($p in (Get-ApprovedProjects)) {
        if ((Normalize-Path $p.path) -ieq $norm) { return $true }
    }
    return $false
}

function Add-ProjectApproval {
    param([string]$ProjectDir)
    if (Test-ProjectApproved $ProjectDir) { return $false }
    $hornHome = Get-HornHome
    New-Item -ItemType Directory -Force -Path $hornHome | Out-Null
    $list = @(Get-ApprovedProjects)
    $list += [pscustomobject]@{ path = (Normalize-Path $ProjectDir); approvedAt = (Get-Date).ToString("s") }
    $doc = [ordered]@{ version = 1; projects = $list }
    Write-Utf8NoBom -Path (Get-ApprovalFile) -Content ($doc | ConvertTo-Json -Depth 4)
    return $true
}

function Invoke-Step {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$LogPath,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [bool]$Mandatory = $true
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Push-Location -LiteralPath $WorkingDirectory
    try {
        & cmd /c "$Command > `"$LogPath`" 2>&1"
        $code = $LASTEXITCODE
    } catch {
        $code = -1
        Add-Content -LiteralPath $LogPath -Value $_.Exception.Message -Encoding UTF8
    } finally { Pop-Location }
    $sw.Stop()
    $status = $script:StatusFail
    if ($code -eq 0) { $status = $script:StatusOk }
    elseif (Test-MissingExecutable -ExitCode $code -LogPath $LogPath) {
        # Outil indisponible : le contrôle n'a pas pu être exécuté, il ne doit pas passer pour un échec du produit.
        $status = $script:StatusSkipped
        Add-Content -LiteralPath $LogPath -Value "`n[horn-dev] Exécutable introuvable : contrôle NON EXÉCUTÉ (installer l'outil dans l'environnement du projet)." -Encoding UTF8
    }
    return [pscustomobject]@{
        Name = $Name; Command = $Command; Mandatory = $Mandatory; Status = $status
        ExitCode = $code; DurationSec = [math]::Round($sw.Elapsed.TotalSeconds, 1); Log = $LogPath
    }
}

function Test-MissingExecutable {
    # cmd.exe renvoie 9009 (ou 1 quand la sortie est redirigée) pour une commande inexistante ; bash 127.
    # On s'appuie sur le message exact du shell dans les premières lignes du journal, jamais sur le seul code.
    param([int]$ExitCode, [string]$LogPath)
    if ($ExitCode -eq 0) { return $false }
    $head = ""
    try { $head = ((Get-Content -LiteralPath $LogPath -TotalCount 3 -ErrorAction SilentlyContinue) -join " ") } catch { }
    return ($head -match "is not recognized as an internal or external command|n'est pas reconnu en tant que commande interne|: command not found")
}

function Get-TreeFingerprint {
    <#
      Empreinte SHA-256 de l'état du code : commit HEAD + fichiers modifiés/non suivis + diff complet.
      Deux rapports avec la même empreinte portent sur le même code ; une empreinte différente périme les preuves.
      Hors dépôt Git : chemins, tailles et dates des fichiers (dossiers générés exclus).
    #>
    param([string]$Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $sb = New-Object System.Text.StringBuilder
    if (Test-Path (Join-Path $Path ".git")) {
        [void]$sb.Append((& cmd /c "git -C `"$Path`" rev-parse HEAD 2>nul") -join "`n")
        [void]$sb.Append("`n--status--`n")
        [void]$sb.Append((& cmd /c "git -C `"$Path`" status --porcelain --untracked-files=all 2>nul") -join "`n")
        [void]$sb.Append("`n--diff--`n")
        [void]$sb.Append((& cmd /c "git -C `"$Path`" diff HEAD 2>nul") -join "`n")
        foreach ($u in (& cmd /c "git -C `"$Path`" ls-files --others --exclude-standard 2>nul")) {
            $f = Join-Path $Path $u
            if (Test-Path -LiteralPath $f -PathType Leaf) { [void]$sb.Append("`n--untracked $u--`n"); [void]$sb.Append([System.IO.File]::ReadAllText($f)) }
        }
        $prefix = "git:"
    } else {
        # Hors Git : contenu des fichiers (pas les dates, pour qu'un fichier restauré redonne la même empreinte). Fichiers > 5 Mo : taille seule.
        $skip = '\\(node_modules|dist|build|target|reports|coverage|\.venv|__pycache__|\.git)(\\|$)'
        Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch $skip } | Sort-Object FullName | ForEach-Object {
            [void]$sb.Append($_.FullName.Substring($Path.Length)); [void]$sb.Append("|"); [void]$sb.Append($_.Length); [void]$sb.Append("|")
            if ($_.Length -le 5MB) { [void]$sb.Append((($sha.ComputeHash([System.IO.File]::ReadAllBytes($_.FullName)) | ForEach-Object { $_.ToString("x2") }) -join "")) }
            [void]$sb.Append("`n")
        }
        $prefix = "fs:"
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($sb.ToString())
    $hash = ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join ""
    return $prefix + $hash.Substring(0, 16)
}

function New-StepResult {
    param([string]$Name, [string]$Command, [bool]$Mandatory, [string]$Status, [string]$Note = "")
    return [pscustomobject]@{
        Name = $Name; Command = $Command; Mandatory = $Mandatory; Status = $Status
        ExitCode = $null; DurationSec = 0; Log = $Note
    }
}

function Write-StatusLine {
    param([string]$Status, [string]$Label, [string]$Detail = "")
    $color = "DarkGray"
    if ($Status -eq $script:StatusOk) { $color = "Green" }
    elseif ($Status -eq $script:StatusFail) { $color = "Red" }
    elseif ($Status -eq $script:StatusSkipped) { $color = "Yellow" }
    $line = ("[{0}] {1}" -f $Status.PadRight(14), $Label)
    if ($Detail) { $line += "  -- $Detail" }
    Write-Host $line -ForegroundColor $color
}

function Get-ProjectAudit {
    # Détection en lecture seule des manifestes et des commandes réellement déclarées. N'invente rien.
    param([string]$ProjectDir)
    $audit = [ordered]@{ stack = @(); manifests = @(); commands = [ordered]@{}; tests = @(); notes = @() }
    $pkgPath = Join-Path $ProjectDir "package.json"
    if (Test-Path -LiteralPath $pkgPath) {
        $audit.manifests += "package.json"; $audit.stack += "node"
        try {
            $pkg = Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $scripts = @()
            if ($pkg.PSObject.Properties.Name -contains "scripts") { $scripts = $pkg.scripts.PSObject.Properties.Name }
            $lock = "npm"
            if (Test-Path (Join-Path $ProjectDir "pnpm-lock.yaml")) { $lock = "pnpm" } elseif (Test-Path (Join-Path $ProjectDir "yarn.lock")) { $lock = "yarn" }
            $runner = "npm run"; if ($lock -eq "pnpm") { $runner = "pnpm run" } elseif ($lock -eq "yarn") { $runner = "yarn" }
            if ($lock -eq "npm") { $audit.commands.install = "npm ci" } elseif ($lock -eq "pnpm") { $audit.commands.install = "pnpm install --frozen-lockfile" } else { $audit.commands.install = "yarn install --frozen-lockfile" }
            foreach ($s in @("test","typecheck","lint","build","dev","start","package")) {
                if ($scripts -contains $s) { $audit.commands[$s] = "$runner $s" }
            }
            if ($scripts -contains "test:coverage") { $audit.commands["test-full"] = "$runner test:coverage" }
            $deps = @()
            foreach ($k in @("dependencies","devDependencies")) { if ($pkg.PSObject.Properties.Name -contains $k) { $deps += $pkg.$k.PSObject.Properties.Name } }
            if ($deps -contains "typescript") { $audit.stack += "typescript" }
            if ($deps -contains "vitest") { $audit.tests += "vitest" }
            if ($deps -contains "jest") { $audit.tests += "jest" }
            if ($deps -contains "@playwright/test") { $audit.tests += "playwright" }
            if ($deps -contains "react") { $audit.stack += "react" }
            if ($deps -contains "electron") { $audit.stack += "electron" }
            if ($deps -contains "@tauri-apps/api") { $audit.stack += "tauri" }
        } catch { $audit.notes += "package.json illisible : $($_.Exception.Message)" }
    }
    $pyproject = Join-Path $ProjectDir "pyproject.toml"
    if ((Test-Path -LiteralPath $pyproject) -or (Test-Path (Join-Path $ProjectDir "requirements.txt"))) {
        $audit.stack += "python"
        if (Test-Path -LiteralPath $pyproject) { $audit.manifests += "pyproject.toml" } else { $audit.manifests += "requirements.txt" }
        $py = "python"; if (Test-Path (Join-Path $ProjectDir "uv.lock")) { $py = "uv run python"; $audit.commands.install = "uv sync" }
        $toml = ""; if (Test-Path -LiteralPath $pyproject) { $toml = Get-Content -LiteralPath $pyproject -Raw -Encoding UTF8 }
        $hasTestsDir = Test-Path (Join-Path $ProjectDir "tests")
        if ($toml -match "pytest") { $audit.commands.test = "$py -m pytest"; $audit.tests += "pytest" }
        elseif ($hasTestsDir -and (Get-ChildItem (Join-Path $ProjectDir "tests") -Filter "test_*.py" -ErrorAction SilentlyContinue)) { $audit.commands.test = "$py -m unittest discover -s tests"; $audit.tests += "unittest" }
        if ($toml -match "\[tool\.ruff\]" -or $toml -match "ruff") { $audit.commands.lint = "$py -m ruff check ." }
    }
    if (Test-Path (Join-Path $ProjectDir "Cargo.toml")) { $audit.stack += "rust"; $audit.manifests += "Cargo.toml"; $audit.commands.test = "cargo test"; $audit.commands.build = "cargo build --release" }
    if (Test-Path (Join-Path $ProjectDir "go.mod")) { $audit.stack += "go"; $audit.manifests += "go.mod"; $audit.commands.test = "go test ./..."; $audit.commands.build = "go build ./..." }
    $csproj = Get-ChildItem -LiteralPath $ProjectDir -Filter "*.csproj" -ErrorAction SilentlyContinue | Select-Object -First 1
    $sln = Get-ChildItem -LiteralPath $ProjectDir -Filter "*.sln" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($csproj -or $sln) { $audit.stack += "dotnet"; $audit.manifests += $(if ($sln) { $sln.Name } else { $csproj.Name }); $audit.commands.test = "dotnet test"; $audit.commands.build = "dotnet build -c Release" }
    if (Test-Path (Join-Path $ProjectDir "project.godot")) { $audit.stack += "godot"; $audit.manifests += "project.godot"; $audit.notes += "Godot détecté : tests via gdUnit4 à configurer manuellement (commande non inventée)." }
    if (Test-Path (Join-Path $ProjectDir "src-tauri")) { $audit.stack += "tauri" }
    if (Test-Path (Join-Path $ProjectDir ".gitleaks.toml")) { $audit.notes += ".gitleaks.toml présent" }
    if (Test-Path (Join-Path $ProjectDir "CLAUDE.md")) { $audit.notes += "CLAUDE.md présent" }
    if (Test-Path (Join-Path $ProjectDir ".claude")) { $audit.notes += ".claude/ présent (règles, skills ou réglages locaux)" }
    if (Test-Path (Join-Path $ProjectDir ".github\workflows")) { $audit.notes += "CI GitHub Actions présente" }
    $audit.stack = @($audit.stack | Select-Object -Unique)
    if ($audit.stack.Count -eq 0) { $audit.notes += "Aucun manifeste reconnu : technologie non identifiée." }
    if (-not $audit.commands.Contains("test")) { $audit.notes += "Aucune commande de test détectée : à définir manuellement dans $script:ConfigFileName (non inventée)." }
    return $audit
}

function New-ProposedConfig {
    param([string]$ProjectDir, $Audit)
    $name = Split-Path $ProjectDir -Leaf
    $checks = New-Object System.Collections.Generic.List[object]
    if ($Audit.commands.Contains("typecheck")) { $checks.Add([pscustomobject][ordered]@{ id="typecheck"; command=$Audit.commands.typecheck; profiles=@("quick","full"); mandatory=$true }) }
    if ($Audit.commands.Contains("lint")) { $checks.Add([pscustomobject][ordered]@{ id="lint"; command=$Audit.commands.lint; profiles=@("quick","full"); mandatory=$false }) }
    if ($Audit.commands.Contains("test")) {
        if ($Audit.commands.Contains("test-full")) {
            $checks.Add([pscustomobject][ordered]@{ id="tests"; command=$Audit.commands.test; profiles=@("quick"); mandatory=$true })
            $checks.Add([pscustomobject][ordered]@{ id="tests-full"; command=$Audit.commands["test-full"]; profiles=@("full"); mandatory=$true })
        } else { $checks.Add([pscustomobject][ordered]@{ id="tests"; command=$Audit.commands.test; profiles=@("quick","full"); mandatory=$true }) }
    }
    if ($Audit.commands.Contains("build")) { $checks.Add([pscustomobject][ordered]@{ id="build"; command=$Audit.commands.build; profiles=@("full"); mandatory=$true }) }
    $commands = [ordered]@{}
    foreach ($k in @("install","dev","start","package")) { if ($Audit.commands.Contains($k)) { $commands[$k] = $Audit.commands[$k] } }
    # Listes typées : l'opérateur += entre un tableau et un dictionnaire ordonné échoue en PowerShell 5.1.
    $limits = New-Object System.Collections.Generic.List[string]
    foreach ($n in $Audit.notes) { if ($n -like "Aucune commande de test*" -or $n -like "Aucun manifeste*" -or $n -like "Godot*") { $limits.Add([string]$n) } }
    $na = New-Object System.Collections.Generic.List[object]
    if (-not ($Audit.tests -contains "playwright")) { $na.Add([pscustomobject][ordered]@{ id="scenarios-navigateur"; reason="aucun test navigateur configuré (ajouter Playwright si une interface existe)" }) }
    return [ordered]@{
        '$schema' = "horn-dev/config-v1 (voir references/config-schema.md du plugin)"
        version = $script:ConfigVersion
        project = [ordered]@{ name = $name; stack = @($Audit.stack); manifests = @($Audit.manifests) }
        paths = [ordered]@{ reports = "reports/dev"; status = "docs/development/STATUS.md"; tasks = "docs/development/tasks" }
        commands = $commands
        checks = $checks.ToArray()
        secrets = [ordered]@{ enabled = $true; config = ".gitleaks.toml"; profiles = @("quick","full"); mandatory = $true }
        notApplicable = $na.ToArray()
        limits = $limits.ToArray()
    }
}
