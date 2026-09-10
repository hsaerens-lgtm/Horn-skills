---
name: bugfix
description: Diagnostiquer et corriger un bug du projet courant — reproduction, hypothèse vérifiable, cause racine, correction ciblée, test de non-régression, vérification des comportements voisins. Utiliser quand l'utilisateur signale un comportement incorrect, une erreur ou un test qui échoue et autorise la correction. Pour une simple analyse sans modification, préférer /horn-dev:dev « analyse … ».
argument-hint: "[description du problème]"
---

# /horn-dev:bugfix — diagnostiquer et corriger

**Projet cible** : `${CLAUDE_PROJECT_DIR}`. Sans `.horn-dev.json`, l'investigation reste possible en lecture, mais aucune commande du projet n'est lancée avant `/horn-dev:init`.

**Entrée** : `$ARGUMENTS` = symptôme, étapes, message d'erreur, fichier ou test concerné. Vide → demander symptôme observé et résultat attendu, puis s'arrêter.

## Dimensionner

Erreur évidente sur une ligne (faute de frappe, condition inversée visible) : corriger, ajouter ou adapter le test si un existe, `/horn-dev:check` quick, compte rendu court. Sinon, parcours complet ci-dessous. Fiche de tâche seulement si le diagnostic dépasse la session.

## Parcours

1. **Reproduire** : test, commande ou scénario qui montre le problème, avec les commandes déclarées dans `.horn-dev.json`. Impossible → dire précisément pourquoi (donnée, service, interface) et proposer le plus petit substitut fiable.
2. **Hypothèse** : `superpowers:systematic-debugging` si disponible. Formuler « si X alors Y », chercher l'élément qui confirme ou infirme (trace, test ciblé, lecture des appelants via serveur de langage ou Grep). Bibliothèque impliquée → version installée puis `/find-docs`.
3. **Impacts** : grille section 2 (`${CLAUDE_PLUGIN_ROOT}/references/verification-grid.md`) pour les domaines touchés par la cause (données, accès, asynchrone…).
4. **Corriger** : la plus petite correction de la cause, pas du symptôme. Test de non-régression qui échoue sans la correction et réussit avec (vérifier le rouge puis le vert).
5. **Vérifier** : `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/horn-check.ps1" -ProjectDir "${CLAUDE_PROJECT_DIR}" -Profile quick`, puis les comportements voisins identifiés à l'étape 3. Relire le diff. `superpowers:verification-before-completion` avant toute affirmation.
6. **Rendre compte** : cause racine (une phrase) · fichiers modifiés · test de non-régression (preuve rouge/vert) · verdict et chemin du rapport · effets de bord possibles · ce qui n'a pas pu être vérifié.

## Limites et conditions d'arrêt

- **Trois tentatives sans progrès démontré** → arrêter toute modification, revenir au dernier état cohérent (sans `git reset --hard`), livrer : symptôme, hypothèses testées et résultats, zones suspectes, informations manquantes, prochaine expérience.
- Ne jamais masquer : pas d'exception silencieuse, de délai arbitraire, de validation supprimée, de contrôle désactivé, de test affaibli.
- Pas de refonte : si la correction l'exige, la décrire et laisser l'utilisateur décider.
