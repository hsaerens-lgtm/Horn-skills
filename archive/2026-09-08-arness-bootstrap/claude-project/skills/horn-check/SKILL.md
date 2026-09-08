---
name: horn-check
description: Vérifier Arness sans modifier le code du produit — typage, tests, compilation, lancement de la version compilée et recherche de secrets via scripts/dev/check.ps1. Utiliser pour « lance les tests », « vérifie le projet », « est-ce que tout passe », ou avant de conclure un travail. Ne déclenche pas de développement.
argument-hint: [quick|full] [fichiers ou périmètre]
allowed-tools: Bash(powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/check.ps1 *) Bash(npm test *) Bash(npm run typecheck *) Bash(npx vitest run *) Bash(git status *) Bash(git diff *) Read Grep Glob
disallowed-tools: Edit Write NotebookEdit
---

# /horn-check — vérifier sans modifier

**Entrée attendue** : `$ARGUMENTS` = profil (`quick` par défaut, `full` pour une préparation de livraison) et, facultativement, un périmètre (fichiers de test, dossier). Sans argument : profil rapide sur tout le projet.

**Prérequis** : `node_modules/` présent. Gitleaks installé (sinon le contrôle « secrets » sera NON EXÉCUTÉ et le verdict global ne pourra pas être SUCCÈS).

## Actions

1. Lancer le contrôle de référence :
   - profil rapide : `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/check.ps1 -Profile quick`
   - profil complet : `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dev/check.ps1 -Profile full`
   - périmètre ciblé (en complément, jamais à la place) : `npx vitest run <fichiers>`.
2. Lire le rapport produit (`reports/dev/check-latest.json` et le `.md` horodaté) et, pour chaque contrôle ÉCHOUÉ ou NON EXÉCUTÉ, ouvrir le journal indiqué et extraire la cause (message d'erreur, test, fichier, ligne).
3. Restituer les statuts tels quels : RÉUSSI, ÉCHOUÉ, NON EXÉCUTÉ, NON APPLICABLE. Le code de sortie fait foi : 0 succès, 1 échec, 2 non vérifié, 3 usage.

## Sorties

Tableau des contrôles avec statut, puis pour chaque problème : emplacement, message, cause probable et **proposition** de correction (sans l'appliquer). Rappeler le chemin du rapport et que les sorties Gitleaks sont masquées.

## Limites et conditions d'arrêt

- Mode strictement non modifiant : aucune correction automatique, aucun reformatage, aucune mise à jour de snapshot ou de résultat attendu. Les seuls fichiers écrits sont les rapports dans `reports/dev/` (générés par le script, hors Git).
- Ne pas invoquer `/horn-feature`, `/horn-bugfix` ni `/horn-release`. Si l'utilisateur veut corriger, lui proposer `/horn-bugfix <problème>`.
- Un scan de secrets réussi n'est pas un audit de sécurité complet ; un test unitaire réussi ne valide ni une interface ni un service réel.
