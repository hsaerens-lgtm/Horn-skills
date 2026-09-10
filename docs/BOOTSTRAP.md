# Installer horn-dev sur une nouvelle machine : prompt à donner à Claude Code

Coller le texte ci-dessous dans une session Claude Code ouverte **dans le dossier où se trouve ce dépôt** (cloné ou copié). Il est en anglais pour être partageable ; Claude répondra dans la langue de votre message si vous ajoutez une phrase en français au début. Le prompt demande à Claude de vérifier avant d'installer, de demander l'accord pour tout téléchargement lourd ou droit administrateur, et de ne rien pousser.

Prérequis que Claude ne peut pas installer seul sans accord : Node.js 24+, Git, Claude Code CLI connecté, Python 3.10+ (pour security-guidance). Sur Windows, `winget` permet d'installer Gitleaks sans droits administrateur.

---

```text
You are setting up my personal Claude Code toolbox "horn-dev" on this machine. The source repository is the current folder (it contains .claude-plugin/marketplace.json and plugins/horn-dev). Work step by step, verify before installing, and never claim something works without running the command that proves it.

Rules
- Check what already exists before installing anything. Reuse it.
- Ask me before: anything needing administrator rights, downloads over 100 MB (the Playwright browser, for example), paid services, or any git push. Never create a remote repository or push.
- Do not modify my other projects. Only this repository and my user-level Claude Code configuration (~/.claude) may change.
- Report every step with one of: DONE (with the command output that proves it), ALREADY PRESENT, SKIPPED (why), FAILED (error message). Do not summarise as "everything is installed" if any step is not DONE or ALREADY PRESENT.

Steps
1. Environment: report versions of node (need 24+), npm, git, python (need 3.10+ for security-guidance), powershell (Windows PowerShell 5.1 or pwsh 7), and claude (Claude Code CLI). If something is missing, tell me the official install command for my OS and stop that step; do not install system software yourself.
2. Gitleaks (secret scanning): if `gitleaks version` fails, on Windows run `winget install --id Gitleaks.Gitleaks --exact --scope user --accept-package-agreements --accept-source-agreements`; on macOS `brew install gitleaks`; on Linux tell me the command. Note that a new terminal may be needed for PATH.
3. Official marketplace: `claude plugin marketplace list`; if claude-plugins-official is missing, `claude plugin marketplace add anthropics/claude-plugins-official`.
4. Method plugin: `claude plugin install superpowers@claude-plugins-official --scope user` (skip if already listed at user scope).
5. Security plugin: `claude plugin install security-guidance@claude-plugins-official --scope user` (needs Python 3.10+; it adds hooks and extra model calls per turn: confirm with me before installing if I have not already said yes).
6. horn-dev: `claude plugin marketplace add "<absolute path of this folder>"` then `claude plugin install horn-dev@horn-toolbox --scope user`. Verify with `claude plugin list` (horn-dev, Scope: user) and `claude plugin details horn-dev@horn-toolbox` (9 skills: bugfix, check, dev, feature, init, release, resume, review, testing).
7. Context7 (documentation): `npx ctx7@latest setup --cli --claude` then tell me to run `npx ctx7@latest login` myself (it opens a browser; do not paste any key in the chat). Verify later with `npx ctx7@latest whoami`.
8. Toolbox self-test in this repository: `npm ci`, `npm test` (all tests must pass), `npm run validate` (plugin and marketplace validation). Then approve this repository for horn-dev: `powershell -NoProfile -ExecutionPolicy Bypass -File plugins/horn-dev/scripts/horn-init.ps1 -ProjectDir "<absolute path of this folder>" -Approve` (on macOS/Linux use pwsh). Then `npm run check` must end with SUCCÈS.
9. Tell me exactly what remains for me to do by hand: restart Claude Code so the new plugins load, run `npx ctx7@latest login`, and, in each of my projects, open Claude Code and run `/horn-dev:init`.

Finish with a table: step, status, proof (command and key output line), and the list of manual actions.
```

---

## Ce que ce prompt installe (rappel)

| Composant | Portée | Commande de vérification |
|---|---|---|
| Node 24+, Git, Python 3.10+, PowerShell, Claude Code CLI | système (déjà présents ou à installer par vous) | `node --version`, `git --version`, `python --version`, `claude --version` |
| Gitleaks | utilisateur (winget) | `gitleaks version` |
| superpowers, security-guidance | plugins Claude Code, portée utilisateur | `claude plugin list` |
| horn-dev (marketplace locale `horn-toolbox`) | plugin Claude Code, portée utilisateur | `claude plugin details horn-dev@horn-toolbox` |
| Context7 (`find-docs`) | utilisateur (`~/.claude/skills`, `~/.claude/rules`) | `npx ctx7@latest whoami` |
| Approbation de ce dépôt | `~/.horn-dev/approved-projects.json` | `npm run check` → SUCCÈS |

Non inclus volontairement : Playwright et son navigateur (par projet, via `/horn-dev:testing`), les plugins de langage (par projet, suggérés par `/horn-dev:init`).
