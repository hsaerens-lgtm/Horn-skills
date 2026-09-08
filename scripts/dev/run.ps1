<#
.SYNOPSIS
  Lance l'application Arness.
.PARAMETER Mode
  dev  : exécute les sources TypeScript directement (tsx), sans compilation.
  dist : exécute la version compilée dist/index.js (compile d'abord si dist/ est absent).
.EXAMPLE
  .\scripts\dev\run.ps1                       # mode dev
  .\scripts\dev\run.ps1 -Mode dist --version  # version compilée
#>
[CmdletBinding()]
param(
    [ValidateSet("dev","dist")][string]$Mode = "dev",
    [Parameter(ValueFromRemainingArguments)][string[]]$AppArgs = @()
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
Push-Location (Get-ProjectRoot)
try {
    $extra = ($AppArgs | Where-Object { $_ -ne "--" }) -join " "
    if ($Mode -eq "dev") {
        & cmd /c "npx tsx src/index.ts $extra"
    } else {
        if (-not (Test-Path "dist\index.js")) {
            Write-Host "dist/ absent : compilation..." -ForegroundColor Yellow
            & cmd /c "npm run build"
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        }
        & cmd /c "node dist/index.js $extra"
    }
    exit $LASTEXITCODE
} finally { Pop-Location }
