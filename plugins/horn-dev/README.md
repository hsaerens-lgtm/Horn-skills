# horn-dev

Assistance technique pour mes projets Claude Code (plugin personnel, portée utilisateur). Un point d'entrée, sept commandes spécialisées, cinq scripts PowerShell génériques pilotés par un fichier `.horn-dev.json` propre à chaque projet.

| Skill | Rôle | Invocation |
|---|---|---|
| `/horn-dev:dev [demande]` | point d'entrée : classe l'intention (implémenter, corriger, analyser, relire, vérifier), dimensionne, choisit les vérifications | utilisateur ou Claude |
| `/horn-dev:feature [besoin]` | implémentation proportionnée avec tests | utilisateur ou Claude |
| `/horn-dev:bugfix [problème]` | reproduction, cause racine, correction ciblée, non-régression | utilisateur ou Claude |
| `/horn-dev:check [quick|full]` | contrôles déclarés, sans modifier le code | utilisateur ou Claude |
| `/horn-dev:review [périmètre] [focus]` | revue séparée, preuves liées à l'empreinte du code | utilisateur ou Claude |
| `/horn-dev:resume` | reprise du contexte | utilisateur ou Claude |
| `/horn-dev:init` | adaptation légère d'un projet, approbation | utilisateur uniquement |
| `/horn-dev:release` | version locale, jamais publiée | utilisateur uniquement |
| `/horn-dev:design [écran, intention]` | concevoir ou restyler une interface : plan de design, états, accessibilité, mouvement sobre ; React Bits via le skill `anthropic-skills:reactbits` quand le projet est en React | utilisateur ou Claude |
| `/horn-dev:testing [explique|demo <dossier>|setup]` | expliquer et mettre en place tests unitaires, tests de bout en bout Playwright (si interface web) et CI ; démonstration avec un échec volontaire par famille | utilisateur uniquement |

Scripts (`scripts/`) : `horn-init.ps1`, `horn-check.ps1`, `horn-fingerprint.ps1`, `horn-doctor.ps1`, `horn-package.ps1` (tous avec `-ProjectDir <dossier>` obligatoire) et `horn-testing-demo.ps1 -TargetDir <dossier vide>` (mini application de démonstration des tests). Références (`references/`) : grille de vérifications par domaine, mémo sur les tests, guide de conception d'interface, workflow, schéma de configuration, correspondance Superpowers et Context7, anciens noms. Modèles (`templates/`), dont `testing-demo/` (Vitest, Playwright, CI GitHub Actions).

Prérequis : Windows PowerShell 5.1 ou PowerShell 7, Git. Recommandés : Gitleaks, Superpowers, Context7, plugin de langage du projet.

Le plugin n'écrit jamais dans son propre dossier ni dans un projet non approuvé ; il ne déclare aucun hook. Les projets approuvés sont listés dans `%USERPROFILE%\.horn-dev\approved-projects.json` (redirigeable via `HORN_DEV_HOME`).
