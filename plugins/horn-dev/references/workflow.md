# Façon de travailler horn-dev

## Répartition des responsabilités

L'utilisateur pilote le produit, les priorités et l'expérience utilisateur. La boîte à outils prend en charge la technique : implémentation et qualité du code, compréhension et correction des bugs, tests et non-régression, sécurité et secrets, données et compatibilité, performances, compilation et packaging, intégration de services et comportements IA. L'utilisateur n'a pas à nommer un spécialiste ou un test : `/horn-dev:dev` classe la demande et applique la grille de vérifications (`verification-grid.md`). L'assistant remet un choix en question seulement pour un risque technique concret, avec une recommandation, et signale les cas nécessitant une revue spécialisée humaine.

## Trois niveaux, strictement séparés

| Niveau | Contient | Ne contient jamais |
|---|---|---|
| Dépôt source de la boîte à outils | skills, scripts génériques, modèles, références, tests du dispositif | code ou données d'un projet utilisateur |
| Plugin installé (portée utilisateur, copie dans le cache Claude Code) | la version validée du plugin | avancement d'un projet, rapports, secrets, chemins propres à une machine |
| Chaque projet | `.horn-dev.json`, STATUS, fiches, rapports, dépendances et tests du produit | la méthode recopiée |

La liste des projets approuvés vit dans `%USERPROFILE%\.horn-dev\` (réglage local non partagé).

## Point d'entrée et commandes spécialisées

| Commande | Rôle | Modifie le produit ? | Invocation |
|---|---|---|---|
| `/horn-dev:dev [demande]` | classe l'intention (implémenter, corriger, analyser, relire, vérifier), dimensionne, applique la grille | selon l'intention ; jamais pour analyser, relire, vérifier | utilisateur ou Claude |
| `/horn-dev:feature [besoin]` | implémentation proportionnée | oui | utilisateur ou Claude |
| `/horn-dev:bugfix [problème]` | diagnostic et correction | oui | utilisateur ou Claude |
| `/horn-dev:check [quick|full]` | contrôles déclarés, rapport, statuts | non | utilisateur ou Claude |
| `/horn-dev:review [périmètre] [focus]` | revue séparée, preuves à empreinte | non | utilisateur ou Claude |
| `/horn-dev:resume` | reprise du contexte | non | utilisateur ou Claude |
| `/horn-dev:init` | adaptation légère d'un projet | crée seulement les fichiers de suivi absents | utilisateur seul |
| `/horn-dev:release` | version locale, jamais publiée | construit un artefact | utilisateur seul |
| `/horn-dev:testing` | expliquer et mettre en place tests unitaires, bout en bout (Playwright si interface web) et CI ; démonstration | installe des dépendances de test et crée des tests, après accord | utilisateur seul |

Le routage de `dev` repose sur des instructions : il est fiable pour les formulations courantes mais pas garanti. Les commandes spécialisées restent l'invocation explicite fiable. Une commande seule ne déclenche jamais tout le parcours.

## Parcours par défaut (modification autorisée)

```
A. Comprendre   : instructions, code et usages, état Git, échecs présents, résultat attendu
B. Impacts      : composants touchés → grille → vérifications nommées avant de coder
C. Intervenir   : changement limité, conventions, tests (existant d'abord), pas de hors périmètre
D. Vérifier     : horn-check (quick|full), diff relu, revue séparée si risque, empreinte à jour
E. Rendre compte: résultat · vérifications exécutées · limites · décision attendue
```

Petit changement : A → C → D (quick) → E, en quelques minutes. Grand changement : cadrage bref, fiche, plan, TDD, check full, revue.

## Preuves

- Statuts : RÉUSSI (exécuté, code 0) · ÉCHOUÉ (exécuté, code ≠ 0 ou sortie inattendue) · NON EXÉCUTÉ (outil absent, commande vide, étape précédente échouée) · NON APPLICABLE (déclaré sans objet).
- Un contrôle obligatoire NON EXÉCUTÉ empêche le verdict SUCCÈS (code 2). Codes : 0 succès · 1 échec · 2 non vérifié · 3 usage · 4 non approuvé · 5 non initialisé.
- Chaque rapport porte `treeFingerprint`, l'empreinte de l'état exact du code vérifié (`horn-fingerprint.ps1`). Une modification ultérieure change l'empreinte et périme les preuves : relancer les contrôles concernés.
- Ne jamais confondre : code modifié · compilation réussie · tests réussis · application réellement exécutée · version distribuable validée.
- Interdits : supprimer un test, affaiblir une assertion, modifier un résultat attendu, exclure un contrôle pour obtenir du vert.

## Réutilisation

Superpowers (méthode) et Context7 (documentation) sont invoqués par leurs noms réels, pas recopiés (`superpowers.md`). Aucun hook n'est déclaré par horn-dev. Sans un de ces outils : suivre ce document et le signaler.

## Transfert entre étapes

Pas de mémoire implicite ni partagée : une fiche par tâche importante (objectif, critères, périmètre, décisions, fichiers, état des tests, risques, blocages, prochaine action) et un STATUS à jour. Un sous-agent de revue reçoit le besoin, le diff et les preuves, et cherche des défauts précis sans corriger.
