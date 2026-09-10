# Démonstration horn-dev : tests unitaires et tests de bout en bout

Mini application (un compteur et un formulaire) livrée avec deux familles de tests, dont **un test volontairement en échec dans chaque famille** pour montrer à quoi ressemble un échec. Aucune donnée réelle, aucun service externe.

## Lancer

```bash
npm install
npx playwright install chromium
```

```bash
npm run test:unit
```
Tests unitaires (Vitest) : les fonctions de `src/counter.js` sont appelées directement. Attendu : 6 réussis, 1 échec volontaire.

```bash
npm run test:e2e
```
Tests de bout en bout (Playwright) : le serveur `app/server.js` est démarré automatiquement, un navigateur Chromium ouvre la page, clique et vérifie. Attendu : 4 réussis, 1 échec volontaire avec capture d'écran et trace dans `test-results/`.

```bash
npm run test:e2e:report
```
Ouvre le rapport HTML de Playwright (captures, trace pas à pas de l'échec).

```bash
npm run demo:clean
```
Supprime les deux tests volontairement en échec ; ensuite `npm test` doit être entièrement vert.

## Voir l'application

```bash
npm start
```
puis ouvrir http://localhost:4731.

## Structure

- `src/counter.js` : logique pure (testée par les tests unitaires).
- `app/public/index.html`, `app/server.js` : page et serveur statique (testés par les tests de bout en bout).
- `tests/unit/`, `tests/e2e/` : les deux familles de tests ; `*.demo-echec.*` = échecs volontaires.
- `.github/workflows/tests.yml` : les mêmes tests rejoués à chaque push, une fois le dépôt sur GitHub.
