# Mémo : tests unitaires, tests de bout en bout, intégration continue

À l'usage de l'utilisateur (non développeur) et de l'assistant quand il met en place les tests d'un projet.

## Pourquoi tester

Un test est une vérification automatique, rejouable à l'identique, qui compare ce que fait le logiciel à ce qu'on attend. Il sert à trois choses : prouver qu'une fonctionnalité marche aujourd'hui, empêcher qu'elle se casse demain sans qu'on s'en rende compte (non-régression), et documenter le comportement attendu par l'exemple.

## Les deux familles à connaître

| | Test unitaire | Test de bout en bout (end-to-end, E2E) |
|---|---|---|
| Ce qu'il vérifie | une fonction ou un petit module, isolé | un parcours complet, comme un utilisateur : ouvrir la page, cliquer, lire ce qui s'affiche |
| Ce qu'il exécute | le code directement, sans navigateur ni serveur | l'application réelle dans un vrai navigateur, avec son serveur |
| Vitesse | millisecondes ; des centaines en quelques secondes | secondes par test ; quelques dizaines suffisent |
| Ce qu'il prouve | la logique est juste | les morceaux fonctionnent **ensemble** |
| Ce qu'il ne prouve pas | que l'écran affiche bien le résultat | pourquoi ça casse (il constate, il n'explique pas) |
| Quand il casse | l'erreur est localisée : nom du test, valeur attendue, valeur obtenue | Playwright garde une capture d'écran et une trace pas à pas de l'échec |
| Outils retenus | Vitest (JavaScript/TypeScript), pytest (Python), `cargo test`, `dotnet test`… | Playwright (interfaces web) ; tests natifs distincts pour une application desktop |

Règle simple : beaucoup de tests unitaires sur la logique, quelques tests de bout en bout sur les parcours qui comptent (la « pyramide » des tests). Un test de bout en bout ne remplace pas les tests unitaires, et l'inverse non plus.

## Comment se lit un résultat

- **Vert / réussi** : la vérification a été exécutée et le résultat attendu est là.
- **Rouge / échoué** : exécuté, mais le résultat diffère. Le message donne le fichier, le nom du test, l'attendu et l'obtenu. Pour un test de bout en bout, ouvrir le rapport HTML (`npx playwright show-report`) et la capture dans `test-results/`.
- **Non exécuté** : l'outil ou le navigateur manque, la commande est vide. Ce n'est pas un succès.

Un échec peut venir du code (bug) **ou** du test (attente fausse). On corrige la cause réelle ; on ne modifie jamais l'attente juste pour repasser au vert.

## Ce que fait Playwright, concrètement

1. Démarre l'application (`webServer` dans `playwright.config`), ou réutilise celle déjà lancée.
2. Ouvre un navigateur sans fenêtre (Chromium par défaut ; Firefox et WebKit possibles).
3. Exécute chaque test : `page.goto`, `getByRole('button', { name: 'Augmenter' }).click()`, `expect(...).toHaveText('1')`. Les attentes patientent automatiquement jusqu'à un délai maximal.
4. En cas d'échec : capture d'écran, trace (chaque action, le DOM, la console), rapport HTML.

Bonnes pratiques : cibler les éléments comme un utilisateur (rôle, libellé), pas par structure HTML fragile ; un test par parcours ; pas de données réelles ; pas de dépendance à un service externe non maîtrisé (le simuler ou l'isoler).

Piège constaté le 2026-09-10 : avec `reuseExistingServer: true`, si un **autre** programme écoute déjà sur le port attendu (ici une autre application de l'utilisateur sur 4173), Playwright teste cette autre application et tous les tests échouent avec des messages déroutants (« titre reçu : Prototype »). Remèdes : un port peu courant par projet, `reuseExistingServer: false` pour une démonstration, et lire le premier message d'erreur (le titre reçu dit tout) avant de soupçonner le code.

## Intégration continue (CI)

La CI rejoue les mêmes commandes qu'en local sur une machine neuve à chaque `push` ou pull request (GitHub Actions : fichier `.github/workflows/*.yml`). Elle prouve que le projet ne dépend pas de l'ordinateur d'un développeur et bloque une fusion qui casserait les tests. Le rapport Playwright et les captures sont conservés en artefacts téléchargeables. Un fichier de workflow créé localement ne fait rien tant que le dépôt n'est pas poussé sur GitHub.

## Mise en place dans un projet (ce que fait `/horn-dev:testing`)

1. Audit : quels tests existent, quelle technologie, y a-t-il une interface web.
2. Explication et proposition : moteur unitaire adapté à la technologie ; Playwright seulement s'il y a une interface web ; modèle de CI.
3. Après accord : installation des dépendances **dans le projet**, configuration, un premier test qui passe et un test volontairement en échec pour apprendre à lire un échec, exécution devant l'utilisateur, puis suppression du test volontaire.
4. Raccordement : `.horn-dev.json` (contrôles `tests-unitaires` et `tests-e2e`), workflow CI, `.gitignore` (rapports, captures).

Modèles : `templates/testing-demo/` (mini application complète), script `horn-testing-demo.ps1` pour la créer dans un dossier vide.

## Ce que les tests ne garantissent pas

Un test simulé ne prouve pas le service réel. Un test de bout en bout dans un navigateur ne valide pas une application desktop native ni un environnement de production différent. Une suite verte n'est pas l'absence de bugs : c'est l'absence des bugs qu'on a pensé à vérifier.
