# Règles de travail (Arness)

- Langue : communiquer en français ; code, identifiants et messages de commit en anglais sauf convention contraire déjà présente.
- Points d'entrée de l'utilisateur : les skills `/horn-feature`, `/horn-bugfix`, `/horn-check`, `/horn-review`, `/horn-release`, `/horn-resume`. Chacun fonctionne seul ; aucun ne rappelle `/horn-feature` ni `/horn-release`.
- Méthode : réutiliser les skills Superpowers (`superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:test-driven-development`, `superpowers:systematic-debugging`, `superpowers:requesting-code-review`, `superpowers:verification-before-completion`) au lieu de recopier leur contenu.
- Documentation des bibliothèques : identifier la version réellement installée (`package.json`, `package-lock.json`) puis interroger Context7 (`npx ctx7@latest library …` / `docs …`). Sans Context7, consulter la documentation officielle et le dire.
- Navigation : privilégier le serveur de langage TypeScript (définitions, références, diagnostics). S'il est indisponible, utiliser Grep/Glob et le signaler.
- Petits changements : une intention par commit, tests associés, revue avant conclusion.
- Fiche de tâche : pour tout travail important, créer ou mettre à jour une fiche dans `docs/development/tasks/` (modèle : `TEMPLATE.md`) et tenir `docs/development/STATUS.md` à jour en fin de session.
- Ne jamais présenter un travail partiellement vérifié comme terminé : distinguer RÉUSSI, ÉCHOUÉ, NON EXÉCUTÉ, NON APPLICABLE.
