---
name: horn-resume
description: Reprendre une session de travail sur Arness — comparer docs/development/STATUS.md avec l'état réel du dépôt, les changements en cours et le dernier rapport de vérification, puis proposer la prochaine action sûre. Utiliser en début de session ou après une interruption. Ne modifie rien et n'installe rien.
disallowed-tools: Edit Write NotebookEdit
---

# /horn-resume — reprendre le contexte

## État réel (capturé à l'invocation)

Git :
```!
git status --short --branch
git log --oneline -8 2>/dev/null || echo "(aucun commit)"
```

Dernier rapport de vérification (`reports/dev/check-latest.json`) :
```!
cat reports/dev/check-latest.json 2>/dev/null | head -40 || echo "(aucun rapport)"
```

Fiches de tâches :
```!
ls docs/development/tasks 2>/dev/null || echo "(aucune fiche)"
```

## Actions

1. Lire `docs/development/STATUS.md` en entier, puis les fiches de tâches non terminées listées ci-dessus.
2. Comparer avec l'état réel : fichiers modifiés non mentionnés dans STATUS, tâches marquées terminées sans commit, rapport de vérification plus ancien que les derniers changements ou avec un verdict autre que SUCCÈS.
3. Signaler chaque écart entre la documentation et la réalité ; le code et le dépôt font foi.

## Sorties

Résumé en quatre blocs : **terminé** (avec preuve), **incomplet** (ce qui reste), **bloqué** (cause et ce qu'il faudrait), **prochaine action sûre** (une seule, exécutable sans risque : par exemple lancer `/horn-check`, finir une fiche, ou demander une décision à l'utilisateur). Mentionner si STATUS.md doit être mis à jour et proposer le texte.

## Limites et conditions d'arrêt

- Ne rien installer, ne rien modifier (ni produit, ni documentation) : ce skill est en lecture seule ; la mise à jour de STATUS.md se fait ensuite sur demande de l'utilisateur.
- Ne pas lancer de plan ni de développement : proposer `/horn-feature`, `/horn-bugfix` ou `/horn-check` selon le cas.
- Si le dépôt contient des modifications non validées non documentées, ne pas les interpréter comme des erreurs : demander à l'utilisateur ce qu'elles représentent.
