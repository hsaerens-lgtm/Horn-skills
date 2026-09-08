---
name: init
description: Analyser et préparer le projet courant pour la boîte à outils horn-dev — audit lecture seule, proposition d'un fichier .horn-dev.json (commandes, contrôles, limites), création des fichiers de suivi absents, approbation locale du projet. Réservé à l'invocation explicite de l'utilisateur.
argument-hint: "[dossier cible facultatif, sinon le projet courant]"
disable-model-invocation: true
---

# /horn-dev:init — préparer le projet courant

**Projet cible** : `$ARGUMENTS` s'il est fourni, sinon le projet de la session : `${CLAUDE_PROJECT_DIR}`. Ne jamais cibler le dossier du plugin (`${CLAUDE_PLUGIN_ROOT}`) ni un autre projet par déduction.

**Prérequis** : PowerShell (Windows PowerShell 5.1 ou PowerShell 7). Aucune dépendance n'est installée par ce skill.

## Actions

1. **Audit lecture seule** : exécuter l'aperçu (rien n'est écrit) :
   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/horn-init.ps1" -ProjectDir "<cible>"`
   puis lire les instructions existantes du projet (`CLAUDE.md`, `README`, `.claude/`), ses manifestes (`package.json`, `pyproject.toml`, `Cargo.toml`, `*.csproj`, `project.godot`…) et ses éventuels sous-projets. Le script ne détecte que les commandes réellement déclarées ; compléter à la main uniquement ce qui est prouvé par un fichier du projet, jamais inventé.
2. **Proposition** : présenter à l'utilisateur, en français et en clair : technologies et versions détectées, commandes de lancement, tests, compilation, contrôles proposés (obligatoires ou non), fichiers qui seraient créés ou complétés (`.horn-dev.json`, STATUS, modèle de fiche, `.gitleaks.toml`, section dans `CLAUDE.md`, ligne `.gitignore`), limites de validation connues. Si une commande de test manque, le dire et proposer d'en ajouter une plus tard via `/horn-dev:feature`, sans installer d'outil maintenant.
3. **Validation du périmètre** : demander l'accord de l'utilisateur (AskUserQuestion) sur la proposition et sur l'approbation du projet (autorisation d'exécuter ses commandes via `/horn-dev:check`). Adapter la proposition selon ses réponses (par exemple retirer un contrôle, changer les chemins).
4. **Application** : après accord seulement :
   `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/horn-init.ps1" -ProjectDir "<cible>" -Apply -Approve`
   puis, si l'utilisateur a demandé des ajustements, éditer `.horn-dev.json` dans le projet (schéma : `${CLAUDE_PLUGIN_ROOT}/references/config-schema.md`). Compléter la section « Résumé » de STATUS.md avec les faits établis (technologie, versions, composants, limites).
5. **Contrôle** : proposer `/horn-dev:check` pour vérifier que les commandes déclarées fonctionnent. Ne pas le lancer sans accord si le projet vient d'être approuvé.
6. **Plugins de langage** : si un plugin de code intelligence officiel correspond à la technologie (typescript-lsp, pyright-lsp, rust-analyzer-lsp…), l'indiquer avec la commande exacte (`claude plugin install <plugin>@claude-plugins-official --scope project`) et le binaire requis, sans l'installer.

## Sorties

Liste des fichiers créés, complétés ou déjà existants (le script les nomme CRÉÉ / COMPLÉTÉ / EXISTANT), état d'approbation, commandes retenues, et ce qui reste à définir manuellement.

## Limites et conditions d'arrêt

- Idempotent : une deuxième exécution ne duplique rien et n'écrase aucune adaptation manuelle (le script conserve les fichiers existants).
- Aucune modification fonctionnelle de l'application, aucune installation de dépendance, aucune commande du projet exécutée avant approbation.
- Si le dossier contient plusieurs sous-projets, proposer un `.horn-dev.json` par sous-projet à initialiser séparément ; ne pas transformer le dépôt en monorepo.
- S'arrêter si la technologie n'est pas identifiable : livrer l'audit et demander à l'utilisateur les commandes réelles.
