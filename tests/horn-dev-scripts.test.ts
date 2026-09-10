import { existsSync, readFileSync, realpathSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { PLUGIN_ROOT, gitleaksAvailable, hashTree, listFiles, makeWorkspace, runScript } from "./helpers.js";

// Ces tests exécutent réellement les scripts PowerShell du plugin sur des copies temporaires
// des deux projets synthétiques (alpha : Node sans dépendance ; beta : Python unittest).
// Aucune écriture n'a lieu dans le profil de l'utilisateur : HORN_DEV_HOME est redirigé.

let ws: ReturnType<typeof makeWorkspace>;
let pluginHashBefore: string;
const hasGitleaks = gitleaksAvailable();
const expectedSuccess = hasGitleaks ? 0 : 2; // sans Gitleaks, le contrôle obligatoire est NON EXÉCUTÉ → 2

beforeAll(() => {
  ws = makeWorkspace();
  pluginHashBefore = hashTree(PLUGIN_ROOT);
});
afterAll(() => {
  ws?.cleanup();
});

describe("projet non initialisé", () => {
  it("horn-check refuse d'exécuter des commandes et affiche un audit lecture seule (code 5)", () => {
    const r = runScript("horn-check.ps1", ["-ProjectDir", ws.alpha], ws.home);
    expect(r.code).toBe(5);
    expect(r.stdout).toMatch(/non initialis/);
    expect(r.stdout).toMatch(/npm run test/);
    expect(existsSync(join(ws.alpha, "reports"))).toBe(false);
  });

  it("horn-check sur un dossier sans manifeste ne trouve aucune technologie (code 5, rien d'inventé)", () => {
    const r = runScript("horn-check.ps1", ["-ProjectDir", ws.gamma], ws.home);
    expect(r.code).toBe(5);
    expect(r.stdout).toMatch(/aucune|non identifi/i);
    expect(listFiles(ws.gamma)).toEqual([]);
  });

  it("-ProjectDir est obligatoire et le dossier du plugin est refusé comme cible (code 3)", () => {
    expect(runScript("horn-check.ps1", [], ws.home).code).toBe(3);
    expect(runScript("horn-check.ps1", ["-ProjectDir", PLUGIN_ROOT], ws.home).code).toBe(3);
    expect(runScript("horn-init.ps1", ["-ProjectDir", PLUGIN_ROOT, "-Apply"], ws.home).code).toBe(3);
  });
});

describe("initialisation légère et idempotente", () => {
  it("l'aperçu n'écrit rien", () => {
    const before = hashTree(ws.alpha);
    const r = runScript("horn-init.ps1", ["-ProjectDir", ws.alpha], ws.home);
    expect(r.code).toBe(0);
    expect(r.stdout).toMatch(/APERÇU|APERCU/);
    expect(hashTree(ws.alpha)).toBe(before);
    expect(existsSync(join(ws.home, "approved-projects.json"))).toBe(false);
  });

  it("-Apply crée uniquement les fichiers absents, déduits des manifestes", () => {
    const r = runScript("horn-init.ps1", ["-ProjectDir", ws.alpha, "-Apply"], ws.home);
    expect(r.code).toBe(0);
    const cfg = JSON.parse(readFileSync(join(ws.alpha, ".horn-dev.json"), "utf8"));
    expect(cfg.version).toBe(1);
    expect(cfg.project.stack).toContain("node");
    expect(cfg.checks.map((c: { command: string }) => c.command)).toContain("npm run test");
    expect(cfg.checks.map((c: { command: string }) => c.command)).toContain("npm run build");
    expect(existsSync(join(ws.alpha, "docs/development/STATUS.md"))).toBe(true);
    expect(existsSync(join(ws.alpha, "docs/development/tasks/TEMPLATE.md"))).toBe(true);
    expect(existsSync(join(ws.alpha, ".gitleaks.toml"))).toBe(true);
    expect(readFileSync(join(ws.alpha, "CLAUDE.md"), "utf8")).toContain("<!-- horn-dev:begin -->");
    // Pas de .gitignore dans la fixture : le script ne le crée pas.
    expect(existsSync(join(ws.alpha, ".gitignore"))).toBe(false);
    // Le fichier package.json du projet n'est pas touché.
    expect(readFileSync(join(ws.alpha, "package.json"), "utf8")).toBe(readFileSync(join(PLUGIN_ROOT, "..", "..", "tests", "fixtures", "alpha", "package.json"), "utf8"));
  });

  it("une deuxième exécution ne change rien et respecte une adaptation manuelle", () => {
    const cfgPath = join(ws.alpha, ".horn-dev.json");
    const cfg = JSON.parse(readFileSync(cfgPath, "utf8"));
    cfg.limits = ["adaptation manuelle conservée"];
    writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
    const before = hashTree(ws.alpha);
    const r = runScript("horn-init.ps1", ["-ProjectDir", ws.alpha, "-Apply"], ws.home);
    expect(r.code).toBe(0);
    expect(r.stdout).not.toMatch(/CRÉÉ|COMPLÉTÉ/);
    expect(hashTree(ws.alpha)).toBe(before);
    expect(JSON.parse(readFileSync(cfgPath, "utf8")).limits).toEqual(["adaptation manuelle conservée"]);
  });
});

describe("approbation explicite", () => {
  it("un projet initialisé mais non approuvé n'exécute rien (code 4)", () => {
    const r = runScript("horn-check.ps1", ["-ProjectDir", ws.alpha], ws.home);
    expect(r.code).toBe(4);
    expect(existsSync(join(ws.alpha, "reports"))).toBe(false);
  });

  it("-Approve enregistre le projet hors du projet et hors du plugin, une seule fois", () => {
    expect(runScript("horn-init.ps1", ["-ProjectDir", ws.alpha, "-Apply", "-Approve"], ws.home).stdout).toMatch(/APPROUVÉ/);
    const again = runScript("horn-init.ps1", ["-ProjectDir", ws.alpha, "-Approve"], ws.home).stdout;
    expect(again).toMatch(/DÉJÀ APPROUVÉ/);
    const approvals = JSON.parse(readFileSync(join(ws.home, "approved-projects.json"), "utf8"));
    expect(approvals.projects).toHaveLength(1);
    expect(listFiles(ws.alpha).some((f) => f.includes("approved"))).toBe(false);
  });
});

describe("vérification pilotée par le projet", () => {
  it("alpha : exécute les commandes Node déclarées et écrit ses rapports dans alpha seulement", () => {
    const betaBefore = hashTree(ws.beta, (rel) => rel.includes("__pycache__"));
    const r = runScript("horn-check.ps1", ["-ProjectDir", ws.alpha, "-Profile", "full"], ws.home);
    expect(r.code, r.stdout).toBe(expectedSuccess);
    expect(r.stdout).toMatch(/npm run test/);
    expect(r.stdout).toMatch(/npm run build/);
    const latest = JSON.parse(readFileSync(join(ws.alpha, "reports/dev/check-latest.json"), "utf8"));
    // realpathSync.native développe les noms courts Windows (HORNS~1) que peut contenir le dossier temporaire.
    expect(realpathSync.native(latest.projectDir).toLowerCase()).toBe(realpathSync.native(ws.alpha).toLowerCase());
    expect(latest.steps.find((s: { name: string }) => s.name === "tests").status).toBe("RÉUSSI");
    expect(hashTree(ws.beta, (rel) => rel.includes("__pycache__"))).toBe(betaBefore);
  });

  it("beta : exécute une commande Python différente, sans toucher alpha", () => {
    expect(runScript("horn-init.ps1", ["-ProjectDir", ws.beta, "-Apply", "-Approve"], ws.home).code).toBe(0);
    const alphaBefore = hashTree(ws.alpha, (rel) => rel.startsWith("reports/"));
    const r = runScript("horn-check.ps1", ["-ProjectDir", ws.beta, "-Profile", "quick"], ws.home);
    expect(r.code, r.stdout).toBe(expectedSuccess);
    expect(r.stdout).toMatch(/python -m unittest discover -s tests/);
    expect(r.stdout).not.toMatch(/npm run/);
    expect(existsSync(join(ws.beta, "reports/dev/check-latest.json"))).toBe(true);
    expect(hashTree(ws.alpha, (rel) => rel.startsWith("reports/"))).toBe(alphaBefore);
  });

  it("un échec réel est remonté (code 1) et le rapport le nomme", () => {
    const test = join(ws.alpha, "tests", "run.js");
    const original = readFileSync(test, "utf8");
    try {
      writeFileSync(test, original.replace("add(2, 3), 5", "add(2, 3), 6"));
      const r = runScript("horn-check.ps1", ["-ProjectDir", ws.alpha, "-Profile", "quick"], ws.home);
      expect(r.code).toBe(1);
      expect(r.stdout).toMatch(/ÉCHEC/);
      const latest = JSON.parse(readFileSync(join(ws.alpha, "reports/dev/check-latest.json"), "utf8"));
      expect(latest.steps.find((s: { name: string }) => s.name === "tests").status).toBe("ÉCHOUÉ");
    } finally {
      writeFileSync(test, original);
    }
  });

  it("un contrôle obligatoire à commande vide rend le verdict NON VÉRIFIÉ (code 2)", () => {
    const cfgPath = join(ws.beta, ".horn-dev.json");
    const saved = readFileSync(cfgPath, "utf8");
    try {
      const cfg = JSON.parse(saved);
      cfg.checks.push({ id: "e2e", command: "", profiles: ["quick"], mandatory: true });
      writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
      const r = runScript("horn-check.ps1", ["-ProjectDir", ws.beta, "-Profile", "quick"], ws.home);
      expect(r.code).toBe(2);
      expect(r.stdout).toMatch(/NON VÉRIFIÉ/);
    } finally {
      writeFileSync(cfgPath, saved);
    }
  });

  it("expectOutput détecte une sortie inattendue", () => {
    const cfgPath = join(ws.alpha, ".horn-dev.json");
    const saved = readFileSync(cfgPath, "utf8");
    try {
      const cfg = JSON.parse(saved);
      cfg.checks = [{ id: "smoke", command: "node src/lib.js", profiles: ["quick"], mandatory: true, expectOutput: "alpha 9.9.9" }];
      cfg.secrets = { enabled: false };
      writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
      const r = runScript("horn-check.ps1", ["-ProjectDir", ws.alpha, "-Profile", "quick"], ws.home);
      expect(r.code).toBe(1);
      expect(r.stdout).toMatch(/alpha 1\.0\.0/);
    } finally {
      writeFileSync(cfgPath, saved);
    }
  });
});

describe("preuves liées à l'état du code", () => {
  it("le rapport porte une empreinte égale à horn-fingerprint, qui change dès qu'un fichier change", () => {
    const before = runScript("horn-fingerprint.ps1", ["-ProjectDir", ws.alpha], ws.home);
    expect(before.code).toBe(0);
    const fp = before.stdout.trim().split(/\r?\n/).pop()!;
    expect(fp).toMatch(/^(git|fs):[0-9a-f]{16}$/);
    const r = runScript("horn-check.ps1", ["-ProjectDir", ws.alpha, "-Profile", "quick"], ws.home);
    const latest = JSON.parse(readFileSync(join(ws.alpha, "reports/dev/check-latest.json"), "utf8"));
    expect(latest.treeFingerprint).toBe(fp);
    expect(r.stdout).toContain(fp);
    // Une modification du code, même sans commit, change l'empreinte : les preuves du rapport sont périmées.
    const lib = join(ws.alpha, "src", "lib.js");
    const original = readFileSync(lib, "utf8");
    try {
      writeFileSync(lib, original + "\n// modification après rapport\n");
      const after = runScript("horn-fingerprint.ps1", ["-ProjectDir", ws.alpha], ws.home).stdout.trim().split(/\r?\n/).pop();
      expect(after).not.toBe(fp);
    } finally {
      writeFileSync(lib, original);
    }
    // Le dossier reports (hors code) ne compte pas : l'empreinte redevient identique.
    // (alpha n'est pas un dépôt Git : l'empreinte fs ignore reports/ ; le contenu restauré redonne l'état initial.)
    const restored = runScript("horn-fingerprint.ps1", ["-ProjectDir", ws.alpha], ws.home).stdout.trim().split(/\r?\n/).pop();
    expect(restored).toBe(fp);
  });
});

describe("outil indispensable indisponible", () => {
  it("un exécutable introuvable rend le contrôle NON EXÉCUTÉ et le verdict NON VÉRIFIÉ (code 2), pas ÉCHOUÉ", () => {
    const cfgPath = join(ws.beta, ".horn-dev.json");
    const saved = readFileSync(cfgPath, "utf8");
    try {
      const cfg = JSON.parse(saved);
      cfg.checks = [{ id: "outil-absent", command: "outil-horn-inexistant --version", profiles: ["quick"], mandatory: true }];
      cfg.secrets = { enabled: false };
      writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
      const r = runScript("horn-check.ps1", ["-ProjectDir", ws.beta, "-Profile", "quick"], ws.home);
      expect(r.code).toBe(2);
      const latest = JSON.parse(readFileSync(join(ws.beta, "reports/dev/check-latest.json"), "utf8"));
      expect(latest.steps.find((s: { name: string }) => s.name === "outil-absent").status).toBe("NON EXÉCUTÉ");
    } finally {
      writeFileSync(cfgPath, saved);
    }
  });
});

describe("isolation du plugin", () => {
  it("le dossier du plugin est inchangé après tous les scénarios", () => {
    expect(hashTree(PLUGIN_ROOT)).toBe(pluginHashBefore);
  });
});
