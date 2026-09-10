# Ajouter à horn-dev la mise en place des tests (unitaires, bout en bout, CI)

Fichier : `docs/tasks/2026-09-10-tests-unitaires-e2e-ci.md` · Créée le 2026-09-10 · Type : outillage

## Objectif
Que l'utilisateur puisse, dans n'importe quel projet, comprendre et mettre en place tests unitaires, tests de bout en bout Playwright (si interface web) et CI qui rejoue les tests à chaque push, avec une démonstration lisible (un test qui passe, un test volontairement en échec).

## Critères d'acceptation
- [x] Skill `/horn-dev:testing` (utilisateur seul) avec modes `explique`, `demo <dossier vide>`, `setup`.
- [x] Mini application de démonstration `templates/testing-demo/` : Vitest (6 tests + 1 échec volontaire), Playwright (4 tests + 1 échec volontaire, capture et trace), serveur sans dépendance, workflow GitHub Actions, `demo:clean`.
- [x] Script `horn-testing-demo.ps1 -TargetDir [-Install] [-Run] [-Force]` refusant un dossier non vide qui n'est pas déjà une démonstration.
- [x] Démonstration réellement exécutée : résultats attendus obtenus, puis tout vert après nettoyage.
- [x] Mémo `references/testing-primer.md` (notions, lecture d'un échec, Playwright, CI, piège du port occupé).
- [x] Artefact pédagogique en six pages avec sorties et captures réelles.
- [x] Version 0.3.0 installée (`claude plugin details` : 9 skills) ; 30 tests du dispositif verts ; validation stricte OK.
- [ ] Mode `setup` exercé sur un vrai projet : à faire par l'utilisateur, le moment venu.

## Décisions
- 2026-09-10 : Playwright n'entre pas dans le dépôt de la boîte à outils (navigateur de 300 Mo) ; il vit dans la démonstration créée à la demande et dans les projets qui en ont besoin.
- 2026-09-10 : `reuseExistingServer: false` et port 4731 dans le modèle, après un échec réel dû à une autre application sur 4173.

## Fichiers modifiés
`plugins/horn-dev/skills/testing/SKILL.md`, `scripts/horn-testing-demo.ps1`, `templates/testing-demo/**`, `references/testing-primer.md`, `references/{workflow,verification-grid}.md`, `README.md`, `plugin.json` (0.3.0) ; `tests/horn-dev-plugin.test.ts` ; `docs/{USAGE,CAPABILITIES,STATUS}.md`.

## État des tests
- `npm test` : 30/30 RÉUSSIS (2026-09-10). `claude plugin validate --strict` : RÉUSSI (plugin et marketplace).
- Démonstration : voir STATUS.

## Risques
- Le mode `setup` dépend du jugement de Claude pour adapter les modèles au projet (port, commande de démarrage) : à vérifier au premier usage réel.

## Prochaine action
Sur un projet réel avec interface web : `/horn-dev:testing setup`, valider la proposition, observer l'exécution, puis pousser pour activer la CI.
