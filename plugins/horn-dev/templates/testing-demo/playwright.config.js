// Configuration Playwright (tests de bout en bout).
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "tests/e2e",
  timeout: 30_000,
  fullyParallel: true,
  retries: process.env.CI ? 1 : 0,
  reporter: [["list"], ["html", { open: "never", outputFolder: "playwright-report" }]],
  use: {
    baseURL: "http://localhost:4731",
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
    video: "off",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  // Playwright démarre le serveur de l'application avant les tests et l'arrête après.
  webServer: {
    command: "node app/server.js",
    url: "http://localhost:4731",
    // Toujours démarrer notre propre serveur : réutiliser un serveur déjà présent sur le port ferait tester une autre application.
    reuseExistingServer: false,
    timeout: 30_000,
  },
});
