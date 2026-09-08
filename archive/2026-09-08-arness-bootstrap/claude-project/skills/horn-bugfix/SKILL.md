---
name: horn-bugfix
description: Investiguer et corriger un bug d'Arness de façon méthodique — reproduction, hypothèse vérifiable, cause racine, correction minimale et test de non-régression. Utiliser quand l'utilisateur signale un comportement incorrect, une erreur, un plantage ou un test qui échoue.
argument-hint: [description du problème]
---

# /horn-bugfix — investiguer et corriger un bug

**Entrée attendue** : `$ARGUMENTS` = description du problème (symptôme, étapes, message d'erreur, fichier ou test concerné). Si elle est vide, demander le symptôme observé et le résultat attendu, puis s'arrêter.

**Prérequis** : dépendances installées, `npm test` exécutable. Noter l'état Git initial (`git status --short`) pour ne pas confondre le bug avec des modifications en cours.

## Actions

1. **Reproduire** : écrire ou lancer le test, la commande ou le scénario qui montre le problème (`npm test`, `npm run dev`, `node dist/index.js`). Si la reproduction est impossible, expliquer précisément ce qui l'empêche (donnée manquante, service externe, interface) et proposer le plus petit substitut fiable.
2. **Investiguer** : invoquer `superpowers:systematic-debugging`. Formuler une hypothèse vérifiable (« si X, alors Y »), la tester avec des traces ou un test ciblé, et noter le résultat dans la fiche de tâche (`docs/development/tasks/`, modèle `TEMPLATE.md`).
3. **Comprendre** : utiliser le serveur de langage TypeScript (références, définitions) pour identifier la cause racine et les autres appelants touchés. Pour un comportement de bibliothèque, vérifier la version installée puis `/find-docs`.
4. **Corriger** : appliquer la correction la plus petite qui traite la cause, pas le symptôme. Ajouter un test de non-régression qui échoue sans la correction et réussit avec.
5. **Vérifier** : lancer `npm run check` (profil rapide). Puis `superpowers:verification-before-completion`.
6. **Conclure** : mettre à jour la fiche et `docs/development/STATUS.md`.

## Sorties

Compte rendu : cause racine (une phrase), fichiers modifiés, test de non-régression ajouté, verdict de la vérification (chemin du rapport), effets de bord possibles et ce qui n'a pas pu être vérifié.

## Limites et conditions d'arrêt

- Ne pas enchaîner des corrections au hasard. **Après trois tentatives sans progrès démontré** (le test cible échoue toujours ou un autre casse), arrêter toute modification, remettre le code dans l'état de la dernière tentative cohérente et fournir un diagnostic structuré : symptôme, hypothèses testées et résultats, zones suspectes, informations manquantes, prochaine expérience proposée.
- Ne pas supprimer ni affaiblir un test pour faire disparaître l'échec.
- Ne pas refondre l'architecture : si la correction exige une refonte, la décrire et laisser l'utilisateur décider.
