# Guide de conception d'interface (horn-dev)

À l'usage de l'assistant quand une tâche touche l'apparence ou l'expérience d'une interface (web, desktop, artefact). L'utilisateur pilote l'expérience utilisateur ; l'assistant propose peu d'options, avec une recommandation, puis exécute avec méthode.

## 1. Cadrer en trois phrases

Sujet concret (quelle application, pour qui), travail de la page ou de l'écran (une seule mission principale), contraintes existantes (charte, système de design, composants déjà présents). Si un système de design existe dans le projet (tokens, thème, composants), il prime sur tout ce qui suit.

## 2. Plan de design avant le code

Écrire un plan court, puis en dériver chaque décision :

- **Couleur** : quatre à six valeurs nommées (fond, fond secondaire, encre, encre secondaire, accent, ligne), des neutres légèrement teintés plutôt que des gris purs, un accent unique. Les couleurs sémantiques (succès, avertissement, erreur) sont à part et ne comptent pas comme accent.
- **Typographie** : une police d'affichage à caractère pour les titres, une police de texte lisible, une monospace pour les données ou commandes. Vraie pile de repli. Texte courant vers 65 à 70 caractères de large ; échelle de tailles fixée et respectée.
- **Disposition** : une phrase. Grille ou flex avec `gap`, pas de marges empilées ; contenus larges (tableaux, code) qui défilent dans leur propre conteneur ; éléments répétés composés comme un seul objet (mêmes bords, même rembourrage).
- **Thèmes** : si l'application a un mode sombre, définir la palette complète en clair, puis redéfinir seulement les jetons en sombre ; tout élément prend sa couleur du même jeu de jetons que sa surface.

## 3. États et accessibilité, toujours

Chaque écran a quatre états : chargement, erreur, vide, succès. Les concevoir explicitement (texte d'erreur qui dit quoi faire, état vide qui propose la première action). Navigation clavier visible (focus), contraste suffisant, libellés lisibles par un lecteur d'écran (rôles, `aria-label` quand le texte manque), `prefers-reduced-motion` respecté.

## 4. Mouvement : assaisonnement, pas plat principal

Une page qui anime tout paraît bon marché et se lit moins vite. Hiérarchie du mouvement :

- au plus **un fond ambiant**, discret, derrière le contenu ; jamais deux ;
- au plus **un effet de titre**, sur le titre principal seulement ; le texte courant reste statique ;
- des **interactions utiles** sur ce que l'utilisateur touche (cartes, boutons, navigation), qui récompensent l'attention au lieu de la réclamer.

Pour une page d'accueil : un fond + un titre animé + deux ou trois composants interactifs suffisent presque toujours.

## 5. Éviter le « déjà vu »

Sauf demande explicite de l'utilisateur : pas de fond crème avec serif et accent terracotta, pas de noir avec un unique vert acide, pas de dégradé violet-bleu, pas d'Inter ou Space Grotesk par défaut, pas d'emoji comme marqueurs de section, pas de tout centré, pas d'arrondis et d'ombres identiques sur chaque bloc. Puiser dans le vocabulaire du sujet (ses unités, ses conventions, ses termes) plutôt que dans une esthétique générique.

## 6. Composants animés React : React Bits, sans le recopier

Quand le projet est en **React** (Vite ou Next, Tailwind conseillé) et que l'utilisateur veut une interface animée ou soignée, utiliser la collection React Bits (135 composants, modèle « copier-coller » : chaque composant devient un fichier du projet que l'on possède et modifie).

- **Si le skill `anthropic-skills:reactbits` est disponible dans la session** (il apparaît dans la liste des skills) : l'invoquer par son nom. Il contient le catalogue et la source TypeScript + Tailwind de chaque composant, utilisable même sans réseau. Ne jamais copier ce skill dans horn-dev : il est maintenu ailleurs et pèse 4 Mo.
- **Sinon** : documentation et installation depuis le site officiel, composant par composant, par exemple `npx shadcn@latest add https://reactbits.dev/r/<Composant>-TS-TW.json` ou `npx jsrepo add https://reactbits.dev/ts/tailwind/<Catégorie>/<Composant>`. Le dire dans le compte rendu.

Règles d'usage :

- Choisir dans le catalogue **avant** d'ouvrir une source ; installer seulement les dépendances des composants retenus (`motion`, `gsap`, `ogl`, `three`, `matter-js` selon le composant ; beaucoup n'en ont aucune).
- Régler les couleurs des composants sur la palette du plan (`colorStops`, `color`, `spotlightColor`, `sparkColor`…) au lieu des violets et verts par défaut.
- Un seul fond WebGL ou 3D par page, et pas sur une cible mobile ou peu puissante.
- Vérifier `prefers-reduced-motion` ; envelopper ou désactiver un composant qui ne le respecte pas.
- Deux composants (`StarBorder`, `GlitchText`) exigent des keyframes Tailwind : le bloc à copier est en commentaire au bas de leur source.
- Toute dépendance ajoutée passe par la règle habituelle : annoncée à l'utilisateur, installée dans le projet, jamais dans horn-dev.

## 7. Preuves

Un design se vérifie : captures d'écran (Playwright si configuré, `/horn-dev:testing`), états chargement, erreur, vide et succès montrés, navigation clavier essayée, contraste mesuré sur les couples texte et fond, comportement en mode sombre si prévu, taille du bundle après ajout de composants animés. Le compte rendu nomme ce qui a été regardé et ce qui ne l'a pas été.
