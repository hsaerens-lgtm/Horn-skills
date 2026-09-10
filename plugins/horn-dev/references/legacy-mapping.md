# Correspondance avec les anciens skills `/horn-*` (projet Arness, 2026-09-08)

Les six skills créés en portée projet dans le dossier Arness sont remplacés par les skills du plugin. Il ne doit rester qu'une implémentation active.

| Ancien (projet) | Nouveau (plugin, portée utilisateur) | Différences |
|---|---|---|
| `/horn-feature` | `/horn-dev:feature` | générique : lit `.horn-dev.json` au lieu de commandes npm codées en dur |
| `/horn-bugfix` | `/horn-dev:bugfix` | idem |
| `/horn-check` | `/horn-dev:check` | appelle `horn-check.ps1 -ProjectDir` du plugin au lieu de `scripts/dev/check.ps1` ; codes 4 et 5 ajoutés (non approuvé, non initialisé) |
| `/horn-review` | `/horn-dev:review` | inchangé dans l'esprit (contexte séparé, preuves exigées) |
| `/horn-release` | `/horn-dev:release` | appelle `horn-package.ps1` qui exécute `commands.package` du projet |
| `/horn-resume` | `/horn-dev:resume` | injection dynamique basée sur le projet courant et `.horn-dev.json` |
| — | `/horn-dev:init` | nouveau : préparation légère et idempotente d'un projet |
| — | `/horn-dev:dev` (0.2.0) | nouveau : point d'entrée qui classe l'intention et dimensionne le parcours |

Anciens scripts `scripts/dev/{check,doctor,run,package,_common}.ps1` (propres à Arness) → `plugins/horn-dev/scripts/horn-{check,init,doctor,package}.ps1` génériques avec `-ProjectDir` obligatoire. `run.ps1` n'a pas d'équivalent générique : le lancement reste la commande `commands.dev` ou `commands.start` du projet.

Anciennes règles `.claude/rules/{workflow,testing,safety}.md` → contenu repris dans `references/workflow.md` et dans les sections « Limites » de chaque skill ; le modèle `templates/CLAUDE-section.md` résume l'essentiel pour chaque projet.
