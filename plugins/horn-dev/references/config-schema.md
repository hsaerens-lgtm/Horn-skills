# Schéma de `.horn-dev.json` (version 1)

Fichier **propre à horn-dev**, placé à la racine du projet utilisateur. Ce n'est pas un fichier natif de Claude Code : seuls les scripts et skills de horn-dev le lisent. Il est créé par `horn-init.ps1 -Apply` à partir des manifestes détectés et peut être édité librement ; une nouvelle exécution d'init ne l'écrase jamais.

Règle de sécurité : les commandes qu'il contient ne sont exécutées que si le projet figure dans la liste locale des projets approuvés (`%USERPROFILE%\.horn-dev\approved-projects.json`, ou `HORN_DEV_HOME`). Cette liste n'est ni dans le projet ni dans le plugin.

| Champ | Type | Obligatoire | Rôle |
|---|---|---|---|
| `$schema` | string | non | libre, indication du schéma |
| `version` | number | oui | `1` |
| `project.name` | string | oui | nom affiché dans les rapports |
| `project.stack` | string[] | non | technologies détectées (`node`, `typescript`, `python`, `rust`, `dotnet`, `godot`, `tauri`, `electron`, `react`…) |
| `project.manifests` | string[] | non | manifestes lus lors de l'init |
| `paths.reports` | string | non | dossier des rapports, relatif au projet (défaut `reports/dev`) ; à exclure de Git |
| `paths.status` | string | non | fichier d'état (défaut `docs/development/STATUS.md`) |
| `paths.tasks` | string | non | dossier des fiches (défaut `docs/development/tasks`) |
| `commands.install` | string | non | installation des dépendances du projet (jamais exécutée par horn-check) |
| `commands.dev` / `commands.start` | string | non | lancement |
| `commands.package` | string | non | construction d'une version distribuable, utilisée par `horn-package.ps1` |
| `checks[]` | object[] | oui (peut être vide) | contrôles exécutés par `horn-check.ps1`, dans l'ordre |
| `checks[].id` | string | oui | identifiant court (lettres, chiffres, tirets) |
| `checks[].command` | string | oui | commande shell exécutée dans le dossier du projet |
| `checks[].profiles` | string[] | non | `quick`, `full` (défaut : les deux) |
| `checks[].mandatory` | boolean | non | défaut `true` ; un obligatoire ÉCHOUÉ → code 1, NON EXÉCUTÉ → code 2 |
| `checks[].expectOutput` | string | non | la dernière ligne non vide de la sortie doit être égale à cette valeur (ex. version attendue) |
| `checks[].network` | boolean | non | `true` si le contrôle a besoin du réseau ; ignoré avec `-NoNetwork` |
| `secrets.enabled` | boolean | non | défaut `true` : Gitleaks sur l'arborescence (et l'historique Git en profil full), toujours avec `--redact` |
| `secrets.config` | string | non | chemin du `.gitleaks.toml` du projet |
| `secrets.profiles` / `secrets.mandatory` | | non | comme pour un contrôle |
| `notApplicable[]` | `{id, reason}` | non | contrôles sans objet pour ce projet, affichés NON APPLICABLE |
| `limits[]` | string[] | non | limites de validation connues, reprises dans les comptes rendus |

Codes de sortie de `horn-check.ps1` : 0 succès · 1 obligatoire ÉCHOUÉ · 2 obligatoire NON EXÉCUTÉ · 3 usage · 4 projet non approuvé · 5 projet non initialisé.

Exemple complet : `templates/horn-dev.example.json`.
