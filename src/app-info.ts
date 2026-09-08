import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

/** Informations d'identité de l'application, lues depuis package.json. */
export interface AppInfo {
  name: string;
  version: string;
}

const SEMVER = /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/;

/**
 * Lit et valide le nom et la version déclarés dans un package.json.
 * Lève une erreur explicite si le fichier est illisible ou incohérent :
 * une version distribuée ne doit jamais démarrer avec une identité invalide.
 */
export function parseAppInfo(packageJsonText: string): AppInfo {
  let parsed: unknown;
  try {
    parsed = JSON.parse(packageJsonText);
  } catch (error) {
    throw new Error(`package.json illisible : ${(error as Error).message}`);
  }
  if (typeof parsed !== "object" || parsed === null) {
    throw new Error("package.json invalide : un objet JSON est attendu");
  }
  const { name, version } = parsed as Record<string, unknown>;
  if (typeof name !== "string" || name.trim() === "") {
    throw new Error("package.json invalide : champ « name » manquant");
  }
  if (typeof version !== "string" || !SEMVER.test(version)) {
    throw new Error(`package.json invalide : version « ${String(version)} » non conforme à semver`);
  }
  return { name, version };
}

/** Localise le package.json du projet (source ou dist) et renvoie ses informations. */
export function loadAppInfo(): AppInfo {
  const here = dirname(fileURLToPath(import.meta.url));
  const packageJsonPath = join(here, "..", "package.json");
  return parseAppInfo(readFileSync(packageJsonPath, "utf8"));
}
