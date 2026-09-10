// Tests de bout en bout : Playwright démarre le serveur (voir playwright.config.js), ouvre un vrai navigateur,
// clique comme un utilisateur et vérifie ce qui s'affiche. Plus lents que les tests unitaires, mais ils prouvent
// que la page, le script et le serveur fonctionnent ensemble.
import { expect, test } from "@playwright/test";

test.describe("compteur", () => {
  test("affiche 0 au chargement", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle("Compteur de démonstration");
    await expect(page.locator("#value")).toHaveText("0");
  });

  test("le bouton + augmente la valeur et − la diminue", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Augmenter" }).click();
    await page.getByRole("button", { name: "Augmenter" }).click();
    await expect(page.locator("#value")).toHaveText("2");
    await page.getByRole("button", { name: "Diminuer" }).click();
    await expect(page.locator("#value")).toHaveText("1");
  });

  test("« Remettre à zéro » ramène à 0", async ({ page }) => {
    await page.goto("/");
    await page.getByRole("button", { name: "Augmenter" }).click();
    await page.getByRole("button", { name: "Remettre à zéro" }).click();
    await expect(page.locator("#value")).toHaveText("0");
  });

  test("le formulaire salue par le prénom", async ({ page }) => {
    await page.goto("/");
    await page.getByLabel("Votre prénom").fill("Horn");
    await page.getByRole("button", { name: "Saluer" }).click();
    await expect(page.locator("#greeting")).toHaveText("Bonjour Horn !");
    // Capture volontaire pour la documentation (dossier screenshots/, hors Git).
    await page.screenshot({ path: "screenshots/accueil-apres-salutation.png", fullPage: true });
  });
});
