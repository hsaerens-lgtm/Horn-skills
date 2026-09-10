// Logique pure du compteur : aucune dépendance au navigateur, donc testable par des tests unitaires.
export const LIMIT = 10;

export function increment(count) {
  return Math.min(count + 1, LIMIT);
}

export function decrement(count) {
  return Math.max(count - 1, 0);
}

export function reset() {
  return 0;
}

export function greet(name) {
  const clean = String(name ?? "").trim();
  return clean ? `Bonjour ${clean} !` : "Bonjour !";
}
