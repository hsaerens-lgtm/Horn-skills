# Outillage d'Arness (TOOLCHAIN)

Inventaire de ce qui est réellement installé le 2026-09-08, avec pour chaque composant : source, version, portée, emplacement, rôle, prérequis, vérification, mise à jour, désactivation, désinstallation. Les versions sont celles constatées ; `package-lock.json` verrouille les dépendances npm.

> **Caches et fichiers globaux imposés** : une installation « portée projet » ne garde pas tous ses fichiers dans le dépôt. Sont écrits hors du projet : le clone de la marketplace et le cache des plugins (`%USERPROFILE%\.claude\plugins\`), le registre global des plugins installés (`installed_plugins.json`, `known_marketplaces.json` dans ce même dossier), le binaire `typescript-language-server` (npm global, `%APPDATA%\npm`), Gitleaks (WinGet, `%LOCALAPPDATA%\Microsoft\WinGet\Packages\`, plus une entrée dans le PATH utilisateur), la session Context7 (`%USERPROFILE%\.config\context7\`) et le cache `npx`.

## Environnement de base (préexistant, non modifié)

| Composant | Version constatée | Emplacement | Rôle |
|---|---|---|---|
| Windows 11 Home | 10.0.26200 | — | système |
| Node.js / npm | 24.16.0 / 11.13.0 | `C:\Program Files\nodejs` | exécution, scripts |
| Git | 2.54.0.windows.1 | `C:\Program Files\Git` (mingw64) | versionnage |
| Windows PowerShell | 5.1 | système | scripts `scripts/dev/*.ps1` (PowerShell 7 absent, non requis) |
| Claude Code CLI | 2.1.223 | npm global `%APPDATA%\npm` | agent de développement |

## Projet TypeScript

| | |
|---|---|
| Source | npmjs.org : `typescript`, `vitest`, `@vitest/coverage-v8`, `tsx`, `@types/node` |
| Version | typescript 7.0.2 · vitest 5.0.0 · @vitest/coverage-v8 5.0.0 · tsx 4.23.13 · @types/node 26.5.0 (épinglées, `--save-exact`) |
| Portée / emplacement | projet : `package.json`, `package-lock.json`, `node_modules/` (hors Git) |
| Rôle | typage (`tsc`), tests et couverture (Vitest), exécution des sources sans compilation (`tsx`) |
| Configuration | `tsconfig.json` (strict), `tsconfig.build.json` (émission dans `dist/`), `vitest.config.ts` (tests dans `tests/`, couverture dans `reports/dev/coverage`) |
| Prérequis | Node ≥ 24 |
| Vérification | `npm run typecheck` · `npm test` · `npm run build` puis `node dist/index.js --version` |
| Mise à jour | `npm outdated` puis `npm install -D <paquet>@<version> --save-exact`, relancer `npm run check:full`. Dependabot proposera des PR une fois le dépôt sur GitHub |
| Désactivation / désinstallation | `npm uninstall -D <paquet>` ; supprimer `node_modules/` puis `npm ci` pour repartir du lock |

## Superpowers (méthode de travail)

| | |
|---|---|
| Source | https://github.com/obra/superpowers via la marketplace officielle `anthropics/claude-plugins-official` |
| Version | 6.3.0 |
| Portée | projet (`.claude/settings.json` → `enabledPlugins`, `extraKnownMarketplaces`) |
| Emplacement | déclaration dans le projet ; fichiers dans le cache global `%USERPROFILE%\.claude\plugins\cache\claude-plugins-official\superpowers\6.3.0\` |
| Rôle | 14 skills de méthode : `brainstorming`, `writing-plans`, `executing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `finishing-a-development-branch`, `subagent-driven-development`, `dispatching-parallel-agents`, `writing-skills`, `using-superpowers`. Un hook `SessionStart` charge `using-superpowers` (~584 jetons par session) |
| Prérequis | Claude Code ≥ 2.1 ; accès GitHub pour le clone de la marketplace |
| Vérification | `claude plugin list` (statut « enabled », scope project) ; en session : `/superpowers:brainstorming` apparaît dans l'autocomplétion ; `claude plugin details superpowers@claude-plugins-official` |
| Mise à jour | `claude plugin marketplace update claude-plugins-official` puis `claude plugin update superpowers@claude-plugins-official` (auto-update activé par défaut pour la marketplace officielle) |
| Désactivation | `claude plugin disable superpowers@claude-plugins-official --scope project` |
| Désinstallation | `claude plugin uninstall superpowers@claude-plugins-official --scope project` ; supprimer la marketplace : `claude plugin marketplace remove claude-plugins-official` (désinstalle aussi typescript-lsp) |

## Navigation dans le code : typescript-lsp + typescript-language-server

| | |
|---|---|
| Source | plugin `typescript-lsp` (marketplace officielle) ; binaire https://github.com/typescript-language-server/typescript-language-server |
| Version | plugin 1.0.0 · typescript-language-server 6.0.0 |
| Portée | plugin : projet (`.claude/settings.json`) · binaire : **npm global utilisateur** (`%APPDATA%\npm\typescript-language-server.cmd`) car le plugin exige le binaire dans le PATH |
| Rôle | définitions, références, diagnostics de type après chaque édition (outil LSP intégré de Claude Code) |
| Prérequis | binaire dans le PATH ; le plugin ne l'installe pas |
| Vérification | `typescript-language-server --version` → 6.0.0 ; en session Claude Code : demander « où est définie `parseAppInfo` ? » et vérifier que la réponse vient de l'outil LSP ; onglet Errors de `/plugin` sans « Executable not found » |
| Mise à jour | `npm install -g typescript-language-server@<version>` ; plugin via `claude plugin update typescript-lsp@claude-plugins-official` |
| Désactivation | `claude plugin disable typescript-lsp@claude-plugins-official --scope project` (Claude retombe sur Grep/Glob) |
| Désinstallation | `claude plugin uninstall typescript-lsp@claude-plugins-official --scope project` ; `npm uninstall -g typescript-language-server` |
| Alternative évaluée | Serena non installé : la navigation TypeScript native couvre le besoin ; à réévaluer seulement si un autre langage apparaît |

## Context7 (documentation à jour)

| | |
|---|---|
| Source | https://github.com/upstash/context7 (CLI `ctx7`) |
| Version | ctx7 0.5.10 (exécuté via `npx ctx7@latest`, pas d'installation globale) |
| Portée | projet : skill `.claude/skills/find-docs/SKILL.md` et règle `.claude/rules/context7.md` (installés par `npx ctx7 setup --cli --claude --project`) ; mode CLI + skills, **pas de serveur MCP** |
| Authentification | connexion OAuth (appareil) effectuée le 2026-09-08 ; jeton conservé dans `%USERPROFILE%\.config\context7\` (hors projet, ne jamais le copier dans le dépôt). Variable alternative : `CONTEXT7_API_KEY` |
| Rôle | `npx ctx7@latest library <nom> "<question>"` puis `npx ctx7@latest docs <id> "<question>"` ; règle : chercher la version réellement installée avant d'interroger |
| Prérequis | réseau ; ne jamais envoyer de code privé, secrets ou données clients dans les requêtes |
| Vérification | `npx ctx7@latest whoami` → « Logged in » ; `npx ctx7@latest library vitest "coverage thresholds"` renvoie `/vitest-dev/vitest` (fait le 2026-09-08) |
| Mise à jour | automatique via `npx ctx7@latest` ; skill : relancer `npx ctx7@latest setup --cli --claude --project` |
| Désactivation | supprimer ou renommer `.claude/rules/context7.md` |
| Désinstallation | `npx ctx7@latest remove --claude --cli` (dans le projet) ; `npx ctx7@latest logout` |
| Repli | sans Context7 : documentation officielle (site du projet) et le dire dans le compte rendu |

## Gitleaks (recherche de secrets)

| | |
|---|---|
| Source | https://github.com/gitleaks/gitleaks via WinGet (`Gitleaks.Gitleaks`, installeur portable, SHA-256 vérifié par WinGet) |
| Version | 8.30.1 |
| Portée | **utilisateur Windows** (pas d'administrateur) : `%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gitleaks.Gitleaks_Microsoft.Winget.Source_8wekyb3d8bbwe\gitleaks.exe`, dossier ajouté au PATH utilisateur (visible dans les nouveaux terminaux) |
| Configuration projet | `.gitleaks.toml` : règles par défaut + exclusion des dossiers générés (`node_modules`, `dist`, `reports`, `package-lock.json`) |
| Rôle | contrôle obligatoire `secrets-arborescence` (profils quick et full) et `secrets-historique-git` (full) dans `check.ps1`, toujours avec `--redact` ; job `secrets` de la CI |
| Vérification | `gitleaks version` (nouveau terminal) ; `npm run check` → ligne `secrets-arborescence RÉUSSI` |
| Mise à jour | `winget upgrade --id Gitleaks.Gitleaks --exact` |
| Désinstallation | `winget uninstall --id Gitleaks.Gitleaks --exact` (le contrôle passera alors en NON EXÉCUTÉ et bloquera le succès global, ce qui est voulu) |
| Limite | un scan sans détection n'est pas un audit de sécurité |

## Scripts et skills du projet

| Composant | Emplacement | Rôle | Vérification |
|---|---|---|---|
| `doctor.ps1` | `scripts/dev/` (`npm run doctor`) | diagnostic lecture seule de l'environnement | code de sortie 0 |
| `check.ps1` | `scripts/dev/` (`npm run check`, `npm run check:full`) | contrôle de référence, rapports dans `reports/dev/` ; codes 0/1/2/3 | test d'échec volontaire réalisé le 2026-09-08 (voir STATUS) |
| `run.ps1` | `scripts/dev/` | lancer en mode `dev` (tsx) ou `dist` | `-Mode dist --version` affiche la version |
| `package.ps1` | `scripts/dev/` (`npm run package`) | paquet `.tgz` + SHA-256 + notice, jamais de publication | fichier dans `dist-packages/` |
| `/horn-*` | `.claude/skills/horn-*/SKILL.md` | six points d'entrée (feature, bugfix, check, review, release, resume) | autocomplétion `/horn-` dans une nouvelle session |
| Règles | `.claude/rules/{workflow,testing,safety,context7}.md` | consignes chargées automatiquement | présentes |
| Permissions | `.claude/settings.json` | allow : commandes de vérification en lecture ; deny : `git push`, `npm publish`, `git reset --hard`, `git clean`, lecture de `.env*` | — |

## CI et dépôt distant

| | |
|---|---|
| `.github/workflows/quality.yml` | rejoue typecheck, tests + couverture, build, lancement de `dist`, audit npm (informatif) et Gitleaks (`gitleaks-action@v3`, sorties masquées). **Non exécuté** : aucun dépôt distant n'existe. Pour un dépôt d'organisation, ajouter le secret `GITLEAKS_LICENSE` (gratuit) |
| `.github/dependabot.yml` | PR hebdomadaires npm et GitHub Actions, pas de fusion automatique. Inactif tant que le dépôt n'est pas sur GitHub |
| GitHub CLI (`gh`) | non installé : aucune fonction concrète ne le justifie tant qu'il n'y a pas de dépôt distant |

## Non installé, volontairement

| Outil | Raison | Quand l'ajouter |
|---|---|---|
| Playwright (CLI + tests) | aucune interface web ou desktop dans Arness | dès qu'une interface existe : `npm i -D @playwright/test` puis `npx playwright install chromium`, et documenter les scénarios dans `tests/e2e/` |
| Promptfoo | aucun prompt, agent ou sortie IA à évaluer dans le produit | si Arness intègre un modèle : cas synthétiques, fournisseurs déjà configurés, télémétrie désactivée |
| Serena | navigation TypeScript native suffisante | autre langage ou besoin non couvert |
| GSD, BMAD, Spec Kit, Everything Claude Code, Feature Dev, Sentry, Docker, MCP supplémentaires | hors périmètre de la première installation | besoin documenté d'abord |

## Sauvegardes de configuration

Toute configuration existante modifiée est copiée au préalable dans `.dev-backups/` (hors Git). Le 2026-09-08 : `settings.json.20260908-120237.bak` (version écrite par `claude plugin install` avant ajout des permissions).
