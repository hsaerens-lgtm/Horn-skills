import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { cpSync, existsSync, mkdirSync, mkdtempSync, readdirSync, readFileSync, rmSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, relative, resolve } from "node:path";

export const REPO_ROOT = resolve(__dirname, "..");
export const PLUGIN_ROOT = join(REPO_ROOT, "plugins", "horn-dev");
export const SCRIPTS_DIR = join(PLUGIN_ROOT, "scripts");
export const FIXTURES_DIR = join(REPO_ROOT, "tests", "fixtures");

/** PowerShell disponible : Windows PowerShell 5.1 sur Windows, sinon pwsh. */
export function powershellExe(): string {
  return process.platform === "win32" ? "powershell" : "pwsh";
}

export interface ScriptResult {
  code: number;
  stdout: string;
  stderr: string;
}

/** Exécute un script horn-dev avec un HORN_DEV_HOME isolé (aucune écriture dans le vrai profil). */
export function runScript(script: string, args: string[], hornHome: string): ScriptResult {
  const r = spawnSync(
    powershellExe(),
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", join(SCRIPTS_DIR, script), ...args],
    { encoding: "utf8", env: { ...process.env, HORN_DEV_HOME: hornHome }, timeout: 180_000 },
  );
  return { code: r.status ?? -1, stdout: r.stdout ?? "", stderr: r.stderr ?? "" };
}

/** Crée un espace temporaire avec des copies indépendantes des projets synthétiques. */
export function makeWorkspace(): { root: string; home: string; alpha: string; beta: string; gamma: string; cleanup: () => void } {
  const root = mkdtempSync(join(tmpdir(), "horn-dev-test-"));
  const home = join(root, "home");
  const alpha = join(root, "alpha");
  const beta = join(root, "beta");
  const gamma = join(root, "gamma");
  cpSync(join(FIXTURES_DIR, "alpha"), alpha, { recursive: true });
  cpSync(join(FIXTURES_DIR, "beta"), beta, { recursive: true });
  mkdirSync(gamma, { recursive: true });
  return { root, home, alpha, beta, gamma, cleanup: () => rmSync(root, { recursive: true, force: true }) };
}

/** Empreinte d'une arborescence (chemins relatifs + contenus), avec exclusions. */
export function hashTree(dir: string, exclude: (rel: string) => boolean = () => false): string {
  const hash = createHash("sha256");
  const walk = (d: string) => {
    for (const name of readdirSync(d).sort()) {
      const full = join(d, name);
      const rel = relative(dir, full).replaceAll("\\", "/");
      if (exclude(rel)) continue;
      const st = statSync(full);
      if (st.isDirectory()) walk(full);
      else {
        hash.update(rel);
        hash.update(readFileSync(full));
      }
    }
  };
  walk(dir);
  return hash.digest("hex");
}

export function listFiles(dir: string): string[] {
  const out: string[] = [];
  const walk = (d: string) => {
    if (!existsSync(d)) return;
    for (const name of readdirSync(d)) {
      const full = join(d, name);
      if (statSync(full).isDirectory()) walk(full);
      else out.push(relative(dir, full).replaceAll("\\", "/"));
    }
  };
  walk(dir);
  return out.sort();
}

/** Même règle de détection que Resolve-Gitleaks dans _common.ps1 : PATH, puis dossier portable WinGet. */
export function gitleaksAvailable(): boolean {
  const onPath = spawnSync("gitleaks", ["version"], { encoding: "utf8", shell: true });
  if (onPath.status === 0) return true;
  const local = process.env.LOCALAPPDATA;
  if (!local) return false;
  const pkgRoot = join(local, "Microsoft", "WinGet", "Packages");
  if (!existsSync(pkgRoot)) return false;
  return readdirSync(pkgRoot).some((d) => d.startsWith("Gitleaks.Gitleaks_") && existsSync(join(pkgRoot, d, "gitleaks.exe")));
}
