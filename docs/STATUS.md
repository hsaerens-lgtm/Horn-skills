# État du dépôt horn-toolbox (STATUS)

Mis à jour le 2026-09-08. Fichier de reprise pour ce dépôt (source de la boîte à outils). L'état de chaque projet utilisateur vit dans son propre STATUS.

## Résumé
- Contenu : plugin `horn-dev` 0.1.0 (7 skills, 4 scripts PowerShell, modèles, références), marketplace locale `horn-toolbox`, tests Vitest du dispositif, docs.
- Installé en portée utilisateur : `horn-dev@horn-toolbox` 0.1.0, `superpowers@claude-plugins-official` 6.3.0, Context7 (`~/.claude/skills/find-docs`, `~/.claude/rules/context7.md`). Portée projet ici : `typescript-lsp`.
- Dernière vérification : `npm run check` (horn-check sur ce dépôt) → SUCCÈS le 2026-09-08 ; `npm test` 25/25 ; `claude plugin validate --strict` OK.

## Terminé (avec preuve)
| Élément | Preuve |
|---|---|
| Plugin valide | `claude plugin validate plugins/horn-dev --strict` et `claude plugin validate .` : Validation passed |
| Installation utilisateur | `claude plugin list` : horn-dev 0.1.0 scope user ; `claude plugin details` : Skills (7) |
| Scripts génériques | 14 tests de comportement réel sur deux projets synthétiques (Node, Python) : codes 0/1/2/3/4/5, idempotence, isolation, plugin inchangé |
| Séparation des données | tests d'hygiène : aucun chemin machine, aucune référence projet, aucun secret dans le plugin |
| Migration | anciens skills/scripts/règles/docs archivés dans `archive/2026-09-08-arness-bootstrap/` |

## Incomplet / à confirmer par l'utilisateur
- Découverte de `/horn-dev:*` et `/superpowers:*` dans une **nouvelle session interactive** (impossible depuis la session d'installation : `claude -p` non connecté). Action : ouvrir Claude Code dans un projet, taper `/horn-dev:` et vérifier l'autocomplétion, puis `/horn-dev:resume`.
- Premier usage réel de `/horn-dev:init` sur un vrai projet.

## Bloqué
- Rien. La CI (`.github/workflows/quality.yml`) attend un dépôt distant que l'utilisateur créera s'il le souhaite.

## Contraintes et limites de validation
- Les scripts ont été testés sous Windows PowerShell 5.1 ; PowerShell 7 et pwsh Linux/macOS non testés.
- La copie installée ne suit pas le source : bump de version + `claude plugin update` (docs/INSTALL.md).

## Prochaine action sûre
Nouvelle session Claude Code dans un projet réel : `/horn-dev:init`, valider la proposition, puis `/horn-dev:check`.
