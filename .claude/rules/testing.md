# Règles de test (Arness)

- Moteur : Vitest (`npm test`, `npm run test:watch`, `npm run test:coverage`). Tests dans `tests/**/*.test.ts` ou à côté du code en `*.test.ts`.
- Typage : `npm run typecheck` fait partie des contrôles obligatoires ; `tsconfig.json` est strict, ne pas l'assouplir pour faire passer un test.
- Contrôle de référence : `scripts/dev/check.ps1 -Profile quick|full` (aussi `npm run check` / `npm run check:full`). Il produit un rapport dans `reports/dev/` avec date, commandes, versions et état Git.
- Interdit : supprimer un test, réduire une assertion, modifier un résultat attendu ou un snapshot, ou contourner un contrôle uniquement pour obtenir un succès. Toute évolution d'un test existant doit être justifiée dans le compte rendu.
- Code préexistant : commencer par des tests qui décrivent le comportement actuel ; ne jamais supprimer du code au motif qu'il n'a pas été écrit avec des tests.
- Nouveau code : cycle rouge → vert → refactor (`superpowers:test-driven-development`). Pas de tests triviaux pour « afficher du vert ».
- Mocks : un test qui simule un service ne prouve pas que le service réel fonctionne ; l'indiquer clairement et séparer tests simulés et tests d'intégration.
- Priorités quand le produit grandira : sauvegarde/rechargement, gestion des pannes, annulation, entrées invalides, échanges entre composants, lancement de la version compilée (`dist-smoke`).
- Interface web : aucune à ce stade. Si une interface apparaît, ajouter Playwright (voir `docs/development/TOOLCHAIN.md`) plutôt que de considérer les tests unitaires comme suffisants.
