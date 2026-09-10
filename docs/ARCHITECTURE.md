# Architecture

## Trois niveaux

```
A. Ce dépôt (source versionné)        B. Mon environnement Claude Code          C. Chaque projet
   .claude-plugin/marketplace.json  →    marketplace « horn-toolbox » (user)   →    .horn-dev.json
   plugins/horn-dev/                →    plugin horn-dev@horn-toolbox (user,        docs/…/STATUS.md, fiches
   tests/, docs/                         copie dans ~/.claude/plugins/cache)        rapports (hors Git)
                                         superpowers (user), find-docs (user)       dépendances, tests, LSP du projet
                                         ~/.horn-dev/approved-projects.json         CLAUDE.md du projet (+ section horn-dev)
```

- **A** contient la méthode et ses tests. Il ne contient aucun code ni aucune donnée de projet.
- **B** est une **copie** installée : modifier A ne change rien dans B tant que la version n'est pas bumpée et le plugin mis à jour (`docs/INSTALL.md`).
- **C** garde tout ce qui est propre au projet : technologies et versions, commandes, contrôles obligatoires, limites, avancement, rapports, dépendances. Rien de cela n'est stocké dans A ni dans B.

## Identification du projet cible

Chaque skill agit sur `${CLAUDE_PROJECT_DIR}` (le dossier ou worktree ouvert dans la session) et passe ce dossier explicitement aux scripts (`-ProjectDir`). Les scripts refusent : un `-ProjectDir` absent (code 3), le dossier du plugin comme cible (code 3), un projet sans `.horn-dev.json` (code 5, audit lecture seule affiché), un projet non approuvé (code 4).

L'**approbation** est une liste locale de chemins dans `%USERPROFILE%\.horn-dev\approved-projects.json` (redirigeable via `HORN_DEV_HOME`). Elle est écrite par `horn-init.ps1 -Approve` après validation par l'utilisateur. Sans elle, aucune commande lue dans un fichier de configuration n'est exécutée : ouvrir un dépôt inconnu ne suffit pas à lancer ses commandes.

## Ce que le plugin ne fait jamais

- écrire dans son propre dossier (vérifié par `tests/horn-dev-scripts.test.ts`) ;
- écrire dans un projet autre que la cible ;
- stocker un chemin absolu de cette machine, un secret, un rapport ou l'avancement d'un projet ;
- installer une dépendance de développement dans un projet ;
- ajouter un hook global : horn-dev ne déclare **aucun hook**. Les seules automatisations sont celles des plugins tiers (Superpowers : hook `SessionStart` qui charge sa méthode).
- accorder une permission générale : les `allowed-tools` des skills se limitent aux scripts du plugin et à `git status`/`git diff`, le temps d'un tour.

## Statuts et codes de sortie

RÉUSSI · ÉCHOUÉ · NON EXÉCUTÉ · NON APPLICABLE. Un contrôle obligatoire NON EXÉCUTÉ empêche le verdict SUCCÈS. Codes : 0 succès · 1 échec · 2 non vérifié · 3 usage · 4 non approuvé · 5 non initialisé · 6 (package) aucune commande déclarée.

## Réutilisation de Superpowers et Context7

Superpowers est installé une fois en portée utilisateur et invoqué par ses noms réels (`references/superpowers.md` dans le plugin). Context7 est installé une fois en portée utilisateur (skill `find-docs`, règle `context7.md`, jeton dans `~/.config/context7/`). Les plugins de langage (typescript-lsp, pyright-lsp…) restent par projet : `/horn-dev:init` les suggère avec la commande exacte, sans les installer.

## Point d'entrée et preuves (0.2.0)

`/horn-dev:dev` classe l'intention (implémenter, corriger, analyser, relire, vérifier), dimensionne le parcours et applique la grille `references/verification-grid.md`. Analyser, relire et vérifier n'autorisent jamais la modification du produit. Chaque rapport de `horn-check` porte `treeFingerprint`, l'empreinte de l'état exact du code vérifié (`horn-fingerprint.ps1`) : une modification ultérieure périme les preuves. Un exécutable introuvable rend le contrôle NON EXÉCUTÉ, pas ÉCHOUÉ.
