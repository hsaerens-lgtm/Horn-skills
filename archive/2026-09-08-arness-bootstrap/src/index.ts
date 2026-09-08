#!/usr/bin/env node
import { loadAppInfo } from "./app-info.js";

/** Point d'entrée : affiche l'identité de l'application (utilisé par le contrôle de la version distribuée). */
export function main(argv: readonly string[] = process.argv.slice(2)): number {
  const info = loadAppInfo();
  if (argv.includes("--version") || argv.includes("-v")) {
    console.log(info.version);
    return 0;
  }
  console.log(`${info.name} ${info.version}`);
  return 0;
}

const invokedDirectly =
  process.argv[1] !== undefined && import.meta.url === new URL(`file:///${process.argv[1].replaceAll("\\", "/")}`).href;

if (invokedDirectly) {
  process.exitCode = main();
}
