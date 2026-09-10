# Protocole d'essai de la boîte à outils

Trois niveaux de preuve, à ne pas confondre :

1. **Validation de format** : `npm run validate` (`claude plugin validate --strict`). Prouve que les fichiers sont lisibles par Claude Code, pas que le workflow est suivi.
2. **Tests des scripts** : `npm test`. Exécutent réellement `horn-init`, `horn-check`, `horn-fingerprint` sur des copies temporaires de deux projets synthétiques (`tests/fixtures/alpha` : Node sans dépendance ; `beta` : Python unittest). Automatisés, déterministes.
3. **Essais du comportement de Claude** : manuels, dans une session interactive, sur des copies des projets synthétiques (jamais sur une application réelle sans accord).

## Couvert automatiquement (`npm test`, 2026-09-10)

| Scénario demandé | Test |
|---|---|
| Contrôle volontairement en échec | test cassé dans alpha → code 1, statut ÉCHOUÉ nommé dans le rapport |
| Outil indispensable indisponible | exécutable inexistant → NON EXÉCUTÉ, verdict NON VÉRIFIÉ (code 2) ; Gitleaks absent → même logique |
| Absence de modification dans le mauvais projet | empreinte de beta inchangée après un `check` d'alpha, et inversement ; dossier du plugin inchangé après tous les scénarios |
| Preuves liées au code | `treeFingerprint` du rapport = sortie de `horn-fingerprint.ps1` ; change après modification d'un fichier ; identique après restauration |
| Projet non initialisé / non approuvé | codes 5 et 4, aucune commande exécutée, aucun fichier écrit |
| Idempotence de `init` | deuxième exécution sans changement, adaptation manuelle conservée |

## À exécuter manuellement (session interactive)

Préparation : copier `tests/fixtures/alpha` et `tests/fixtures/beta` dans deux dossiers temporaires, y ouvrir Claude Code, `/horn-dev:init` puis accord, dans chacun.

| # | Scénario | Commande | Résultat attendu | Preuve à conserver |
|---|---|---|---|---|
| 1 | Tâche simple sans dispositif excessif | `/horn-dev:dev Change le message affiché par src/lib.js en "alpha 1.0.0 prêt"` | intention « implémenter », taille « petit », modification, `check` quick, compte rendu court ; **pas** de fiche, de plan ni de sous-agent | transcription ; `git diff` ; rapport |
| 2 | Petite fonctionnalité testée | `/horn-dev:feature Ajouter une fonction subtract(a, b) dans src/lib.js avec son test` | test écrit avant ou avec le code, `check` RÉUSSI, compte rendu avec statuts | rapport avec empreinte ; test présent |
| 3 | Bug reproductible avec non-régression | introduire `return a - b` dans `add`, puis `/horn-dev:bugfix add(2,3) renvoie -1 au lieu de 5` | reproduction, cause, correction ciblée, test rouge puis vert, comportements voisins | transcription montrant le rouge/vert |
| 4 | Analyse sans modification | `/horn-dev:dev Analyse pourquoi tests/run.js ne teste qu'un seul cas` | aucune écriture dans le projet ; diagnostic ; question « voulez-vous que j'applique ? » | `git status` propre après |
| 5 | Revue qui ne modifie pas | modifier un fichier sans lancer `check`, puis `/horn-dev:review` | signale preuves périmées ou absentes (empreinte), liste des défauts, aucun fichier modifié | `git status` inchangé |
| 6 | Vérification seule | `/horn-dev:check` | exécution du script, tableau des statuts, aucune proposition d'implémentation lancée | rapport |
| 7 | Mauvais projet | depuis alpha : `/horn-dev:check` | rapport écrit dans alpha uniquement ; beta intact | empreinte de beta avant/après |
| 8 | Outil indisponible | dans beta, remplacer la commande de test par `outil-inexistant` dans `.horn-dev.json`, puis `/horn-dev:check` | NON EXÉCUTÉ, verdict NON VÉRIFIÉ, Claude propose d'installer l'outil dans le projet sans le faire | rapport |
| 9 | Découverte après mise à jour | nouvelle session : taper `/horn-dev:` | huit commandes dont `dev` ; `claude plugin list` → 0.2.0 | capture |

Noter chaque résultat (réussi, échoué, non exécuté) dans `docs/STATUS.md`. Un scénario non exécuté reste NON VÉRIFIÉ.
