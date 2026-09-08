---
name: bugfix
description: Investiguer et corriger un bug du projet courant de façon méthodique — reproduction, hypothèse vérifiable, cause racine, correction minimale et test de non-régression. Utiliser quand l'utilisateur signale un comportement incorrect, une erreur, un plantage ou un test qui échoue.
argument-hint: "[description du problème]"
---

# /horn-dev:bugfix — investiguer et corriger un bug

**Projet cible** : `${CLAUDE_PROJECT_DIR}`. Sans `.horn-dev.json`, l'investigation reste possible en lecture (code, journaux fournis), mais aucune commande du projet n'est lancée avant `/horn-dev:init`.

**Entrée attendue** : `$ARGUMENTS` = symptôme, étapes, message d'erreur, fichier ou test concerné. Vide → demander symptôme observé et résultat attendu, puis s'arrêter.

## Actions

1. **Reproduire** : écrire ou lancer le test, la commande ou le scénario qui montre le problème, avec les commandes déclarées dans `.horn-dev.json`. Reproduction impossible → expliquer précisément ce qui l'empêche (donnée, service externe, interface) et proposer le plus petit substitut fiable.
2. **Investiguer** : `superpowers:systematic-debugging` si disponible. Hypothèse vérifiable (« si X alors Y »), test ciblé, résultat consigné dans une fiche (`paths.tasks`, modèle TEMPLATE.md).
3. **Comprendre** : serveur de langage (références, définitions) pour la cause racine et les autres appelants ; comportement de bibliothèque → version installée puis `/find-docs`.
4. **Corriger** : la plus petite correction qui traite la cause. Ajouter un test de non-régression qui échoue sans la correction et réussit avec.
5. **Vérifier** : `/horn-dev:check` (quick), puis `superpowers:verification-before-completion`.
6. **Conclure** : fiche et STATUS mis à jour.

## Sorties

Cause racine (une phrase), fichiers modifiés, test de non-régression, verdict de la vérification (rapport), effets de bord possibles, ce qui n'a pas pu être vérifié.

## Limites et conditions d'arrêt

- **Trois tentatives sans progrès démontré** → arrêter toute modification, revenir au dernier état cohérent (sans `git reset --hard`), et livrer un diagnostic structuré : symptôme, hypothèses testées et résultats, zones suspectes, informations manquantes, prochaine expérience.
- Ne jamais supprimer ni affaiblir un test pour faire disparaître l'échec.
- Pas de refonte : si la correction l'exige, la décrire et laisser l'utilisateur décider.
