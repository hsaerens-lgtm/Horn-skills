# Inventaire des capacités (au 2026-09-10)

Pour chaque capacité : où elle est installée, si elle est accessible dans une session Claude Code, si elle est configurée pour un projet, comment elle se déclenche, et ce qui la limite. « Vérifiée » signifie qu'un essai réel a été fait, pas seulement que le fichier existe.

## Capacités de horn-dev 0.2.0

| Capacité | Déclenchement | Installée | Accessible en session | Configurée pour un projet | Vérifiée par essai | Limites |
|---|---|---|---|---|---|---|
| Point d'entrée `dev` (classer, dimensionner, grille) | `/horn-dev:dev …` | oui (plugin user) | à confirmer dans une nouvelle session après mise à jour | via `.horn-dev.json` | format validé ; routage par instructions **non testé** avec Claude (voir TEST-PROTOCOL.md) | routage non garanti : les commandes spécialisées restent l'invocation fiable |
| Implémentation proportionnée (`feature`) | `/horn-dev:feature …` | oui | oui (0.1.0 constaté dans cette session) | idem | format validé ; comportement non testé | — |
| Diagnostic et correction (`bugfix`) | `/horn-dev:bugfix …` | oui | oui | idem | idem | arrêt après trois tentatives : règle d'instruction |
| Vérification sans modification (`check`) | `/horn-dev:check` ou `npm run check` | oui | oui | `.horn-dev.json` + approbation | **oui** : scripts testés (codes 0/1/2/3/4/5, isolation, idempotence), `npm run check` de ce dépôt SUCCÈS | ne valide ni interface ni service réel |
| Revue séparée avec preuves (`review`) | `/horn-dev:review [focus]` | oui | oui | idem | format validé ; sous-agent non exercé | contexte Explore : lecture seule |
| Reprise (`resume`) | `/horn-dev:resume` | oui | oui | idem | format validé | — |
| Adaptation légère (`init`) | `/horn-dev:init` (utilisateur) | oui | masqué au modèle, visible à l'utilisateur | — | **oui** : script testé (aperçu sans écriture, idempotence, approbation) | détection limitée aux manifestes reconnus |
| Version locale (`release`) | `/horn-dev:release` (utilisateur) | oui | idem | `commands.package` | script testé le 2026-09-08 sur ce dépôt (ancienne version) ; pas de scénario automatisé | jamais de publication |
| Preuves liées au code (`treeFingerprint`) | automatique dans chaque rapport ; `horn-fingerprint.ps1` | oui | via scripts | — | **oui** : test « empreinte change après modification, revient après restauration » | hors Git : contenu des fichiers < 5 Mo |
| Tests unitaires, bout en bout et CI (`testing`, 0.3.0) | `/horn-dev:testing explique|demo|setup` (utilisateur) ; `horn-testing-demo.ps1` ; `templates/testing-demo/` | oui | masqué au modèle, visible à l'utilisateur | par projet (dépendances installées après accord) | **oui** : démonstration exécutée le 2026-09-10 dans un dossier temporaire : Vitest 6 réussis + 1 échec volontaire, Playwright 4 réussis + 1 échec volontaire avec capture et trace ; après `demo:clean`, tout vert | Playwright seulement pour une interface web ; téléchargement de Chromium (~300 Mo) ; CI inactive sans dépôt distant |
| Outil indisponible → NON EXÉCUTÉ | automatique | oui | via scripts | — | **oui** : test « exécutable introuvable → code 2 » | détection par code 9009/127 et message |
| Recherche de secrets | dans `check` | Gitleaks 8.30.1 (WinGet, user) | via scripts | `.gitleaks.toml` | **oui** | un scan n'est pas un audit |
| Grille de vérifications par domaine | lue par `dev`, `feature`, `bugfix`, `review` | oui (`references/verification-grid.md`) | — | — | document ; application par Claude non testée | ne remplace pas une expertise |

## Capacités réutilisées (hors horn-dev)

| Capacité | Installée | Accessible en session | Vérifiée | Rôle dans horn-dev |
|---|---|---|---|---|
| Superpowers 6.3.0 | oui, portée user | **oui** : skill `verification-before-completion` chargé le 2026-09-10 (absent de la liste initiale de la session, mais invocable) | oui | méthode : brainstorming (grand seulement), plans, TDD, débogage, revue, vérification |
| Context7 (`find-docs`) | oui, portée user (`~/.claude/skills`, `~/.claude/rules`) | non listé dans cette session ; connecté (`whoami`) | oui le 2026-09-08 | documentation à la version installée |
| typescript-lsp | portée projet (ce dépôt) | non vérifié | non | navigation ; à installer par projet selon le langage |
| Gitleaks | user | via scripts | oui | secrets |

## Capacités absentes, évaluées

| Besoin | Option évaluée (source officielle consultée) | Coût / permissions | Décision |
|---|---|---|---|
| Revue de sécurité continue pendant que Claude écrit | plugin officiel `security-guidance@claude-plugins-official` : hooks `PostToolUse` (motifs, sans modèle), `Stop` (revue du diff par un appel modèle séparé), commit/push (revue agentique). Python ≥ 3.10 requis ; crée un venv dans `~/.claude/security/` ; ne bloque rien, ne modifie pas les fichiers | appels modèle supplémentaires à chaque tour qui modifie des fichiers ; 4 hooks globaux (SessionStart, UserPromptSubmit, PostToolUse, Stop) | **Installé le 2026-09-10 sur accord de l'utilisateur**, version 2.0.7, portée user (`claude plugin list`). Couche « motifs à l'édition » **vérifiée** : avertissement réel émis dans la session d'installation lors de l'écriture d'un fichier mentionnant `eval(`. Couches à appel modèle (fin de tour, commit) encore à observer en session projet (journal `~/.claude/security/log.txt`). Désactivation : `SECURITY_GUIDANCE_DISABLE=1` ou `claude plugin disable security-guidance@claude-plugins-official`. Règles projet : `.claude/claude-security-guidance.md` |
| Spécialistes par domaine (sécurité, performance, migrations, debug) | marketplace `wshobson/agents` : 94 plugins, 202 agents (ex. `security-scanning`, `comprehensive-review`, `error-diagnostics`, `tdd-workflows`, `application-performance`, `database-migrations`, `javascript-typescript`, `python-development`), MIT | chaque plugin ajoute agents et commandes en contexte ; modèles par tiers (Opus pour revue et sécurité) ; qualité et maintenance non vérifiées ici | **non installé** : la grille couvre les cas courants sans agent par ligne de checklist. À réévaluer pour un manque précis (par ex. `database-migrations` si une migration réelle arrive), un plugin à la fois, après lecture de sa source |
| Passe de sécurité ponctuelle | commande intégrée `/security-review` de Claude Code (branche courante) | un appel | à utiliser à la demande, déjà disponible |
| Tests d'interface | Playwright | dépendance projet | par projet, quand une interface existe |
| Évaluations de modèles IA | Promptfoo | dépendance projet, coût fournisseur | par projet, quand des prompts existent |

## Ce qui n'est pas vérifiable depuis la session d'installation

Les essais du comportement réel de Claude (routage de `dev`, déroulé de `feature` et `bugfix`, refus de modifier en analyse ou revue) exigent une session interactive : la CLI `claude -p` répond « Not logged in » sur ce poste. Le protocole manuel est dans `docs/TEST-PROTOCOL.md`.
