---
name: release
description: Préparer et vérifier une version locale distribuable du projet courant — état du dépôt, vérification complète, commande de construction déclarée par le projet, compte rendu avec installation et retour arrière. Réservé à l'invocation explicite de l'utilisateur. Ne publie, ne pousse, ne signe et ne déploie jamais.
argument-hint: "[version cible facultative]"
disable-model-invocation: true
---

# /horn-dev:release — préparer une version locale

**Projet cible** : `${CLAUDE_PROJECT_DIR}`. Nécessite `.horn-dev.json` avec une commande `commands.package` et un projet approuvé ; sinon expliquer et proposer `/horn-dev:init` ou l'ajout de la commande (par l'utilisateur).

**Entrée** : `$ARGUMENTS` = version cible facultative. Si elle diffère de la version déclarée par le projet (manifeste), ne pas la modifier soi-même : demander confirmation, puis appliquer avec la commande propre à la technologie (`npm version <x> --no-git-tag-version`, édition de `pyproject.toml`, `Cargo.toml`…).

## Actions

1. **État du projet** : `git status --short`, `git log --oneline -5`, lecture du STATUS déclaré (`paths.status`) : éléments incomplets ou bloqués. Signaler toute modification non validée : un paquet construit sur un arbre non commité ne correspond à aucun commit précis.
2. **Construction** :
   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/horn-package.ps1" -ProjectDir "${CLAUDE_PROJECT_DIR}"`
   Le script exécute d'abord la vérification complète (profil full) et s'arrête si elle n'est pas SUCCÈS, puis lance `commands.package` dans le projet et écrit `<paths.reports>/release-<horodatage>.md`. Ne jamais utiliser `-SkipChecks` sans demande explicite de l'utilisateur ; le mentionner alors dans le compte rendu.
3. **Lecture des résultats** : ouvrir `check-latest.json` et le compte rendu de release ; identifier l'artefact produit (chemin, empreinte si le projet en produit une).
4. **Documentation** : compléter STATUS (section « Dernière version préparée ») : version, commit, date, verdict, limites connues. Proposer l'entrée de CHANGELOG si le projet en tient un.

## Sorties

Artefact produit (chemin), commit et branche, verdict de la vérification complète (rapport), procédure d'installation et de retour arrière adaptée à la technologie, et **ce qui n'a pas été validé** (interface, environnement cible, données réelles, tests manuels).

## Limites et conditions d'arrêt

- Interdits absolus : publication (`npm publish`, `cargo publish`, `twine upload`…), `git push`, tag distant, signature avec des secrets, déploiement, modification de données réelles.
- Une compilation réussie ne suffit pas à déclarer la version validée : le dire et lister les validations manuelles restantes.
- S'arrêter sans artefact si la vérification complète renvoie 1 ou 2 ; proposer `/horn-dev:bugfix` ou `/horn-dev:check full`.
