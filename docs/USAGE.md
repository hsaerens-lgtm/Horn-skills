# Utiliser horn-dev dans un projet

## Ouvrir un projet et démarrer

1. Ouvrir Claude Code dans le dossier du projet (le dossier ouvert est le projet cible ; horn-dev ne devine jamais un autre dossier).
2. Première fois : taper `/horn-dev:init`. Claude fait un audit en lecture seule, propose un `.horn-dev.json` (commandes et contrôles déduits des manifestes du projet, jamais inventés), liste les fichiers qu'il créerait, et attend votre accord. Après accord, il crée les fichiers absents et **approuve** le projet (autorisation locale d'exécuter ses commandes).
3. Ensuite, à chaque session : `/horn-dev:resume` pour reprendre le contexte.

Sans init, seules les lectures sont possibles : `/horn-dev:check` affiche un audit et le code 5, `/horn-dev:resume` conclut « projet non initialisé ».

## Les commandes

| Commande | Exemple | Ce qui se passe |
|---|---|---|
| `/horn-dev:check` | `/horn-dev:check` · `/horn-dev:check full` | exécute les contrôles de `.horn-dev.json` (typage, tests, build, secrets…), écrit le rapport dans le dossier `reports` du projet, restitue RÉUSSI / ÉCHOUÉ / NON EXÉCUTÉ / NON APPLICABLE. Ne modifie rien. |
| `/horn-dev:feature` | `/horn-dev:feature Exporter la liste en CSV` | cadrage (validation si ambigu), fiche, plan, TDD, check, revue, STATUS. |
| `/horn-dev:bugfix` | `/horn-dev:bugfix L'export CSV perd les accents` | reproduction, cause racine, correction minimale, test de non-régression, check. Trois tentatives sans progrès → diagnostic et arrêt. |
| `/horn-dev:review` | `/horn-dev:review` · `/horn-dev:review src/export.ts` | relecture en contexte séparé, exige des preuves (rapport récent), verdict. Ne corrige rien. |
| `/horn-dev:release` | `/horn-dev:release` | vérification complète puis `commands.package` du projet ; compte rendu avec installation et retour arrière. Jamais de publication ni de push. |
| `/horn-dev:resume` | `/horn-dev:resume` | compare STATUS, fiches, Git et dernier rapport ; propose une seule prochaine action. |
| `/horn-dev:init` | `/horn-dev:init` | préparation légère, idempotente, avec validation. |

`init` et `release` ne peuvent être lancés que par vous. `check`, `review`, `resume` ne déclenchent jamais de développement.

## Équivalents terminal (sans Claude)

Chemin du plugin installé : `~/.claude/plugins/cache/horn-toolbox/horn-dev/<version>/scripts/` (ou le source : `plugins/horn-dev/scripts/`).

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <scripts>\horn-check.ps1 -ProjectDir C:\chemin\projet -Profile quick
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <scripts>\horn-init.ps1 -ProjectDir C:\chemin\projet
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <scripts>\horn-doctor.ps1 -ProjectDir C:\chemin\projet
```

Codes de sortie : 0 succès · 1 échec · 2 non vérifié · 3 usage · 4 non approuvé · 5 non initialisé.

## Lire un échec

1. Dernière ligne de `/horn-dev:check` : SUCCÈS, ÉCHEC ou NON VÉRIFIÉ.
2. Rapport `reports/dev/check-<profil>-<date>.md` du projet : tableau des contrôles.
3. Journal du contrôle dans `reports/dev/logs/<date>/<contrôle>.log` : message exact.
4. `/horn-dev:bugfix <message>`. Ne jamais modifier un test pour le faire passer.

## Ce qui reste propre à chaque projet

Dépendances (npm, Python, Cargo…), moteurs de tests, plugins de langage, connexions à des services, CI, avancement et rapports. horn-dev les lit via `.horn-dev.json` ; il ne les installe ni ne les partage.
