---
name: horn-feature
description: Ajouter une fonctionnalité à Arness de bout en bout — cadrage, critères d'acceptation, plan, implémentation par petits pas avec tests (TDD), revue et vérification. Utiliser quand l'utilisateur demande une nouvelle fonctionnalité, une évolution ou un changement de comportement du produit.
argument-hint: [description de la fonctionnalité]
---

# /horn-feature — ajouter une fonctionnalité

**Entrée attendue** : `$ARGUMENTS` = description de la fonctionnalité souhaitée. Si elle est vide, demander une phrase à l'utilisateur et s'arrêter.

**Prérequis** : dépendances installées (`node_modules/`), `npm run check` disponible. Vérifier rapidement avec `git status --short`; ne pas mélanger des modifications préexistantes de l'utilisateur avec ce travail (les laisser en place, ne rien stasher).

## Actions

1. **Contexte** : lire `docs/development/STATUS.md`, les fiches ouvertes dans `docs/development/tasks/`, puis le code concerné (utiliser le serveur de langage TypeScript pour les définitions et références ; à défaut Grep/Glob).
2. **Cadrage** : reformuler le besoin en une phrase, lister les critères d'acceptation vérifiables et les composants touchés. Si le besoin est ambigu ou implique un choix produit important, invoquer `superpowers:brainstorming` puis faire valider le besoin à l'utilisateur (AskUserQuestion) avant de coder. Pour un détail technique ordinaire, décider et expliquer en une ligne.
3. **Fiche de tâche** : créer `docs/development/tasks/<AAAA-MM-JJ>-<slug>.md` à partir de `TEMPLATE.md` (objectif, critères, périmètre, décisions).
4. **Plan** : pour tout changement touchant plus d'un fichier ou plus d'une heure de travail, invoquer `superpowers:writing-plans`. Sinon, écrire trois à six étapes dans la fiche.
5. **Documentation** : pour toute API de bibliothèque, identifier la version installée dans `package.json` puis utiliser `/find-docs` (Context7). Sans Context7, consulter la documentation officielle et le signaler.
6. **Implémentation** : appliquer `superpowers:test-driven-development` par petits incréments (test rouge → code → vert → refactor). Ne pas supprimer de code préexistant ; pour l'existant, ajouter d'abord des tests décrivant le comportement actuel.
7. **Vérification partagée** : lancer `npm run check` (profil rapide). Un échec se corrige ou se documente ; ne jamais assouplir un test.
8. **Revue** : invoquer `superpowers:requesting-code-review` ou `/horn-review` sur le diff produit. Traiter les problèmes bloquants avant de conclure.
9. **Conclusion** : appliquer `superpowers:verification-before-completion`. Mettre à jour la fiche (fichiers modifiés, état des tests, risques) et `docs/development/STATUS.md`.

## Sorties

Compte rendu contenant : la fonctionnalité livrée, les tests ajoutés (fichiers, nombre), le résultat de la revue, le verdict de `npm run check` (chemin du rapport dans `reports/dev/`), et les **limites de validation** (ce qui n'a pas pu être vérifié, par exemple interface, données réelles, version compilée).

## Limites et conditions d'arrêt

- Ne pas pousser, publier, ni préparer de version : c'est le rôle de `/horn-release`, invoqué uniquement par l'utilisateur.
- S'arrêter et demander si le besoin reste ambigu après cadrage, si la fonctionnalité exige une dépendance nouvelle ou une API facturée, ou si un contrôle obligatoire ne peut pas être exécuté (le signaler comme NON VÉRIFIÉ).
- Après trois cycles sans progrès sur un même test, passer en mode diagnostic (`superpowers:systematic-debugging`) plutôt que d'enchaîner des tentatives.
