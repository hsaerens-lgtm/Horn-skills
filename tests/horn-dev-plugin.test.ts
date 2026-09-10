import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { PLUGIN_ROOT, REPO_ROOT, listFiles } from "./helpers.js";

const SKILLS = ["dev", "init", "feature", "bugfix", "check", "review", "release", "resume"];
const USER_ONLY = ["init", "release"];

function frontmatter(path: string): Record<string, string> {
  const text = readFileSync(path, "utf8");
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!m) throw new Error(`frontmatter absent : ${path}`);
  const out: Record<string, string> = {};
  for (const line of m[1]!.split(/\r?\n/)) {
    const kv = line.match(/^([a-z-]+):\s*(.*)$/);
    if (kv) out[kv[1]!] = kv[2]!;
  }
  return out;
}

describe("manifestes du plugin", () => {
  it("marketplace.json déclare horn-dev avec une source relative", () => {
    const mp = JSON.parse(readFileSync(join(REPO_ROOT, ".claude-plugin", "marketplace.json"), "utf8"));
    expect(mp.name).toBe("horn-toolbox");
    expect(mp.owner?.name).toBeTruthy();
    const entry = mp.plugins.find((p: { name: string }) => p.name === "horn-dev");
    expect(entry).toBeDefined();
    expect(entry.source).toBe("./plugins/horn-dev");
    expect(entry.version, "la version doit être déclarée à un seul endroit (plugin.json)").toBeUndefined();
  });

  it("plugin.json est valide et versionné en semver", () => {
    const pj = JSON.parse(readFileSync(join(PLUGIN_ROOT, ".claude-plugin", "plugin.json"), "utf8"));
    expect(pj.name).toBe("horn-dev");
    expect(pj.version).toMatch(/^\d+\.\d+\.\d+$/);
    expect(pj.description.length).toBeGreaterThan(20);
  });

  it("aucun composant n'est placé dans .claude-plugin/", () => {
    expect(readdirSync(join(PLUGIN_ROOT, ".claude-plugin"))).toEqual(["plugin.json"]);
  });
});

describe("skills du plugin", () => {
  it("les huit skills existent avec name et description", () => {
    for (const s of SKILLS) {
      const path = join(PLUGIN_ROOT, "skills", s, "SKILL.md");
      expect(existsSync(path), path).toBe(true);
      const fm = frontmatter(path);
      expect(fm.name).toBe(s);
      expect(fm.description?.length ?? 0).toBeGreaterThan(40);
      expect(fm.description!.length).toBeLessThan(1536);
    }
  });

  it("init et release sont réservés à l'utilisateur ; les autres non", () => {
    for (const s of SKILLS) {
      const fm = frontmatter(join(PLUGIN_ROOT, "skills", s, "SKILL.md"));
      if (USER_ONLY.includes(s)) expect(fm["disable-model-invocation"], s).toBe("true");
      else expect(fm["disable-model-invocation"], s).toBeUndefined();
    }
  });

  it("check, review et resume ne peuvent pas éditer de fichiers", () => {
    expect(frontmatter(join(PLUGIN_ROOT, "skills", "check", "SKILL.md"))["disallowed-tools"]).toMatch(/Edit/);
    expect(frontmatter(join(PLUGIN_ROOT, "skills", "resume", "SKILL.md"))["disallowed-tools"]).toMatch(/Edit/);
    const review = frontmatter(join(PLUGIN_ROOT, "skills", "review", "SKILL.md"));
    expect(review.context).toBe("fork");
    expect(review.agent).toBe("Explore");
  });

  it("check, review et resume n'invoquent pas feature, bugfix, init ou release (pas de dépendance circulaire)", () => {
    for (const s of ["check", "review", "resume"]) {
      const body = readFileSync(join(PLUGIN_ROOT, "skills", s, "SKILL.md"), "utf8");
      // Les seules mentions autorisées sont des interdictions ou des propositions à l'utilisateur.
      const lines = body.split(/\r?\n/).filter((l) => /\/horn-dev:(feature|bugfix|init|release)/.test(l));
      for (const l of lines) expect(l, `${s}: ${l}`).toMatch(/Ne pas|ne pas|proposer|Proposer|orienter|utilisateur|réservé|N'exécuter|jamais|explique/i);
    }
  });

  it("dev respecte l'intention : analyser, relire et vérifier n'autorisent pas la modification", () => {
    const body = readFileSync(join(PLUGIN_ROOT, "skills", "dev", "SKILL.md"), "utf8");
    expect(body).toMatch(/\*\*analyser\*\*.*\*\*non\*\*/);
    expect(body).toMatch(/\*\*relire\*\*.*\*\*non\*\*/);
    expect(body).toMatch(/\*\*vérifier\*\*.*\*\*non\*\*/);
    expect(body).toContain("verification-grid.md");
    expect(body).toContain("horn-fingerprint.ps1");
  });

  it("les skills ciblent le projet courant et les scripts du plugin, jamais un chemin codé en dur", () => {
    for (const s of ["check", "init", "release", "review", "dev"]) {
      const body = readFileSync(join(PLUGIN_ROOT, "skills", s, "SKILL.md"), "utf8");
      expect(body).toContain("${CLAUDE_PLUGIN_ROOT}");
      expect(body).toContain("${CLAUDE_PROJECT_DIR}");
    }
  });
});

describe("hygiène du plugin", () => {
  it("aucun chemin absolu propre à une machine ni référence à Arness dans le plugin", () => {
    for (const rel of listFiles(PLUGIN_ROOT)) {
      const text = readFileSync(join(PLUGIN_ROOT, rel), "utf8");
      expect(text, rel).not.toMatch(/[A-Z]:\\Users\\[^\\\s]+\\(?!\.)/i);
      if (!rel.startsWith("references/legacy-mapping")) expect(text, rel).not.toMatch(/\bArness\b/);
    }
  });

  it("aucun motif de secret évident dans le plugin", () => {
    for (const rel of listFiles(PLUGIN_ROOT)) {
      const text = readFileSync(join(PLUGIN_ROOT, rel), "utf8");
      expect(text, rel).not.toMatch(/(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16})/);
    }
  });

  it("les scripts ne dépendent d'aucun fichier hors du plugin", () => {
    for (const rel of listFiles(join(PLUGIN_ROOT, "scripts"))) {
      const text = readFileSync(join(PLUGIN_ROOT, "scripts", rel), "utf8");
      expect(text, rel).not.toMatch(/\.\.\\\.\.|\.\.\/\.\./);
    }
  });
});
