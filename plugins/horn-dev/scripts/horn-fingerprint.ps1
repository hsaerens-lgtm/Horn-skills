<#
.SYNOPSIS
  Affiche l'empreinte de l'état courant du code d'un projet cible (celle qui figure dans les rapports horn-check).
.DESCRIPTION
  Empreinte = SHA-256 de : commit HEAD + `git status --porcelain` + `git diff HEAD` (fichiers suivis et non suivis).
  Si deux empreintes diffèrent, le code a changé depuis le rapport : ses preuves sont périmées.
  Hors dépôt Git : empreinte des chemins, tailles et dates de modification des fichiers (hors dossiers générés).
  Code de sortie : 0 · 3 usage.
#>
[CmdletBinding()]
param([string]$ProjectDir)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"
$project = Resolve-ProjectDir $ProjectDir
if (-not $project) { exit $script:ExitUsage }
Write-Output (Get-TreeFingerprint $project)
exit $script:ExitOk
