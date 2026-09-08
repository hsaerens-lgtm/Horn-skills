---
name: feature
description: Ajouter une fonctionnalité au projet courant de bout en bout — cadrage, critères d'acceptation, plan, implémentation par petits pas avec tests, vérification et relecture. Utiliser quand l'utilisateur demande une nouvelle fonctionnalité, une évolution ou un changement de comportement du produit.
argument-hint: "[description du besoin]"
---

# /horn-dev:feature — ajouter une fonctionnalité

**Projet cible** : `${CLAUDE_PROJECT_DIR}`. Vérifier qu'il contient `.horn-dev.json` ; sinon proposer `/horn-dev:init` (invoqué par l'utilisateur) et, en attendant, ne pas exécuter de commandes du projet.

**Entrée attendue** : `$ARGUMENTS` = description du besoin. Vide → demander une phrase et s'arrêter.

**Prérequis** : `git status --short` noté au départ ; les modifications préexistantes de l'utilisateur ne sont ni stashées ni mélangées au travail.

## Actions

1. **Contexte** : lire `.horn-dev.json` (commandes, contrôles, limites), le fichier STATUS déclaré dans `paths.status`, les fiches ouvertes dans `paths.tasks`, puis le code concerné (serveur de langage si disponible, sinon Grep/Glob et le signaler).
2. **Cadrage** : reformuler le besoin en une phrase ; lister des critères d'acceptation vérifiables et les composants touchés. Besoin ambigu ou choix produit important → invoquer `superpowers:brainstorming` (si Superpowers est disponible) puis faire valider par l'utilisateur (AskUserQuestion) avant de coder. Détail technique ordinaire → décider et l'expliquer en une ligne.
3. **Fiche** : créer `<paths.tasks>/<AAAA-MM-JJ>-<slug>.md` depuis `TEMPLATE.md` (ou `${CLAUDE_PLUGIN_ROOT}/templates/TASK.md` s'il manque).
4. **Plan** : plus d'un fichier ou plus d'une heure → `superpowers:writing-plans` ; sinon trois à six étapes dans la fiche.
5. **Documentation** : pour une API de bibliothèque, identifier la version installée (manifeste et lock du projet) puis `/find-docs` (Context7) ; sans Context7, documentation officielle et le dire.
6. **Implémentation** : `superpowers:test-driven-development` par petits incréments (rouge → vert → refactor). Ne jamais supprimer du code préexistant ; pour l'existant, d'abord des tests qui décrivent le comportement actuel.
7. **Vérification partagée** : `/horn-dev:check` (profil quick). Un échec se corrige ou se documente ; ne jamais affaiblir un test.
8. **Relecture** : `/horn-dev:review` (contexte séparé) ou `superpowers:requesting-code-review`. Traiter les points bloquants.
9. **Conclusion** : `superpowers:verification-before-completion` ; mettre à jour la fiche et STATUS.

## Sorties

Fonctionnalité livrée, tests ajoutés (fichiers, nombre), résultat de la relecture, verdict de `/horn-dev:check` (rapport dans `paths.reports`), et **limites de validation** (non vérifié : interface, données réelles, version compilée…).

## Limites et conditions d'arrêt

- Ne pas pousser, publier ni préparer de version : `/horn-dev:release` est réservé à l'utilisateur.
- S'arrêter et demander si : besoin ambigu après cadrage, dépendance nouvelle ou API facturée nécessaire, contrôle obligatoire impossible (le marquer NON VÉRIFIÉ).
- Trois cycles sans progrès sur un même test → passer à `superpowers:systematic-debugging` au lieu d'enchaîner des tentatives.
- Si Superpowers n'est pas disponible dans cette session, suivre les mêmes étapes avec `${CLAUDE_PLUGIN_ROOT}/references/workflow.md` et le signaler.
