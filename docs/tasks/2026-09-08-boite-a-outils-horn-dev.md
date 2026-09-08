# Transformer l'installation Arness en boîte à outils commune horn-dev

Fichier : `docs/tasks/2026-09-08-boite-a-outils-horn-dev.md` · Créée le 2026-09-08 · Type : outillage

## Objectif
Disposer d'un plugin Claude Code personnel `horn-dev` (portée utilisateur) réutilisable dans tous mes projets, ce dépôt en étant le source versionné, chaque projet ne conservant que ses informations propres.

## Critères d'acceptation
- [x] Plugin au format officiel, `claude plugin validate --strict` sans erreur.
- [x] Marketplace locale `horn-toolbox` ajoutée et `horn-dev@horn-toolbox` installé en portée utilisateur (`claude plugin list`, `claude plugin details` : 7 skills).
- [x] Superpowers en portée utilisateur, plus en portée projet ; Context7 (skill `find-docs`, règle) en portée utilisateur.
- [x] Scripts génériques avec `-ProjectDir` explicite, refus du dossier plugin, codes 3/4/5.
- [x] Deux projets synthétiques (Node sans dépendance, Python unittest) : commandes différentes exécutées, aucun fichier écrit dans l'autre projet ni dans le plugin, échec remonté (code 1), non vérifié (code 2), init idempotent, projet non initialisé en lecture seule.
- [ ] Découverte de `/horn-dev:*` dans une **nouvelle session interactive** (non vérifiable depuis cette session : `claude -p` répond « Not logged in »).
- [x] Anciens skills, scripts, règles et docs Arness archivés, une seule implémentation active.

## Périmètre
Inclus : plugin, tests du dispositif, docs, installation utilisateur. Exclu : hooks globaux, dépôt distant, Playwright, Promptfoo.

## Décisions
- 2026-09-08 : approbation explicite des projets dans `%USERPROFILE%\.horn-dev\approved-projects.json` avant toute exécution de commandes lues dans `.horn-dev.json`.
- 2026-09-08 : version déclarée uniquement dans `plugin.json` (jamais dans `marketplace.json`).
- 2026-09-08 : aucun hook dans horn-dev.
- 2026-09-08 : fichiers écrits par les scripts en UTF-8 sans BOM ; console en UTF-8 (PowerShell 5.1).

## Fichiers modifiés
Voir `docs/STATUS.md` et `git show --stat HEAD`.

## État des tests
- `npm test` : 25 tests RÉUSSIS (2026-09-08). `npm run typecheck` RÉUSSI. `claude plugin validate` RÉUSSI (plugin et marketplace).
- Non couvert : découverte en session interactive, navigation LSP, CI (pas de dépôt distant).

## Risques
- Modifier le source sans bump de version ne met pas à jour la copie installée (documenté dans docs/INSTALL.md).

## Blocages
- Aucun côté local.

## Prochaine action
Ouvrir une nouvelle session Claude Code dans un vrai projet, taper `/horn-dev:init`, valider, puis `/horn-dev:check`.
