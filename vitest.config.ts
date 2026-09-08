import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/**/*.test.ts", "src/**/*.test.ts"],
    environment: "node",
    reporters: process.env.CI ? ["default", "junit"] : ["default"],
    outputFile: { junit: "reports/dev/vitest-junit.xml" },
    coverage: {
      provider: "v8",
      include: ["src/**/*.ts"],
      exclude: ["src/**/*.test.ts"],
      reporter: ["text", "json-summary"],
      reportsDirectory: "reports/dev/coverage",
    },
  },
});
