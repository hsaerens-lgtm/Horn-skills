# Fonctions partagées par les scripts scripts/dev/*.ps1 (dot-source : . "$PSScriptRoot\_common.ps1").
# Compatible Windows PowerShell 5.1 et PowerShell 7.
Set-StrictMode -Version 2.0

$script:StatusOk      = "RÉUSSI"
$script:StatusFail    = "ÉCHOUÉ"
$script:StatusSkipped = "NON EXÉCUTÉ"
$script:StatusNA      = "NON APPLICABLE"

function Get-ProjectRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Resolve-Gitleaks {
    # 1) PATH courant ; 2) emplacement portable WinGet (le PATH utilisateur n'est relu qu'à l'ouverture d'un nouveau shell).
    $cmd = Get-Command gitleaks -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $pkgRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path $pkgRoot) {
        $candidate = Get-ChildItem $pkgRoot -Directory -Filter "Gitleaks.Gitleaks_*" -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName "gitleaks.exe" } | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($candidate) { return $candidate }
    }
    return $null
}

function Get-ToolVersion {
    param([string]$Command, [string[]]$Arguments = @("--version"))
    try {
        $out = & cmd /c "$Command $($Arguments -join ' ') 2>&1"
        if ($LASTEXITCODE -ne 0) { return $null }
        return (($out | Select-Object -First 1) -as [string]).Trim()
    } catch { return $null }
}

function Get-GitState {
    $root = Get-ProjectRoot
    $state = [ordered]@{ branch = $null; commit = $null; dirty = $null }
    if (-not (Test-Path (Join-Path $root ".git"))) { return $state }
    # cmd /c évite les erreurs NativeCommandError de PowerShell 5.1 quand git écrit sur stderr (ex. dépôt sans commit).
    # symbolic-ref fonctionne même avant le premier commit.
    $branch = & cmd /c "git -C `"$root`" symbolic-ref --short HEAD 2>nul"
    if ($LASTEXITCODE -eq 0) { $state.branch = ($branch -as [string]).Trim() } else { $state.branch = "(détaché)" }
    $commit = & cmd /c "git -C `"$root`" rev-parse --short HEAD 2>nul"
    if ($LASTEXITCODE -eq 0) { $state.commit = ($commit -as [string]).Trim() } else { $state.commit = "(aucun commit)" }
    $porcelain = & cmd /c "git -C `"$root`" status --porcelain 2>nul"
    $state.dirty = [bool]$porcelain
    return $state
}

function Invoke-Step {
    <#
      Exécute une commande via cmd.exe, capture la sortie dans un fichier journal et renvoie un objet résultat.
      Le code de sortie du programme est propagé tel quel dans .ExitCode.
    #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$LogPath,
        [bool]$Mandatory = $true,
        [string]$WorkingDirectory = (Get-ProjectRoot)
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Push-Location $WorkingDirectory
    try {
        & cmd /c "$Command > `"$LogPath`" 2>&1"
        $code = $LASTEXITCODE
    } catch {
        $code = -1
        Add-Content -Path $LogPath -Value $_.Exception.Message -Encoding utf8
    } finally { Pop-Location }
    $sw.Stop()
    $status = if ($code -eq 0) { $script:StatusOk } else { $script:StatusFail }
    return [pscustomobject]@{
        Name = $Name; Command = $Command; Mandatory = $Mandatory; Status = $status
        ExitCode = $code; DurationSec = [math]::Round($sw.Elapsed.TotalSeconds, 1); Log = $LogPath
    }
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
