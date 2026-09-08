# horn-dev

Boîte à outils de développement assisté pour Claude Code (plugin personnel, portée utilisateur). Sept skills et quatre scripts PowerShell génériques, pilotés par un fichier `.horn-dev.json` propre à chaque projet.

| Skill | Rôle | Invocation |
|---|---|---|
| `/horn-dev:init` | préparer le projet courant (audit, `.horn-dev.json`, fichiers de suivi, approbation) | utilisateur uniquement |
| `/horn-dev:feature [besoin]` | cadrer, planifier, développer avec tests, vérifier, faire relire | utilisateur ou Claude |
| `/horn-dev:bugfix [problème]` | reproduire, trouver la cause, corriger au minimum, test de non-régression | utilisateur ou Claude |
| `/horn-dev:check [quick|full]` | exécuter les contrôles déclarés sans modifier le code | utilisateur ou Claude |
| `/horn-dev:review [périmètre]` | relire avec preuves, contexte séparé en lecture seule | utilisateur ou Claude |
| `/horn-dev:release` | version locale distribuable, jamais de publication | utilisateur uniquement |
| `/horn-dev:resume` | relire l'état et proposer la prochaine action | utilisateur ou Claude |

Scripts (`scripts/`) : `horn-init.ps1`, `horn-check.ps1`, `horn-doctor.ps1`, `horn-package.ps1`, tous avec `-ProjectDir <dossier>` obligatoire. Modèles (`templates/`) et références (`references/`) : schéma de configuration, workflow, correspondance avec Superpowers et Context7, anciens noms.

Prérequis : Windows PowerShell 5.1 ou PowerShell 7, Git. Optionnels mais recommandés : Gitleaks (contrôle secrets), Superpowers (méthode), Context7 (documentation), plugin de langage du projet.

Le plugin n'écrit jamais dans son propre dossier ni dans un projet non approuvé. Les projets approuvés sont listés dans `%USERPROFILE%\.horn-dev\approved-projects.json` (redirigeable via `HORN_DEV_HOME`).
