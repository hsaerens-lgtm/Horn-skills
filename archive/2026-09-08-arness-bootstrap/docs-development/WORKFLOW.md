# Façon de travailler (WORKFLOW)

Deux modes coexistent : **coordonné** (Claude Code enchaîne les étapes) et **indépendant** (chaque outil s'utilise seul, y compris sans Claude).

## Mode coordonné

Qui fait quoi :

- **Claude Code** conduit le travail dans la session.
- **Superpowers** fournit la méthode (skills `superpowers:*`), chargée à chaque démarrage de session.
- **Les skills `/horn-*`** sont les points d'entrée de l'utilisateur ; ils appellent la méthode et les outils réels.
- **Context7** (`/find-docs`) fournit la documentation à la version installée.
- **typescript-lsp** aide à comprendre définitions, références et erreurs de type.
- **Vitest, tsc, Gitleaks et `scripts/dev/check.ps1`** produisent les résultats mesurables et le rapport.
- **`/horn-review`** examine les changements et exige des preuves.
- **La CI** (`quality.yml`) rejouera les mêmes contrôles après un push autorisé.

Chaîne type :

```
Demande (/horn-feature "…")
→ cadrage (superpowers:brainstorming si ambigu ; validation du besoin par l'utilisateur)
→ critères d'acceptation (fiche docs/development/tasks/…)
→ plan (superpowers:writing-plans)
→ implémentation et tests (superpowers:test-driven-development, /find-docs)
→ revue (/horn-review ou superpowers:requesting-code-review)
→ vérification (npm run check ; superpowers:verification-before-completion)
→ compte rendu (fiche + STATUS.md)
```

Aucune architecture d'agents supplémentaire n'est nécessaire : `/horn-review` utilise un contexte séparé (`context: fork`, agent Explore en lecture seule) ; le reste s'exécute dans la session.

## Mode indépendant

| Besoin | Sans développer | Équivalent terminal (sans Claude) |
|---|---|---|
| Consulter une documentation | `/find-docs` ou `npx ctx7@latest library vitest "…"` | idem |
| Lancer les tests | `/horn-check` | `npm test`, `npm run check` |
| Relire un diff | `/horn-review` | `git diff` |
| Investiguer un bug | `/horn-bugfix "…"` (sans refonte) | `npx vitest run tests/…`, `npm run dev` |
| Préparer un paquet sans publier | `/horn-release` | `npm run package` |
| Reprendre le contexte | `/horn-resume` | lire `docs/development/STATUS.md`, `git status`, `reports/dev/check-latest.json` |

Règles d'indépendance :

- `/horn-check` et `/horn-review` ne rappellent jamais `/horn-feature`, `/horn-bugfix` ni `/horn-release`.
- `/horn-release` est réservé à l'utilisateur (`disable-model-invocation: true`) ; aucun autre skill ne l'invoque.
- L'étape de vérification est partagée : tous les skills utilisent `scripts/dev/check.ps1`, jamais une variante privée.
- `/horn-resume` ne modifie rien.

## Transfert entre étapes

Aucune mémoire implicite n'est partagée entre les étapes ou les sous-agents. Le relais se fait par une **fiche de tâche** (`docs/development/tasks/AAAA-MM-JJ-<slug>.md`, modèle `TEMPLATE.md`) contenant : objectif, critères, périmètre, décisions, fichiers modifiés, état des tests, risques, blocages, prochaine action. `STATUS.md` résume l'ensemble en fin de session.

Un sous-agent (revue, exploration) reçoit dans son prompt le périmètre, la fiche et les preuves à examiner. Parallélisme initial limité : un sous-agent à la fois sauf demande.

## Dégradation propre

- Sans Context7 : consulter la documentation officielle et le signaler dans le compte rendu.
- Sans serveur de langage : Grep/Glob et le signaler.
- Sans Superpowers (plugin désactivé) : suivre les règles `.claude/rules/` ; les skills `/horn-*` restent utilisables.
- **Sans Gitleaks, sans Node ou sans dépendances** : le contrôle obligatoire est NON EXÉCUTÉ, `check.ps1` renvoie 2 et la livraison ne peut pas être déclarée validée. C'est volontaire.

## Statuts et codes de sortie de la vérification

| Statut | Sens |
|---|---|
| RÉUSSI | contrôle exécuté, code 0 |
| ÉCHOUÉ | contrôle exécuté, code ≠ 0 (voir journal dans `reports/dev/logs/<horodatage>/`) |
| NON EXÉCUTÉ | contrôle prévu mais impossible à lancer (outil absent, étape précédente échouée) |
| NON APPLICABLE | contrôle sans objet pour ce projet (ex. scénarios navigateur sans interface) |

Code de sortie de `check.ps1` : 0 succès · 1 au moins un obligatoire ÉCHOUÉ · 2 un obligatoire NON EXÉCUTÉ · 3 erreur d'usage. Un contrôle optionnel (audit npm) n'influence pas le code de sortie mais figure dans le rapport.
