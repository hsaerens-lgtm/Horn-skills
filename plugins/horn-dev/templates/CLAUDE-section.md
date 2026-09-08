<!-- horn-dev:begin -->
## Méthode de travail (horn-dev)

Ce projet utilise la boîte à outils personnelle `horn-dev` (plugin Claude Code, portée utilisateur). Points d'entrée : `/horn-dev:feature`, `/horn-dev:bugfix`, `/horn-dev:check`, `/horn-dev:review`, `/horn-dev:release`, `/horn-dev:resume`.

- Commandes, contrôles obligatoires et limites du projet : `.horn-dev.json` (fichier propre à horn-dev, pas un fichier natif de Claude Code).
- État d'avancement : `{{STATUS}}` · fiches de tâches : `{{TASKS}}/`.
- Rapports de vérification : dossier `reports` déclaré dans `.horn-dev.json` (hors Git).
- Ne jamais affaiblir un test pour obtenir un succès ; un contrôle obligatoire non exécuté interdit de déclarer la livraison validée.
<!-- horn-dev:end -->
