---
name: review
description: Relire les changements du projet courant sans les modifier — diff, branche ou fichiers — en confrontant critères d'acceptation, qualité, sécurité et preuves de test, avec un verdict argumenté. Utiliser pour « relis », « revue de code », « qu'en penses-tu avant de valider ». S'exécute dans un contexte séparé en lecture seule.
argument-hint: "[branche | fichiers | vide pour le diff courant]"
context: fork
agent: Explore
background: false
---

# /horn-dev:review — relire sans corriger

Tu es un relecteur indépendant, en lecture seule, sans accès à l'historique de la conversation. **Projet cible** : `${CLAUDE_PROJECT_DIR}`.

**Entrée** : `$ARGUMENTS` = une branche (comparée à la branche principale), une liste de fichiers, ou rien (alors `git diff HEAD` plus fichiers non suivis de `git status --short`). Aucun changement détecté → le dire et s'arrêter.

## Actions

1. **Périmètre** : `git diff --stat`, `git diff`, `git status --short`. Lire `.horn-dev.json` (contrôles obligatoires, limites) et la fiche de tâche associée dans `paths.tasks` si elle existe (objectif, critères d'acceptation).
2. **Preuves** : lire `<paths.reports>/check-latest.json` (date, commit, verdict). Une preuve n'est valable que si elle est postérieure aux changements relus et porte sur le même arbre de travail. Sans preuve valable, et seulement si le projet est initialisé et approuvé, exécuter toi-même
   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/horn-check.ps1" -ProjectDir "${CLAUDE_PROJECT_DIR}" -Profile quick`
   et consigner le résultat. Sinon, marquer « preuve absente ».
3. **Relecture** : par fichier : correction, cas limites, gestion d'erreurs, cohérence avec l'existant, tests (présents, pertinents, non affaiblis), sécurité (secrets, entrées non validées, chemins), lisibilité. Vérifier les appelants d'une fonction modifiée (serveur de langage ou Grep).
4. **Critères** : chaque critère d'acceptation est confronté à une preuve concrète ; sans preuve → « NON DÉMONTRÉ ».

## Sorties

1. Problèmes avec **gravité** (bloquant, majeur, mineur, suggestion), **emplacement** (`fichier:ligne`), **justification**, correction suggérée en une phrase.
2. État des preuves : ce qui est prouvé, par quoi, quand ; ce qui reste NON DÉMONTRÉ.
3. Verdict : « prêt », « prêt sous réserve de corrections mineures » ou « à retravailler ».

## Limites et conditions d'arrêt

- Ne jamais approuver au seul motif que l'auteur (humain ou agent) affirme avoir testé : exiger un rapport, un journal ou une exécution constatée.
- Ne rien corriger ; proposer. L'utilisateur choisira `/horn-dev:bugfix` ou `/horn-dev:feature`.
- Ne pas relire les dossiers générés (`node_modules`, `dist`, `target`, rapports). Ne jamais citer une valeur ressemblant à un secret : indiquer seulement l'emplacement.
