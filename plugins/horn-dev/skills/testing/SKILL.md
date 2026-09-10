---
name: testing
description: Mettre en place ou expliquer les tests d'un projet — tests unitaires adaptés à la technologie, tests de bout en bout Playwright s'il existe une interface web, intégration continue qui rejoue les tests à chaque push — avec une démonstration (un test qui passe, un test volontairement en échec) et le raccordement à .horn-dev.json. Réservé à l'invocation explicite de l'utilisateur car des dépendances sont installées dans le projet.
argument-hint: "[explique | demo <dossier vide> | setup] [précisions]"
disable-model-invocation: true
---

# /horn-dev:testing — tests unitaires, bout en bout, CI

**Projet cible** : `${CLAUDE_PROJECT_DIR}` (sauf mode `demo`, qui cible un dossier vide indiqué par l'utilisateur, jamais un projet réel). Mémo de référence : `${CLAUDE_PLUGIN_ROOT}/references/testing-primer.md`. Modèles : `${CLAUDE_PLUGIN_ROOT}/templates/testing-demo/`.

**Entrée** : `$ARGUMENTS` = `explique`, `demo <dossier>`, `setup`, ou vide (alors : audit puis proposition, sans rien installer).

## Mode `explique`

Expliquer en français, à partir du mémo : différence entre tests unitaires et tests de bout en bout, ce que chacun prouve et ne prouve pas, comment lire un échec, ce que fait Playwright, ce qu'apporte la CI. Proposer un artefact pédagogique si l'utilisateur veut un document à conserver. Aucune commande exécutée.

## Mode `demo <dossier vide>`

1. Vérifier que le dossier est vide ou inexistant et qu'il n'est pas un projet réel de l'utilisateur.
2. Créer la mini application : `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/horn-testing-demo.ps1" -TargetDir "<dossier>"`. Annoncer que `-Install` télécharge un navigateur (Chromium, plusieurs dizaines de Mo) et attendre l'accord ; puis relancer avec `-Install -Run`.
3. Commenter la sortie devant l'utilisateur : les tests verts, le test volontairement en échec de chaque famille (nom `DÉMO ÉCHEC VOLONTAIRE`), où sont la capture d'écran et la trace (`test-results/`), comment ouvrir le rapport (`npm run test:e2e:report`), et comment retirer les échecs volontaires (`npm run demo:clean`).
4. Ne rien copier de cette démonstration dans un projet réel sans passer par le mode `setup`.

## Mode `setup` (projet courant)

1. **Audit** : technologie et versions (manifestes), tests existants et leur moteur, présence d'une interface web (fichiers HTML, framework front, serveur de dev), CI existante, `.horn-dev.json`. Aucune installation.
2. **Proposition** en clair : moteur unitaire adapté (Vitest pour Node/TypeScript, pytest pour Python, `cargo test`, `dotnet test`… ; conserver un moteur déjà présent), Playwright **seulement** s'il y a une interface web (sinon dire pourquoi non), commandes à ajouter, fichiers créés, modèle de CI, coût (téléchargement du navigateur, durée des tests). Demander l'accord (AskUserQuestion).
3. **Installation et configuration** après accord : dépendances de développement dans le projet, configuration (adapter `templates/testing-demo/playwright.config.js` et `vitest.config.js` : port, commande de démarrage réelle, dossiers), `.gitignore` (`test-results/`, `playwright-report/`, rapports).
4. **Premiers tests** : un test unitaire réel sur un comportement existant important (pas un test trivial), un test de bout en bout sur le parcours principal (ciblage par rôle et libellé), plus un test volontairement en échec par famille, nommé `DÉMO ÉCHEC VOLONTAIRE`, pour montrer la lecture d'un échec.
5. **Exécution devant l'utilisateur** : lancer les deux commandes, commenter les résultats et les artefacts (capture, trace, rapport). Puis supprimer les tests volontaires avec son accord et relancer pour obtenir le vert.
6. **Raccordement** : ajouter dans `.horn-dev.json` les contrôles `tests-unitaires` (profils quick et full, obligatoire) et `tests-e2e` (profil full au minimum, obligatoire si l'interface est le cœur du produit) ; créer le workflow CI à partir de `templates/testing-demo/.github/workflows/tests.yml` en reprenant les commandes réelles du projet ; rappeler qu'il ne s'exécutera qu'après un push, que l'utilisateur fera lui-même.
7. **Vérification** : `/horn-dev:check full` doit être SUCCÈS. Mettre à jour STATUS (ce qui est couvert, ce qui ne l'est pas).

## Sorties

Ce qui est installé (versions), fichiers créés, commandes disponibles, résultats réellement observés (nombre de tests, échecs), ce que les tests couvrent et ne couvrent pas, prochaine étape (push pour activer la CI).

## Limites et conditions d'arrêt

- Pas d'installation sans accord ; pas de téléchargement de navigateur sans l'annoncer.
- Ne pas remplacer un moteur de tests existant qui convient ; ne pas ajouter Playwright à un projet sans interface web.
- Ne jamais affaiblir un test pour obtenir du vert ; les échecs volontaires de démonstration sont nommés comme tels et retirés.
- Un test de bout en bout dans un navigateur ne valide pas une application desktop native ; le dire.
- Le mode `demo` n'écrit jamais dans un dossier non vide ni dans le dossier du plugin.
