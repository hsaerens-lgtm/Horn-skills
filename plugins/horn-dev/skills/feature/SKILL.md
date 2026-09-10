---
name: feature
description: Implémenter une fonctionnalité ou une évolution dans le projet courant, avec un parcours proportionné à la taille du changement — comprendre, évaluer les impacts, intervenir avec tests, vérifier, rendre compte avec preuves. Utiliser quand l'utilisateur demande d'ajouter ou de changer un comportement du produit. Pour une demande dont la nature est incertaine, préférer /horn-dev:dev.
argument-hint: "[description du besoin]"
---

# /horn-dev:feature — implémenter une fonctionnalité

**Projet cible** : `${CLAUDE_PROJECT_DIR}`. Sans `.horn-dev.json`, proposer `/horn-dev:init` (invoqué par l'utilisateur) et n'exécuter aucune commande du projet.

**Entrée** : `$ARGUMENTS` = le besoin. Vide → demander une phrase et s'arrêter.

L'utilisateur pilote le produit ; tu prends en charge la technique. Ne recommence pas le cadrage : reformule le besoin en une phrase, questionne un choix seulement si un risque technique concret le justifie (avec recommandation), puis avance.

## Dimensionner (grille section 1 : `${CLAUDE_PLUGIN_ROOT}/references/verification-grid.md`)

- **Petit** (libellé, valeur, option triviale) : lire → modifier → `/horn-dev:check` quick → diff → compte rendu court. Ni fiche, ni plan, ni sous-agent.
- **Moyen** (nouvelle fonction, option, changement dans un composant) : parcours A à E ci-dessous. Fiche seulement si la tâche dépasse la session.
- **Grand** (nouveau composant, contrat ou format modifié, plusieurs composants, données ou accès) : cadrage bref si un point est vraiment ambigu (`superpowers:brainstorming`), fiche `<paths.tasks>/<AAAA-MM-JJ>-<slug>.md` depuis `TEMPLATE.md`, plan (`superpowers:writing-plans`), puis A à E avec `check full` et revue séparée.

## Parcours

A. **Comprendre** : instructions du projet, `.horn-dev.json`, code concerné et ses usages (serveur de langage, sinon Grep), `git status --short`, échecs déjà présents (`check-latest.json`). Résultat observable attendu écrit en une phrase.
B. **Évaluer les impacts** : composants touchés ; grille section 2 → vérifications nécessaires, nommées avant de coder. Risque hors périmètre → signalé, proposé à part.
C. **Intervenir** : changement limité, conventions existantes, pas de dépendance nouvelle si une capacité existante convient, pas de renommage ni reformatage hors demande. Existant non testé → d'abord des tests qui décrivent le comportement à préserver. Nouveau code → `superpowers:test-driven-development` si disponible. Bibliothèques → version installée puis `/find-docs`.
D. **Vérifier** : `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/horn-check.ps1" -ProjectDir "${CLAUDE_PROJECT_DIR}" -Profile quick` (ou `full`). Relire `git diff` : erreurs, oublis, hors périmètre. Revue séparée (`/horn-dev:review`) si domaine sensible ou taille grande. Toute modification après le rapport → relancer (empreinte `treeFingerprint`).
E. **Rendre compte** : résultat · vérifications exécutées (statuts et chemin du rapport) · limites et risques · décision attendue de l'utilisateur, seulement si nécessaire. Mettre à jour STATUS pour un changement moyen ou grand.

## Limites et conditions d'arrêt

- Ne pas pousser, publier ni préparer de version : `/horn-dev:release` est réservé à l'utilisateur.
- Ne jamais affaiblir un test ni masquer un problème (exception silencieuse, délai arbitraire, validation supprimée).
- Demander l'accord avant : réécriture importante, nouvelle dépendance, API facturée, migration, opération destructive.
- Trois cycles sans progrès sur un même test → `superpowers:systematic-debugging` ou arrêt avec diagnostic.
- Sans Superpowers, Context7 ou serveur de langage : suivre `${CLAUDE_PLUGIN_ROOT}/references/workflow.md` et le signaler.
