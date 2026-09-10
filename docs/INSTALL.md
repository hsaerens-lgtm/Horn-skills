# Installer, mettre à jour, revenir en arrière, désinstaller

Toutes les commandes s'exécutent dans un terminal (PowerShell ou Git Bash), pas dans une session Claude Code, sauf mention contraire. Remplacer `<source>` par le dossier de ce dépôt (ici `C:\Users\Horn S\Arness`, chemin propre à cet ordinateur).

## Installer la version validée (portée utilisateur)

```bash
claude plugin marketplace add "<source>"
```

```bash
claude plugin install horn-dev@horn-toolbox --scope user
```

Ce que cela écrit : `~/.claude/plugins/known_marketplaces.json` (marketplace `horn-toolbox` → chemin local), `~/.claude/plugins/installed_plugins.json`, une **copie** du plugin dans `~/.claude/plugins/cache/horn-toolbox/horn-dev/<version>/`, et `enabledPlugins` dans `~/.claude/settings.json`. Le dossier `.claude/` de vos projets n'est pas modifié.

Puis, dans chaque session déjà ouverte : `/reload-plugins` (ou redémarrer Claude Code). Les nouvelles sessions chargent le plugin automatiquement.

## Vérifier la version réellement chargée

```bash
claude plugin list
```

Doit afficher `horn-dev@horn-toolbox`, sa version et `Scope: user`. La version du source est dans `plugins/horn-dev/.claude-plugin/plugin.json`. Si elles diffèrent, la copie installée est en retard : voir « Mettre à jour ».

```bash
claude plugin details horn-dev@horn-toolbox
```

Liste les sept skills chargés. En session, `/horn-dev:` doit proposer `check`, `feature`, `bugfix`, `review`, `resume`, `init`, `release`.

## Mettre à jour depuis ce dépôt source

1. Modifier le plugin dans `plugins/horn-dev/`, puis `npm test` et `npm run validate`.
2. Augmenter `version` dans `plugins/horn-dev/.claude-plugin/plugin.json` (la version n'est déclarée qu'à cet endroit, jamais dans `marketplace.json`). Sans bump, `claude plugin update` ne recopie rien.
3. Committer.
4. Dans un terminal :

```bash
claude plugin marketplace update horn-toolbox
```

```bash
claude plugin update horn-dev@horn-toolbox --scope user
```

5. `/reload-plugins` dans les sessions ouvertes, puis `claude plugin list` pour confirmer la version.

Une modification du source **n'actualise jamais** la copie installée toute seule.

## Revenir à la version précédente

Deux options :

- **Depuis le source** : revenir au commit de la version voulue (`git log --oneline` puis `git checkout <commit> -- plugins/horn-dev`), remettre le `version` correspondant, committer, puis suivre « Mettre à jour ». Chaque version installée est aussi conservée dans `~/.claude/plugins/cache/horn-toolbox/horn-dev/<version>/` tant qu'elle n'est pas nettoyée.
- **Temporairement** : `claude --plugin-dir <source>/plugins/horn-dev` charge le source tel quel pour une seule session (utile pour tester avant bump). Ce n'est pas une installation.

## Désactiver / désinstaller (sans toucher aux projets)

```bash
claude plugin disable horn-dev@horn-toolbox --scope user
```

```bash
claude plugin uninstall horn-dev@horn-toolbox --scope user
```

```bash
claude plugin marketplace remove horn-toolbox
```

Les fichiers de vos projets (`.horn-dev.json`, STATUS, fiches, rapports) restent en place : ce sont des fichiers du projet. La liste d'approbations `%USERPROFILE%\.horn-dev\` peut être supprimée à la main si vous ne voulez plus rien garder.

## Refaire l'installation sur un autre ordinateur

1. Prérequis : Claude Code CLI, Git, Windows PowerShell 5.1 ou PowerShell 7 (sur macOS/Linux : `pwsh`). Optionnels : Gitleaks, Node/Python/… selon les projets.
2. Cloner ou copier ce dépôt (c'est le seul artefact nécessaire), puis « Installer » ci-dessus avec le nouveau chemin.
3. Outils partagés recommandés : `claude plugin install superpowers@claude-plugins-official --scope user` ; `claude plugin install security-guidance@claude-plugins-official --scope user` (Python ≥ 3.10 requis ; revue de sécurité automatique, appels modèle supplémentaires) ; `npx ctx7@latest setup --cli --claude` puis `npx ctx7@latest login` ; `winget install --id Gitleaks.Gitleaks --exact --scope user`.
4. Dans chaque projet : ouvrir Claude Code, `/horn-dev:init`, valider, puis `/horn-dev:check`.

Cette installation est locale à la machine. Elle ne se synchronise ni avec Claude Code sur le Web ni avec un autre poste : refaire les étapes là-bas.
