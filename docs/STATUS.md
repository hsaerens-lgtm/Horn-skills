# État du dépôt horn-toolbox (STATUS)

Mis à jour le 2026-09-10. Fichier de reprise pour ce dépôt (source de la boîte à outils). L'état de chaque projet utilisateur vit dans son propre STATUS.

## Résumé
- Contenu : plugin `horn-dev` **0.2.0** (8 skills dont le point d'entrée `dev`, 5 scripts PowerShell, grille de vérifications, modèles, références), marketplace locale `horn-toolbox`, 28 tests Vitest du dispositif, docs.
- Installé en portée utilisateur : `horn-dev@horn-toolbox` 0.2.0 (mis à jour le 2026-09-10, `claude plugin details` : 8 skills ; les sessions déjà ouvertes doivent être relancées ou faire `/reload-plugins`), `superpowers@claude-plugins-official` 6.3.0, `security-guidance@claude-plugins-official` 2.0.7 (installé le 2026-09-10 sur accord ; 4 hooks ; venv Python créé au prochain démarrage), Context7. Portée projet ici : `typescript-lsp`.
- Dernière vérification : `npm run check:full` → SUCCÈS le 2026-09-10, empreinte `git:8cece6efd157b7d6` (avant commit de la 0.2.0) ; `npm test` 28/28 ; `claude plugin validate --strict` OK.

## Terminé (avec preuve)
| Élément | Preuve |
|---|---|
| Point d'entrée `dev` : intention, taille, grille | `claude plugin details` liste `dev` ; test de structure « analyser / relire / vérifier → non » |
| `feature` et `bugfix` proportionnés | fichiers réécrits, validation stricte OK |
| Preuves liées au code (`treeFingerprint`, `horn-fingerprint.ps1`) | test : empreinte du rapport = script ; change après modification ; identique après restauration |
| Outil indisponible → NON EXÉCUTÉ (code 2) | test « exécutable introuvable » |
| Copie installée = source | `claude plugin list` : 0.2.0 scope user |
| Inventaire des capacités et protocole d'essai | `docs/CAPABILITIES.md`, `docs/TEST-PROTOCOL.md` |

## Incomplet / à confirmer par l'utilisateur
- Essais du comportement de Claude (routage de `dev`, tâche simple sans dispositif excessif, analyse et revue sans modification, feature testée, bug avec non-régression) : **NON VÉRIFIÉS**, à faire en session interactive selon `docs/TEST-PROTOCOL.md` (la CLI `claude -p` n'est pas connectée sur ce poste).
- Découverte de `/horn-dev:dev` dans une nouvelle session (la session d'installation a chargé la 0.1.0).
- `security-guidance` à l'exécution : premier démarrage de session (création du venv, `~/.claude/security/log.txt`), puis essai d'un `eval(` dans une copie de fixture pour voir l'avertissement.

## Bloqué
- Rien côté local. CI en attente d'un dépôt distant (aucun push sans demande).

## Contraintes et limites de validation
- Routage par instructions non garanti ; commandes spécialisées = invocation fiable.
- Scripts testés sous Windows PowerShell 5.1 uniquement.
- Spécialistes externes (`security-guidance`, `wshobson/agents`) évalués, non installés sans accord (coût, hooks) : voir `docs/CAPABILITIES.md`.

## Prochaine action sûre
Nouvelle session dans une copie de `tests/fixtures/alpha` (après `/horn-dev:init`) : scénarios 1, 4 et 5 du protocole. Noter les résultats ici.
