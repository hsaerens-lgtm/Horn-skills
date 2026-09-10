// Configuration Vitest (tests unitaires). Les tests de bout en bout (tests/e2e) sont exclus : Playwright les exécute.
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/unit/**/*.test.js"],
    environment: "node",
    reporters: process.env.CI ? ["default", "junit"] : ["default"],
    outputFile: { junit: "reports/vitest-junit.xml" },
  },
});
