# Superpowers et Context7 : réutilisation, pas recopie

## Superpowers (méthode principale)

Plugin `superpowers@claude-plugins-official` (source : https://github.com/obra/superpowers). Version constatée le 2026-09-08 : 6.3.0. horn-dev **n'en recopie aucun skill** : il les invoque par leur nom réel quand ils sont disponibles.

| Étape horn-dev | Skill Superpowers |
|---|---|
| cadrage d'un besoin ambigu | `superpowers:brainstorming` |
| plan | `superpowers:writing-plans`, exécution `superpowers:executing-plans` |
| développement | `superpowers:test-driven-development` |
| débogage | `superpowers:systematic-debugging` |
| relecture | `superpowers:requesting-code-review`, `superpowers:receiving-code-review` |
| conclusion | `superpowers:verification-before-completion` |
| branches parallèles | `superpowers:using-git-worktrees`, `superpowers:finishing-a-development-branch` |

Vérifier la disponibilité : `claude plugin list` doit lister `superpowers@claude-plugins-official` en portée **user** (disponible dans tous les projets) ; en session, `/superpowers:` apparaît dans l'autocomplétion. Si absent : `claude plugin install superpowers@claude-plugins-official --scope user`. Sans Superpowers, suivre `references/workflow.md` et le signaler.

## Context7 (documentation à jour)

CLI `ctx7` (source : https://github.com/upstash/context7), mode CLI + skills, **sans serveur MCP**. Installation personnelle : `npx ctx7@latest setup --cli --claude` (skill `find-docs` et règle `context7.md` dans `~/.claude/`), connexion `npx ctx7@latest login` (jeton conservé dans `~/.config/context7/`, jamais dans un projet). Vérifier : `npx ctx7@latest whoami`.

Règle d'usage : trouver la version réellement installée dans le projet (manifeste et fichier de verrouillage) avant d'interroger ; ne jamais envoyer de code privé, de secrets ni de données clients dans les requêtes.

## Ce qui reste propre à chaque projet

Bibliothèques de tests, environnements Python, dépendances Node, extensions Godot, plugins de langage (typescript-lsp, pyright-lsp…), connexions à des bases ou services : configurés et installés dans le projet concerné, jamais dans horn-dev.

## security-guidance (revue de sécurité en session)

Plugin officiel `security-guidance@claude-plugins-official` (portée utilisateur, installé le 2026-09-10). Il agit par hooks : motifs risqués à chaque édition (sans modèle), revue du diff en fin de tour et revue agentique à chaque commit ou push faits par Claude (appels modèle séparés). Il ne bloque rien et ne modifie aucun fichier : ses constats reviennent à Claude, qui les traite dans la conversation. horn-dev ne le recopie pas : `review` et la grille restent la revue **à la demande** ; security-guidance est la couche **continue**. Ni l'un ni l'autre ne constituent un audit de sécurité complet. Règles propres à un projet : `.claude/claude-security-guidance.md` et `.claude/security-patterns.yaml` dans le projet. Désactivation : `SECURITY_GUIDANCE_DISABLE=1` ou `claude plugin disable security-guidance@claude-plugins-official`.
