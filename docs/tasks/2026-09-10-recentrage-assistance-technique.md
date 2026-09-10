# Recentrer horn-dev en assistant d'implémentation et de correction

Fichier : `docs/tasks/2026-09-10-recentrage-assistance-technique.md` · Créée le 2026-09-10 · Type : outillage

## Objectif
L'utilisateur pilote le produit ; horn-dev prend en charge la technique (code, bugs, tests, sécurité, données, performances, packaging, IA) sans qu'il doive nommer un spécialiste, et produit des preuves liées à l'état exact du code.

## Critères d'acceptation
- [x] Point d'entrée `/horn-dev:dev` qui classe l'intention et respecte « analyser ≠ modifier » (test de structure).
- [x] Grille de vérifications par domaine (`references/verification-grid.md`) référencée par `dev`, `feature`, `bugfix`, `review`.
- [x] `feature` et `bugfix` proportionnés (petit / moyen / grand), sans cadrage systématique.
- [x] Preuves liées au code : `treeFingerprint` dans chaque rapport + `horn-fingerprint.ps1` (test : change après modification, identique après restauration).
- [x] Outil indisponible → NON EXÉCUTÉ, verdict NON VÉRIFIÉ (test).
- [x] Version 0.2.0 installée en portée utilisateur, `claude plugin details` : 8 skills.
- [ ] Essais du comportement de Claude (9 scénarios de `docs/TEST-PROTOCOL.md`) : **manuels, non exécutés** (CLI non connectée depuis cette session).

## Périmètre
Inclus : skills, scripts, tests, docs du plugin. Exclu : installation de spécialistes externes (documentés dans `docs/CAPABILITIES.md`), hooks, applications réelles.

## Décisions
- 2026-09-10 : pas d'agent par ligne de checklist ; une grille + une revue séparée couvrent les cas courants. `security-guidance` (officiel) et `wshobson/agents` documentés, non installés sans accord (coût, hooks).
- 2026-09-10 : détection d'exécutable manquant par le message du shell (cmd renvoie 1 avec redirection, pas 9009).
- 2026-09-10 : empreinte hors Git basée sur le contenu des fichiers, pas sur les dates.

## Fichiers modifiés
`plugins/horn-dev/skills/{dev,feature,bugfix,review,check}/SKILL.md`, `scripts/{_common,horn-check,horn-fingerprint}.ps1`, `references/{verification-grid,workflow,legacy-mapping}.md`, `README.md`, `plugin.json` (0.2.0) ; `tests/*.test.ts` ; `docs/{CAPABILITIES,TEST-PROTOCOL,USAGE,STATUS}.md`.

## État des tests
- `npm test` : 28/28 RÉUSSIS (2026-09-10). `npm run check:full` : voir STATUS. `claude plugin validate --strict` : RÉUSSI.

## Risques
- Le routage de `dev` par instructions n'est pas garanti : les commandes spécialisées restent l'invocation fiable.

## Blocages
- Essais interactifs à faire par l'utilisateur (protocole fourni).

## Prochaine action
Nouvelle session dans une copie de `tests/fixtures/alpha` : scénarios 1, 4 et 5 du protocole (tâche simple, analyse sans modification, revue sans modification).
