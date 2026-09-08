---
name: resume
description: Reprendre une session sur le projet courant — comparer son fichier STATUS avec l'état réel du dépôt, les changements en cours et le dernier rapport de vérification, puis proposer une seule prochaine action cohérente. Utiliser en début de session ou après une interruption. Ne modifie rien, n'installe rien, ne démarre aucune implémentation.
disallowed-tools: Edit Write NotebookEdit
---

# /horn-dev:resume — reprendre le contexte

**Projet cible** : `${CLAUDE_PROJECT_DIR}`.

## État réel capturé à l'invocation

Git :
```!
cd "${CLAUDE_PROJECT_DIR}" && (git status --short --branch 2>/dev/null || echo "(pas de dépôt Git)") && (git log --oneline -8 2>/dev/null || echo "(aucun commit)")
```

Configuration horn-dev :
```!
cd "${CLAUDE_PROJECT_DIR}" && (cat .horn-dev.json 2>/dev/null || echo "(projet non initialisé : .horn-dev.json absent)")
```

## Actions

1. Si `.horn-dev.json` est absent : audit lecture seule uniquement (manifestes, instructions, tests visibles) ; conclure par « projet non initialisé » et proposer `/horn-dev:init` (à invoquer par l'utilisateur). Ne rien exécuter.
2. Sinon : lire le STATUS déclaré (`paths.status`), les fiches non terminées dans `paths.tasks`, et `<paths.reports>/check-latest.json` s'il existe (date, commit, verdict).
3. Comparer avec l'état réel : fichiers modifiés non mentionnés, tâches marquées terminées sans commit, rapport plus ancien que les derniers changements ou verdict autre que SUCCÈS. Le code et le dépôt font foi ; signaler chaque écart.

## Sorties

Quatre blocs : **terminé** (avec preuve), **incomplet**, **bloqué** (cause, ce qu'il faudrait), **prochaine action sûre** (une seule : par exemple `/horn-dev:check`, finir une fiche, ou une décision à demander à l'utilisateur). Indiquer si STATUS doit être mis à jour et proposer le texte, sans l'écrire.

## Limites et conditions d'arrêt

- Lecture seule : aucune modification du produit ni de la documentation, aucune installation.
- Ne lance ni plan ni développement : orienter vers `/horn-dev:feature`, `/horn-dev:bugfix` ou `/horn-dev:check`.
- Modifications non validées non documentées → demander à l'utilisateur ce qu'elles représentent au lieu de les interpréter.
