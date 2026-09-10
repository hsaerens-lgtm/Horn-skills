// DÉMONSTRATION : ce test échoue VOLONTAIREMENT pour montrer à quoi ressemble un échec.
// Le code est correct ; c'est l'attente qui est fausse (1 + 1 ne fait pas 3).
// À supprimer après la démonstration : npm run demo:clean
import { expect, it } from "vitest";
import { increment } from "../../src/counter.js";

it("DÉMO ÉCHEC VOLONTAIRE : attend un résultat faux", () => {
  expect(increment(1)).toBe(3);
});
