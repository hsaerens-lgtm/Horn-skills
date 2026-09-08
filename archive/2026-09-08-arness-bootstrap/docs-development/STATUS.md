# État du projet Arness (STATUS)

Mis à jour le 2026-09-08 à la fin de la session d'installation de l'environnement. Ce fichier est la référence de reprise : `/horn-resume` le compare à l'état réel du dépôt.

## Résumé

- Projet : nouveau, Node.js / TypeScript, aucune fonctionnalité produit. `src/index.ts` affiche nom et version ; `src/app-info.ts` lit et valide `package.json`.
- Version : 0.1.0 · branche `main` · commit initial : voir `git log --oneline -1`.
- Dernière vérification : `check.ps1 -Profile full` → SUCCÈS le 2026-09-08 (`reports/dev/check-latest.json`, dossier hors Git donc à régénérer après un clone).
- Dernier paquet : `dist-packages/arness-0.1.0.tgz` (hors Git), produit le 2026-09-08 après vérification complète RÉUSSIE. Version **non validée** au sens produit : il n'y a pas encore de produit.

## Terminé (avec preuve)

| Élément | Preuve |
|---|---|
| Base TypeScript 7.0.2 + Vitest 5.0.0, 6 tests | `npm test` RÉUSSI, `npm run typecheck` RÉUSSI |
| Superpowers 6.3.0 et typescript-lsp 1.0.0, portée projet | `claude plugin list` : enabled, scope project |
| typescript-language-server 6.0.0 (npm global) | `typescript-language-server --version` |
| Context7 CLI connecté, skill `find-docs` et règle installés | `npx ctx7 whoami` → Logged in ; documentation Vitest récupérée (`/vitest-dev/vitest`) |
| Gitleaks 8.30.1 (WinGet, utilisateur), `.gitleaks.toml` | contrôle `secrets-arborescence` RÉUSSI, sorties masquées |
| Scripts `doctor`, `run`, `check` (quick/full), `package` | exécutés le 2026-09-08 ; `doctor` exit 0 ; `check` détecte un échec volontaire (fixture temporaire, exit 1, fixture supprimée) |
| Six skills `/horn-*`, quatre règles, permissions projet | fichiers présents, frontmatter valide, `settings.json` JSON valide |
| Documentation `docs/development/` (README, TOOLCHAIN, WORKFLOW, tasks) | fichiers présents |
| CI `quality.yml` et `dependabot.yml` | fichiers présents, **non exécutés** (pas de dépôt distant) |

## Incomplet / à confirmer en nouvelle session

- Découverte des skills `/horn-*` et `superpowers:*` dans l'autocomplétion : les skills créés pendant la session d'installation ne sont pas chargés dans cette même session (erreur « Unknown skill » constatée). À confirmer au prochain démarrage de Claude Code dans ce dossier.
- Navigation LSP réelle (définition de `parseAppInfo`, références) : le plugin est installé mais ne se charge qu'au démarrage d'une session.
- Hook `SessionStart` de Superpowers : s'exécutera au prochain démarrage.

## Bloqué

- Rien de bloqué côté local. La CI et Dependabot attendent un dépôt GitHub, que l'utilisateur créera et poussera lui-même s'il le souhaite (aucun push automatique).

## Non applicable pour l'instant

- Playwright (aucune interface), Promptfoo (aucun prompt), Serena (navigation TypeScript native suffisante), GitHub CLI (aucun dépôt distant).

## Décisions récentes

Voir `docs/development/tasks/2026-09-08-installation-environnement.md`.

## Prochaine action sûre

Ouvrir une nouvelle session Claude Code dans le projet et taper `/horn-resume`, puis vérifier l'autocomplétion `/horn-` et `/superpowers:` et poser une question de navigation (« où est définie parseAppInfo ? »). Ensuite seulement, définir la première fonctionnalité d'Arness avec `/horn-feature`.

## Dernière version préparée

- 0.1.0 · 2026-09-08 · `dist-packages/arness-0.1.0.tgz` · vérification complète RÉUSSIE · limites : aucune fonctionnalité produit, aucun test d'interface, CI non exécutée.
