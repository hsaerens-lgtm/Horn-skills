# Grille de sélection des vérifications

Objectif : pour chaque tâche, déduire des **parties touchées** les vérifications qui s'imposent, même si l'utilisateur ne les a pas demandées. La grille déclenche une évaluation proportionnée, pas tous les tests à chaque demande. Un risque important hors périmètre se **signale** et se propose comme action distincte ; il ne transforme pas la tâche en refonte.

## 1. Dimensionner d'abord

| Taille | Exemples | Parcours |
|---|---|---|
| **Petit** | libellé, message, valeur par défaut, erreur évidente sur une ligne, commentaire | lire → modifier → contrôles existants (`/horn-dev:check` quick) → diff → compte rendu court. Pas de fiche, pas de plan, pas de cadrage. |
| **Moyen** | nouvelle fonction ou option, correction avec test de non-régression, changement dans un composant | comprendre → impacts (grille) → intervenir avec tests → check → diff → compte rendu. Fiche seulement si la tâche dépasse la session. |
| **Grand** | nouveau composant, contrat ou format modifié, migration, sécurité, plusieurs composants | cadrage bref (l'utilisateur pilote le produit : questionner seulement un risque technique concret), fiche, plan (`superpowers:writing-plans`), TDD, check full, revue séparée, compte rendu avec limites. |

## 2. Domaines touchés → vérifications

| Si la modification touche… | Vérifier | Preuve attendue | Limite à signaler |
|---|---|---|---|
| **Fichiers, sauvegardes, base de données, formats persistés** | lecture et écriture ; données existantes toujours lisibles ; écriture partielle ou interrompue ; compatibilité ascendante du format ; récupération après erreur ; sauvegarde et retour arrière **avant** toute migration | test de relecture d'un fichier ou d'une base créés avec l'ancienne version ; test d'écriture interrompue ; script de sauvegarde exécuté | données réelles non testées ; volumes réels non mesurés |
| **Authentification, API, permissions, entrées utilisateur** | accès autorisés **et** interdits ; validation des entrées (vide, trop long, type inattendu, injection) ; codes d'erreur ; aucun secret ni donnée sensible dans les journaux et réponses | tests des deux côtés de chaque règle d'accès ; test d'entrée invalide ; grep des journaux ; scan Gitleaks | un scan n'est pas un audit ; revue spécialisée recommandée pour tout ce qui gère des identifiants ou des paiements |
| **Tâches asynchrones, parallélisme, appels réseau, génération IA** | délais et expiration ; annulation ; exécutions concurrentes ; échec partiel ; consommation mémoire et CPU ; réactivité de l'interface pendant l'attente | test avec délai simulé ; test d'annulation ; test de deux exécutions simultanées ; mesure simple avant et après | comportements réels du service distant non couverts par des simulations |
| **Interface (web, desktop, CLI interactive)** | états chargement, erreur, vide, succès ; interactions principales ; navigation clavier et libellés lisibles | tests de composants ou scénario Playwright si configuré ; sinon procédure manuelle écrite et statut NON EXÉCUTÉ | un test unitaire ne valide pas l'interface ; un test navigateur ne valide pas une application desktop native |
| **Échanges entre composants (API interne, messages, fichiers partagés)** | formats et versions des messages ; erreurs et indisponibilité de l'autre composant ; compatibilité avec l'ancien format | test de contrat ; test avec composant indisponible ; distinguer test simulé (mock) et intégration réelle | un mock ne prouve pas le service réel |
| **Packaging, dépendances, compilation, démarrage** | installation reproductible depuis le lock ; compilation ; ressources incluses ; démarrage de la version compilée dans un environnement propre ; audit des dépendances | `install` puis `build` puis lancement de l'artefact (`expectOutput`) dans `/horn-dev:check full` ou `/horn-dev:release` | environnement cible différent du poste de développement |
| **Comportements d'un modèle IA (prompts, agents, sorties structurées, appels d'outils)** | schéma des sorties ; appels d'outils attendus ; respect des consignes ; cas d'échec (réponse vide, refus, dépassement) ; coût et délai | tests **logiciels** déterministes (parseurs, garde-fous, cas d'erreur simulés) séparés des **évaluations du modèle** (cas synthétiques, fournisseur déjà configuré, résultats conservés avec modèle et paramètres) | une évaluation n'est pas reproductible à l'identique ; ne pas introduire de consommation facturée sans accord |
| **Performance et ressources** | temps de réponse, mémoire, taille des artefacts, requêtes répétées | mesure avant et après sur le même jeu de données ; jamais « optimisé » sans chiffre | mesure sur le poste, pas en conditions réelles |

## 3. Domaines techniques pris en charge pour l'utilisateur

L'utilisateur pilote le produit, les priorités et l'expérience. La boîte à outils prend en charge les aspects suivants sans qu'il doive nommer un spécialiste :

| Domaine | Ce que l'assistant fait systématiquement | Ce qu'il signale |
|---|---|---|
| Qualité du code | conventions du projet, lecture des usages avant changement, pas de renommage ni reformatage hors demande | dette technique rencontrée, sans la corriger d'office |
| Bugs | reproduction, hypothèse, cause racine, correction ciblée, non-régression ; arrêt après trois tentatives sans progrès | causes possibles non confirmées |
| Tests | tests décrivant l'existant avant de le changer ; nouveaux tests pour le nouveau code ; jamais d'affaiblissement | zones sans test, tests simulés |
| Sécurité et secrets | Gitleaks, validation des entrées, accès interdits testés, pas de secret dans les sorties | besoin d'une revue spécialisée (identifiants, paiements, données personnelles) |
| Données et compatibilité | sauvegarde et retour arrière avant migration, relecture d'anciens fichiers | migrations de données réelles : accord explicite requis |
| Performances | mesure avant/après quand la tâche l'exige | absence de mesure en conditions réelles |
| Compilation, packaging, diagnostic | `check full`, `release`, `doctor` | environnement cible non reproduit |
| Services et IA | séparation tests logiciels / évaluations ; fournisseurs déjà configurés | coût, non-déterminisme |

## 4. Ce que la grille ne garantit pas

Elle ne remplace ni une expertise humaine ni un audit indépendant. Elle produit des preuves reproductibles et nomme ce qui n'a pas été vérifié. Un compte rendu qui dit « tout est sécurisé » ou « code optimisé » sans mesure ni test est une erreur de méthode.
