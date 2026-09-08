# horn-toolbox (dépôt source de la boîte à outils horn-dev)

Ce dépôt est le **source** du plugin Claude Code personnel `horn-dev` et de sa marketplace locale `horn-toolbox`. Ce n'est pas une application : ne pas y ajouter de code produit ni y déplacer d'autres projets. Ce fichier concerne le développement de la boîte à outils ; il ne doit pas être copié dans les projets utilisateurs (ils reçoivent la section `templates/CLAUDE-section.md` via `/horn-dev:init`).

## Structure

- `.claude-plugin/marketplace.json` : marketplace locale `horn-toolbox` (plugin `horn-dev`, source `./plugins/horn-dev`).
- `plugins/horn-dev/` : le plugin, autonome (manifeste, `skills/`, `scripts/`, `templates/`, `references/`, `README.md`). Aucune dépendance vers le reste du dépôt.
- `tests/` : tests Vitest du dispositif (structure du plugin, comportement réel des scripts PowerShell sur les projets synthétiques `tests/fixtures/alpha` et `beta`).
- `docs/` : architecture, installation et mise à jour, migration depuis l'ancien dossier Arness, état (`STATUS.md`).
- `archive/` : anciennes versions conservées pour référence, inactives.

## Commandes (développement de la boîte à outils)

- `npm ci` puis `npm test` : tests du dispositif (exécutent réellement les scripts dans des dossiers temporaires isolés, `HORN_DEV_HOME` redirigé).
- `npm run typecheck` · `npm run validate` (`claude plugin validate`) · `npm run check` (vérification horn-dev de ce dépôt via `.horn-dev.json`).
- Installation locale : voir `docs/INSTALL.md` (`claude plugin marketplace add <ce dossier>` puis `claude plugin install horn-dev@horn-toolbox --scope user`). La copie installée n'est mise à jour qu'après bump de version dans `plugins/horn-dev/.claude-plugin/plugin.json` et `claude plugin update`.

## Règles

- Le plugin ne doit contenir ni chemin absolu propre à cette machine, ni secret, ni donnée d'un projet (tests `tests/horn-dev-plugin.test.ts`).
- Scripts PowerShell compatibles Windows PowerShell 5.1 et PowerShell 7, `-ProjectDir` explicite, jamais le dossier du plugin comme cible.
- Ne jamais affaiblir un test pour obtenir un succès. Toute modification de skill se vérifie par `npm run validate` puis par une nouvelle session Claude Code après `claude plugin update`.
- Ne pas pousser, publier ni créer de dépôt distant sans demande explicite.
