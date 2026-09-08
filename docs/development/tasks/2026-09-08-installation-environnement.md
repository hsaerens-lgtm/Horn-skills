# Installation de l'environnement de développement assisté

Fichier : `docs/development/tasks/2026-09-08-installation-environnement.md` · Créée le 2026-09-08 · Type : vérification / outillage

## Objectif
Disposer d'un environnement reproductible (méthode, documentation, navigation, tests, secrets, scripts, skills, CI) pour développer Arness avec Claude Code, utilisable en workflow complet et outil par outil.

## Critères d'acceptation
- [x] Superpowers installé en portée projet et listé « enabled » (`claude plugin list`).
- [x] Context7 en mode CLI + skills, connecté, une documentation réelle récupérée (`/vitest-dev/vitest`).
- [x] Plugin typescript-lsp installé, binaire `typescript-language-server` 6.0.0 disponible.
- [ ] Navigation LSP constatée dans une session Claude Code (définition ou références) : **nécessite une nouvelle session**.
- [x] Vitest exécute un scénario réel (6 tests sur `parseAppInfo` / `loadAppInfo`).
- [x] Gitleaks installé, scan masqué RÉUSSI dans `check.ps1`.
- [x] `check.ps1` détecte un échec volontaire (fixture temporaire, code de sortie 1) puis fixture supprimée.
- [x] Six skills `/horn-*` présents avec frontmatter valide.
- [ ] Skills `/horn-*` et `superpowers:*` visibles dans l'autocomplétion d'une **nouvelle session** (découverte à confirmer).
- [x] Paquet local produit (`dist-packages/arness-0.1.0.tgz` + SHA-256 + notice).

## Périmètre
Inclus : outillage, base TypeScript minimale (identité de l'application), documentation, CI locale. Exclu : toute fonctionnalité produit, dépôt distant, Playwright, Promptfoo.

## Décisions
- 2026-09-08 : dossier vide → l'utilisateur choisit « nouveau projet Node.js / TypeScript ». Base neutre (tsc + Vitest), ni React ni Express imposés.
- 2026-09-08 : Context7 en mode CLI (pas de MCP) pour éviter deux mécanismes redondants.
- 2026-09-08 : `typescript-language-server` installé en npm global (portée utilisateur) car le plugin exige le binaire dans le PATH ; copie locale retirée pour éviter le doublon.
- 2026-09-08 : Gitleaks via WinGet, portée utilisateur, sans droits administrateur.
- 2026-09-08 : Playwright et Promptfoo non installés (pas d'interface, pas de prompts) ; documentés comme NON APPLICABLE.
- 2026-09-08 : `git push`, `npm publish`, `git reset --hard`, `git clean` refusés par les permissions du projet.

## Fichiers modifiés
Voir la liste complète dans `STATUS.md` (section « Fichiers créés le 2026-09-08 »).

## État des tests
- `npm run check` quick : SUCCÈS · `npm run check:full` : SUCCÈS (2026-09-08, rapports dans `reports/dev/`).
- Fixture d'échec : détectée (code 1), supprimée.
- Non couvert : interface (aucune), services externes (aucun), CI (non exécutée sans dépôt distant).

## Risques
- TypeScript 7.0.2 est la dernière version publiée ; si un outil tiers ne la supporte pas encore, revenir à 5.9.x (`npm i -D typescript@5.9 --save-exact`).
- Le PATH utilisateur mis à jour par WinGet n'est visible que dans les nouveaux terminaux ; `check.ps1` sait retrouver Gitleaks sans lui.

## Blocages
- Vérifications nécessitant une nouvelle session Claude Code (chargement des plugins, découverte des skills, navigation LSP).

## Prochaine action
Ouvrir une nouvelle session Claude Code dans `C:\Users\Horn S\Arness`, taper `/horn-resume`, puis vérifier que `/horn-` et `/superpowers:` apparaissent dans l'autocomplétion et que la question « où est définie parseAppInfo ? » passe par l'outil LSP.
