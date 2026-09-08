---
name: check
description: Vérifier le projet courant sans modifier son code — exécute les contrôles déclarés dans .horn-dev.json (typage, tests, compilation, secrets…) via horn-check.ps1 et restitue les statuts RÉUSSI / ÉCHOUÉ / NON EXÉCUTÉ / NON APPLICABLE. Utiliser pour « lance les tests », « vérifie le projet », « est-ce que tout passe ». Ne déclenche aucun développement.
argument-hint: "[quick|full] [périmètre facultatif]"
allowed-tools: Bash(powershell -NoProfile -ExecutionPolicy Bypass -File ${CLAUDE_PLUGIN_ROOT}/scripts/horn-check.ps1 *) Bash(git status *) Bash(git diff *) Read Grep Glob
disallowed-tools: Edit Write NotebookEdit
---

# /horn-dev:check — vérifier sans modifier

**Projet cible** : `${CLAUDE_PROJECT_DIR}` (jamais le dossier du plugin). **Entrée** : `$ARGUMENTS` = profil `quick` (défaut) ou `full`, plus un périmètre facultatif (fichiers ou dossier à commenter en priorité).

## Actions

1. Lancer le contrôle de référence :
   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/horn-check.ps1" -ProjectDir "${CLAUDE_PROJECT_DIR}" -Profile <quick|full>`
2. Interpréter le code de sortie : 0 SUCCÈS · 1 ÉCHEC (contrôle obligatoire échoué) · 2 NON VÉRIFIÉ (contrôle obligatoire non exécuté) · 3 usage · 4 projet non approuvé · 5 projet non initialisé.
   - Code 5 : le script affiche un audit lecture seule (technologies, commandes déclarées). Le restituer et proposer `/horn-dev:init` à l'utilisateur. N'exécuter aucune commande du projet à la main.
   - Code 4 : expliquer que les commandes d'un fichier de configuration ne sont exécutées qu'après approbation explicite (`/horn-dev:init` puis `-Approve`). Ne pas contourner.
3. Lire le rapport (`<paths.reports>/check-latest.json` et le `.md` horodaté) ; pour chaque contrôle ÉCHOUÉ ou NON EXÉCUTÉ, ouvrir le journal indiqué et extraire la cause (message, test, fichier, ligne).
4. Si un périmètre est donné, commenter en priorité les résultats qui le concernent ; ne pas lancer de variante privée des contrôles.

## Sorties

Tableau des contrôles avec statut, puis pour chaque problème : emplacement, message, cause probable, **proposition** de correction (non appliquée). Rappeler le chemin du rapport et que les sorties Gitleaks sont masquées.

## Limites et conditions d'arrêt

- Aucune correction automatique, aucun reformatage, aucune mise à jour de snapshot ou de résultat attendu. Seuls les rapports du dossier `paths.reports` du projet sont écrits, par le script.
- Ne pas invoquer `/horn-dev:feature`, `/horn-dev:bugfix`, `/horn-dev:init` ni `/horn-dev:release`. Pour corriger, proposer `/horn-dev:bugfix <problème>`.
- Un scan de secrets réussi n'est pas un audit de sécurité ; un test simulé ne valide pas un service réel ; un test unitaire ne valide pas une interface.
