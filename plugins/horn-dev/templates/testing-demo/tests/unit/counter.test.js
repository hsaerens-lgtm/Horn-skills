// Tests unitaires : on appelle directement les fonctions, sans navigateur ni serveur. Ils s'exécutent en millisecondes.
import { describe, expect, it } from "vitest";
import { decrement, greet, increment, reset, LIMIT } from "../../src/counter.js";

describe("increment", () => {
  it("ajoute 1", () => {
    expect(increment(0)).toBe(1);
    expect(increment(4)).toBe(5);
  });

  it("ne dépasse jamais la limite", () => {
    expect(increment(LIMIT)).toBe(LIMIT);
  });
});

describe("decrement", () => {
  it("retire 1 sans passer sous zéro", () => {
    expect(decrement(1)).toBe(0);
    expect(decrement(0)).toBe(0);
  });
});

describe("reset", () => {
  it("revient à zéro", () => {
    expect(reset()).toBe(0);
  });
});

describe("greet", () => {
  it("salue par le prénom, en ignorant les espaces", () => {
    expect(greet("  Horn ")).toBe("Bonjour Horn !");
  });

  it("salue sans prénom si le champ est vide ou absent", () => {
    expect(greet("")).toBe("Bonjour !");
    expect(greet(undefined)).toBe("Bonjour !");
  });
});
