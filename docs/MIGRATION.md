# Migration depuis l'installation « Arness » du 2026-09-08

## Inventaire de l'existant (avant transformation)

| Élément | Constat | Devenir |
|---|---|---|
| Six skills `.claude/skills/horn-*` (portée projet) | découverts dans la session ; contenu réutilisable mais commandes npm et chemins Arness codés en dur | remplacés par `plugins/horn-dev/skills/*` génériques ; anciens fichiers archivés dans `archive/` |
| `.claude/skills/find-docs` + `.claude/rules/context7.md` (Context7, portée projet) | fonctionnels, connectés | réinstallés en portée utilisateur (`npx ctx7@latest setup --cli --claude`) ; copies projet retirées |
| `.claude/rules/{workflow,testing,safety}.md` | consignes propres à Arness | contenu repris dans `plugins/horn-dev/references/workflow.md`, les sections « Limites » des skills et `templates/CLAUDE-section.md` ; archivés |
| `scripts/dev/{check,doctor,run,package,_common}.ps1` | fonctionnels mais liés à npm et au dossier courant | remplacés par `plugins/horn-dev/scripts/horn-*.ps1` (cible `-ProjectDir` explicite, configuration `.horn-dev.json`) ; archivés |
| Superpowers 6.3.0 (portée projet) | disponible seulement dans ce dossier | réinstallé en portée **utilisateur** ; entrée projet retirée |
| typescript-lsp 1.0.0 (portée projet) + `typescript-language-server` global | dépend du langage du projet | conservé en portée projet ici (tests TypeScript) ; suggéré par `/horn-dev:init` ailleurs |
| Gitleaks 8.30.1 (WinGet, utilisateur) | disponible pour tous les projets | inchangé ; utilisé par `horn-check.ps1` |
| `src/`, `tests/app-info.test.ts`, `tsconfig.build.json` | module d'exemple d'une application vide | archivés dans `archive/2026-09-08-arness-bootstrap/` |
| `docs/development/*` | guide et état d'une application Arness inexistante | remplacés par `docs/` (architecture, installation, usage, migration, état) ; archivés |
| `.github/workflows/quality.yml`, `dependabot.yml` | CI d'une application Node | réécrite pour tester le dispositif (Windows) ; non exécutée sans dépôt distant |
| Permissions `.claude/settings.json` (allow scripts/dev, deny push/publish) | chemins obsolètes | réécrites pour ce dépôt |
| Doublons | `typescript-language-server` avait été installé en local puis en global : seul le global reste | — |
| Non vérifié dans la première installation | découverte des skills et navigation LSP en nouvelle session | la découverte des skills projet a été constatée au redémarrage de session du 2026-09-08 ; la navigation LSP reste non vérifiée |

## Correspondance des anciens noms

Voir `plugins/horn-dev/references/legacy-mapping.md`. En résumé : `/horn-<x>` → `/horn-dev:<x>` pour feature, bugfix, check, review, release, resume ; `/horn-dev:init` est nouveau.

## Éléments archivés (inactifs)

`archive/2026-09-08-arness-bootstrap/` : module d'exemple, ancien test, anciens skills, règles, scripts et documentation. Ils ne sont ni chargés par Claude Code (hors de `.claude/`), ni exécutés par les tests (`vitest.config.ts` exclut `archive/`). Ils peuvent être supprimés après quelques semaines d'usage du plugin sans regret : tout est dans l'historique Git (commit `1ea1127`).

## Ce qui n'a pas été touché

Le vault Obsidian (lecture seule), `~/.claude/CLAUDE.md`, le skill global `vault-sync`, les autres projets du poste.
