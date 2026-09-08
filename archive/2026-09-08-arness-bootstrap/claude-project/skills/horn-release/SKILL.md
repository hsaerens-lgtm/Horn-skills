---
name: horn-release
description: Préparer une version locale distribuable d'Arness — état du dépôt, vérification complète, compilation, archive npm .tgz avec empreinte, notice d'installation et de retour arrière. Réservé à l'invocation explicite de l'utilisateur. Ne publie, ne pousse, ne signe et ne déploie jamais.
argument-hint: [version cible facultative, ex. 0.2.0]
disable-model-invocation: true
---

# /horn-release — préparer une version locale

**Entrée attendue** : `$ARGUMENTS` = version cible facultative. Si elle diffère de `package.json`, ne pas la modifier soi-même : demander confirmation à l'utilisateur, puis utiliser `npm version <x.y.z> --no-git-tag-version` seulement après son accord.

**Prérequis** : dépôt Git présent, dépendances installées, Gitleaks disponible (sinon la vérification complète sera NON VÉRIFIÉE et le paquet ne doit pas être présenté comme validé).

## Actions

1. **État du projet** : `git status --short`, `git log --oneline -5`, lecture de `docs/development/STATUS.md` (éléments incomplets ou bloqués). Signaler toute modification non validée : un paquet construit sur un arbre non commité ne correspond à aucun commit précis.
2. **Construction** : lancer `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/package.ps1`. Ce script exécute la vérification complète (`check.ps1 -Profile full`), s'arrête si elle n'est pas RÉUSSIE, recompile `dist/`, produit `dist-packages/arness-<version>.tgz`, son `.sha256` et `INSTALL-<version>.md`. Ne jamais utiliser `-SkipChecks` sans demande explicite de l'utilisateur, et le mentionner alors dans le compte rendu.
3. **Lecture des résultats** : ouvrir `reports/dev/check-latest.json` et la notice produite. Vérifier que la version affichée par `node dist/index.js --version` correspond à `package.json`.
4. **Documentation** : compléter `docs/development/STATUS.md` (section « Dernière version préparée ») avec version, commit, date, verdict de vérification et limites connues. Si un fichier `CHANGELOG.md` existe, y proposer l'entrée ; sinon résumer les changements depuis la version précédente dans le compte rendu.

## Sorties

Compte rendu : chemin de l'archive et son SHA-256, commit et branche, verdict de la vérification complète (chemin du rapport), procédure d'installation et de retour arrière (extraites de la notice), et **ce qui n'a pas été validé** (interface, environnement cible, données réelles, tests manuels).

## Limites et conditions d'arrêt

- Interdits absolus : `npm publish`, `git push`, création de tag distant, signature avec des secrets, déploiement, modification de données réelles.
- Une compilation réussie et un paquet produit ne suffisent pas à déclarer la version validée : le dire explicitement et lister les validations manuelles restantes.
- S'arrêter sans produire de paquet si un contrôle obligatoire est ÉCHOUÉ ou NON EXÉCUTÉ (codes de sortie 1 ou 2 du script) ; proposer `/horn-bugfix` ou `/horn-check full`.
