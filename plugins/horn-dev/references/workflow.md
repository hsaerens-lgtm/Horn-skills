# Façon de travailler horn-dev

## Trois niveaux, strictement séparés

| Niveau | Contient | Ne contient jamais |
|---|---|---|
| Dépôt source de la boîte à outils | skills, scripts génériques, modèles, références, tests du dispositif | code ou données d'un projet utilisateur |
| Plugin installé (portée utilisateur, copie dans le cache Claude Code) | la version validée du plugin | avancement d'un projet, rapports, secrets, chemins propres à une machine |
| Chaque projet | `.horn-dev.json`, STATUS, fiches, rapports, dépendances et tests du produit | la méthode recopiée |

La liste des projets approuvés vit dans `%USERPROFILE%\.horn-dev\` (réglage local non partagé).

## Mode coordonné

```
/horn-dev:feature "besoin"
→ cadrage (superpowers:brainstorming si ambigu ; validation par l'utilisateur)
→ critères d'acceptation (fiche dans paths.tasks)
→ plan (superpowers:writing-plans)
→ implémentation et tests (superpowers:test-driven-development ; /find-docs pour les bibliothèques)
→ vérification (/horn-dev:check → horn-check.ps1 → rapport dans paths.reports)
→ relecture (/horn-dev:review, contexte séparé, exige des preuves)
→ conclusion (superpowers:verification-before-completion ; fiche + STATUS)
```

## Mode indépendant

| Besoin | Skill | Sans Claude |
|---|---|---|
| documentation | `/find-docs` | `npx ctx7@latest library <lib> "<question>"` |
| vérifier | `/horn-dev:check [quick|full]` | `horn-check.ps1 -ProjectDir <projet> -Profile quick` |
| relire | `/horn-dev:review` | `git diff` |
| investiguer | `/horn-dev:bugfix "…"` | commandes de test du projet |
| préparer une version | `/horn-dev:release` (utilisateur) | `horn-package.ps1 -ProjectDir <projet>` |
| reprendre | `/horn-dev:resume` | lire STATUS, `git status`, `check-latest.json` |
| préparer un projet | `/horn-dev:init` (utilisateur) | `horn-init.ps1 -ProjectDir <projet> [-Apply -Approve]` |
| diagnostiquer | — | `horn-doctor.ps1 [-ProjectDir <projet>]` |

Règles : `check`, `review` et `resume` n'appellent jamais `feature`, `bugfix`, `init` ni `release`. `init` et `release` ne sont invoqués que par l'utilisateur. L'étape de vérification est unique et partagée (`horn-check.ps1`).

## Statuts et codes

| Statut | Sens |
|---|---|
| RÉUSSI | exécuté, code 0 |
| ÉCHOUÉ | exécuté, code ≠ 0 ou sortie inattendue |
| NON EXÉCUTÉ | prévu mais impossible (outil absent, étape précédente échouée, commande vide) |
| NON APPLICABLE | sans objet pour ce projet (déclaré dans `.horn-dev.json`) |

Un contrôle obligatoire NON EXÉCUTÉ empêche le verdict SUCCÈS (code 2). C'est volontaire.

## Dégradation propre

- Sans Superpowers : suivre ce document ; le signaler dans le compte rendu.
- Sans Context7 : documentation officielle ; le signaler.
- Sans serveur de langage : Grep/Glob ; le signaler.
- Sans Gitleaks ou sans les outils du projet : NON EXÉCUTÉ, verdict NON VÉRIFIÉ, pas de livraison « validée ».

## Transfert entre étapes

Pas de mémoire implicite : une fiche par tâche importante (objectif, critères, périmètre, décisions, fichiers modifiés, état des tests, risques, blocages, prochaine action) et un STATUS à jour en fin de session. Un sous-agent reçoit le périmètre, la fiche et les preuves dans son prompt. Parallélisme initial limité.
