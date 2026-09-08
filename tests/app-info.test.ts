import { describe, expect, it } from "vitest";
import { loadAppInfo, parseAppInfo } from "../src/app-info.js";

describe("parseAppInfo", () => {
  it("accepte un package.json valide", () => {
    expect(parseAppInfo('{"name":"arness","version":"0.1.0"}')).toEqual({ name: "arness", version: "0.1.0" });
  });

  it("accepte une pré-version semver", () => {
    expect(parseAppInfo('{"name":"arness","version":"1.2.3-beta.1"}').version).toBe("1.2.3-beta.1");
  });

  it("refuse un JSON illisible", () => {
    expect(() => parseAppInfo("{ pas du json")).toThrow(/illisible/);
  });

  it("refuse un nom manquant", () => {
    expect(() => parseAppInfo('{"version":"0.1.0"}')).toThrow(/name/);
  });

  it("refuse une version non semver", () => {
    expect(() => parseAppInfo('{"name":"x","version":"1.0"}')).toThrow(/semver/);
  });
});

describe("loadAppInfo", () => {
  it("lit le package.json réel du projet", () => {
    const info = loadAppInfo();
    expect(info.name).toBe("arness");
    expect(info.version).toMatch(/^\d+\.\d+\.\d+/);
  });
});
