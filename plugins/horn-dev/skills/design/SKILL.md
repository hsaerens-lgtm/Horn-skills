---
name: design
description: Concevoir ou restyler une interface du projet courant — plan de design (palette, typographie, disposition, thèmes), états et accessibilité, mouvement sobre, puis implémentation et preuves visuelles ; utilise la collection React Bits via le skill anthropic-skills:reactbits quand le projet est en React et que ce skill est disponible. Utiliser pour « rends ça plus joli », « page d'accueil », « design », « animation », « restyle », « maquette ».
argument-hint: "[écran ou composant à concevoir, et intention (sobre, animé, marketing…)]"
---

# /horn-dev:design — concevoir une interface avec méthode

**Projet cible** : `${CLAUDE_PROJECT_DIR}`. Guide : `${CLAUDE_PLUGIN_ROOT}/references/design-guide.md` (à lire avant de proposer quoi que ce soit). Grille de vérifications, ligne « Interface » : `${CLAUDE_PLUGIN_ROOT}/references/verification-grid.md`.

**Entrée** : `$ARGUMENTS` = l'écran ou le composant visé et l'intention. Vide → demander en une question : quel écran, pour qui, quelle impression recherchée.

L'utilisateur pilote l'expérience utilisateur. Ne pas le noyer d'options : proposer au plus deux directions, avec une recommandation argumentée, puis exécuter.

## Actions

1. **Comprendre** : lire les instructions du projet, le système de design existant s'il y en a un (tokens, thème, composants, Tailwind ou CSS), la stack (React ? Vite ? Next ? autre), les écrans voisins pour rester cohérent. Un système existant prime sur le guide.
2. **Plan de design** (guide, sections 1 à 5) : sujet, mission de l'écran, palette nommée, paire de polices, disposition en une phrase, thèmes, états, mouvement prévu (au plus un fond, un effet de titre, des interactions utiles). Le présenter en quelques lignes et obtenir l'accord de l'utilisateur si l'écran est central ou si la direction change l'identité visuelle ; sinon, décider et l'expliquer en une ligne.
3. **Composants animés** (guide, section 6) : si le projet est en React et que l'intention appelle du mouvement, vérifier si le skill `anthropic-skills:reactbits` est disponible dans la session ; si oui, l'invoquer et choisir dans son catalogue en respectant la sobriété ; sinon, utiliser l'installation officielle par composant et le signaler. Toute dépendance nouvelle est annoncée avant installation, dans le projet uniquement.
4. **Implémenter** : par petits pas, conventions du projet, jetons de couleur plutôt que valeurs codées, états chargement, erreur, vide et succès, focus visible, `prefers-reduced-motion`. Pas de refonte hors périmètre.
5. **Vérifier** (guide, section 7) : `/horn-dev:check` ; captures d'écran des états via Playwright si configuré (sinon proposer `/horn-dev:testing`), essai clavier, contraste des couples texte et fond, mode sombre si prévu, poids ajouté par les composants. Relire le diff.
6. **Rendre compte** : plan retenu, composants utilisés et leurs dépendances, preuves (captures, contrôles), ce qui n'a pas été vérifié (appareils réels, lecteur d'écran), décision attendue s'il en reste une.

## Limites et conditions d'arrêt

- Ne jamais recopier le skill React Bits ni ses sources dans horn-dev : le réutiliser par son nom ; les composants copiés appartiennent au projet.
- Ne pas empiler les effets : si l'utilisateur demande « plus d'animations » au-delà de la hiérarchie du guide, le prévenir du coût (lisibilité, performance, accessibilité) et proposer un compromis.
- Ne pas changer l'identité visuelle d'une application existante sans accord explicite.
- Un rendu vérifié dans un navigateur ne valide pas une application desktop native ni un appareil mobile réel.
