# Utiliser horn-dev dans un projet

## Répartition des rôles

Vous pilotez le produit, les priorités et l'expérience utilisateur. horn-dev prend en charge la technique : écrire et corriger le code, tester, sécuriser, gérer données et compatibilité, mesurer les performances, compiler et diagnostiquer, intégrer services et comportements IA. Vous n'avez pas à savoir quel spécialiste ou quel test demander : décrivez le besoin.

## Ouvrir un projet et démarrer

1. Ouvrir Claude Code dans le dossier du projet (ce dossier est la cible ; horn-dev ne devine jamais un autre dossier).
2. Première fois : `/horn-dev:init`. Audit en lecture seule, proposition d'un `.horn-dev.json` déduit des fichiers du projet, liste des fichiers à créer, puis votre accord et l'approbation du projet.
3. Ensuite, à chaque session : `/horn-dev:resume`.

Sans init, seules les lectures sont possibles.

## Le point d'entrée : `/horn-dev:dev`

Écrivez la demande en langage courant. Claude annonce d'abord l'intention qu'il a comprise et la taille du travail, puis agit en conséquence :

| Vous écrivez | Intention comprise | Claude peut modifier le code ? |
|---|---|---|
| « ajoute un export CSV » · « fais que le bouton… » | implémenter | oui |
| « ça plante quand… » · « corrige… » | corriger | oui |
| « analyse pourquoi… » · « explique… » | analyser | **non** : diagnostic, puis il vous demande |
| « relis… » · « qu'en penses-tu ? » | relire | **non** |
| « vérifie » · « lance les tests » | vérifier | **non** |

Taille : **petit** (libellé, valeur, erreur évidente) → modification directe, contrôles, compte rendu court ; **moyen** → comprendre, impacts, tests, contrôles, diff relu ; **grand** (nouveau composant, données, accès, plusieurs composants) → cadrage bref, fiche, plan, tests, contrôles complets, revue séparée.

Selon les parties touchées, Claude ajoute des vérifications que vous n'avez pas demandées (fichiers et bases : relecture des anciennes données et retour arrière ; accès : cas autorisés et interdits ; asynchrone : délais et annulation ; interface : états ; packaging : démarrage de la version compilée…). La grille complète est dans le plugin (`references/verification-grid.md`).

Le classement de l'intention repose sur des instructions : il fonctionne pour les formulations courantes mais n'est pas garanti. En cas de doute, utilisez directement la commande spécialisée.

## Les commandes spécialisées

| Commande | Exemple | Ce qui se passe |
|---|---|---|
| `/horn-dev:feature` | `/horn-dev:feature Exporter la liste en CSV` | parcours proportionné : comprendre, impacts, intervenir avec tests, vérifier, rendre compte |
| `/horn-dev:bugfix` | `/horn-dev:bugfix L'export CSV perd les accents` | reproduction, cause racine, correction ciblée, test de non-régression (rouge puis vert), voisins vérifiés. Trois tentatives sans progrès → diagnostic et arrêt |
| `/horn-dev:check` | `/horn-dev:check` · `/horn-dev:check full` | exécute les contrôles de `.horn-dev.json`, écrit le rapport, restitue RÉUSSI / ÉCHOUÉ / NON EXÉCUTÉ / NON APPLICABLE. Ne modifie rien |
| `/horn-dev:review` | `/horn-dev:review` · `/horn-dev:review src/export.ts sécurité` | relecture séparée, preuves confrontées à l'empreinte du code, défauts avec gravité et emplacement. Ne corrige rien |
| `/horn-dev:release` | `/horn-dev:release` | vérification complète puis construction locale ; jamais de publication ni de push |
| `/horn-dev:resume` | `/horn-dev:resume` | état réel vs STATUS, prochaine action |
| `/horn-dev:init` | `/horn-dev:init` | préparation légère, idempotente, avec votre accord |

`init` et `release` ne peuvent être lancés que par vous. `check`, `review`, `resume` et l'intention « analyser » ne modifient jamais le produit.

## Lire un compte rendu

Format habituel : **résultat obtenu** · **vérifications réellement exécutées** (statuts, chemin du rapport) · **limites ou risques restants** · **décision attendue de vous**, seulement si nécessaire.

Chaque rapport porte une **empreinte du code vérifié** (`treeFingerprint`). Si le code change ensuite, les preuves sont périmées et les contrôles doivent être relancés ; `/horn-dev:review` le détecte.

Ne confondez pas : code modifié · compilation réussie · tests réussis · application réellement lancée · version distribuable validée. Un compte rendu qui affirme « tout est sécurisé » ou « optimisé » sans mesure ni test est à refuser.

## Équivalents terminal (sans Claude)

Chemin des scripts : plugin installé `~/.claude/plugins/cache/horn-toolbox/horn-dev/<version>/scripts/` ou source `plugins/horn-dev/scripts/`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <scripts>\horn-check.ps1 -ProjectDir C:\chemin\projet -Profile quick
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <scripts>\horn-fingerprint.ps1 -ProjectDir C:\chemin\projet
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File <scripts>\horn-doctor.ps1 -ProjectDir C:\chemin\projet
```

Codes de sortie : 0 succès · 1 échec · 2 non vérifié · 3 usage · 4 non approuvé · 5 non initialisé.

## Lire un échec

1. Dernière ligne de `/horn-dev:check` : SUCCÈS, ÉCHEC ou NON VÉRIFIÉ.
2. Rapport `reports/dev/check-<profil>-<date>.md` : tableau des contrôles. Un « NON EXÉCUTÉ, exécutable introuvable » signifie qu'un outil du projet manque.
3. Journal du contrôle dans `reports/dev/logs/<date>/`.
4. `/horn-dev:bugfix <message>` ou `/horn-dev:dev corrige …`. On ne modifie jamais un test pour le faire passer.

## Ce qui reste propre à chaque projet

Dépendances, moteurs de tests, plugins de langage, connexions à des services, CI, avancement, rapports et décisions. horn-dev les lit via `.horn-dev.json` ; il ne les installe ni ne les partage. Aucun chemin de votre application ne devient une valeur globale.
