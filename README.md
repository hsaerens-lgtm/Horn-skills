# horn-toolbox

Dépôt source de **horn-dev**, ma boîte à outils de développement assisté pour Claude Code : un plugin personnel (portée utilisateur) qui apporte à chacun de mes projets la même méthode (cadrage, fonctionnalités, correction de bugs, vérification, revue, version locale, reprise de session) sans recopier quoi que ce soit dans les projets. Chaque projet ne garde que ses informations propres dans un petit fichier `.horn-dev.json`.

- Le plugin : [plugins/horn-dev/README.md](plugins/horn-dev/README.md)
- Architecture à trois niveaux et séparation entre projets : [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Installer, mettre à jour, revenir en arrière, désinstaller, refaire sur un autre ordinateur : [docs/INSTALL.md](docs/INSTALL.md)
- Utiliser les commandes dans un projet : [docs/USAGE.md](docs/USAGE.md)
- Migration depuis l'ancien dossier Arness et correspondance des anciens noms : [docs/MIGRATION.md](docs/MIGRATION.md)
- Capacités, déclenchement et limites : [docs/CAPABILITIES.md](docs/CAPABILITIES.md)
- Protocole d'essai (scripts automatisés et essais manuels) : [docs/TEST-PROTOCOL.md](docs/TEST-PROTOCOL.md)
- État courant : [docs/STATUS.md](docs/STATUS.md)

Tests du dispositif :

```bash
npm ci
npm test
```
