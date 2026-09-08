# Arness

Application Node.js / TypeScript en démarrage (aucune fonctionnalité produit encore). Environnement Windows 11, Node 24, npm, Windows PowerShell 5.1.

## Commandes

- Lancer : `npm run dev` (sources) · `npm start` (dist compilé) · `scripts/dev/run.ps1 [-Mode dev|dist]`
- Vérifier : `npm run check` (rapide) · `npm run check:full` (livraison) · rapports dans `reports/dev/`
- Tests : `npm test` · `npm run test:watch` · `npm run test:coverage` · typage : `npm run typecheck`
- Diagnostic : `npm run doctor` · Paquet local : `npm run package` (jamais de publication)

## Structure

`src/` code · `tests/` tests Vitest · `scripts/dev/` scripts PowerShell · `docs/development/` guide, outillage, workflow, état (`STATUS.md`), fiches de tâches · `.claude/` règles et skills · `.github/workflows/quality.yml` CI (non exécutée tant qu'aucun dépôt distant n'existe).

## Règles

Voir `.claude/rules/` (workflow, tests, sécurité, Context7). Points d'entrée : `/horn-feature`, `/horn-bugfix`, `/horn-check`, `/horn-review`, `/horn-release`, `/horn-resume`. Méthode : plugin Superpowers. Documentation : Context7 (`/find-docs`). Reprise de session : lire `docs/development/STATUS.md`.
