import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/**/*.test.ts"],
    exclude: ["tests/fixtures/**", "node_modules/**", "archive/**"],
    environment: "node",
    testTimeout: 180_000,
    hookTimeout: 60_000,
    reporters: process.env.CI ? ["default", "junit"] : ["default"],
    outputFile: { junit: "reports/dev/vitest-junit.xml" },
  },
});
