// DÉMONSTRATION : ce test de bout en bout échoue VOLONTAIREMENT.
// La page fonctionne ; c'est l'attente qui est fausse (après un seul clic, la valeur est 1, pas 5).
// Playwright conserve alors une capture d'écran et une trace dans test-results/.
// À supprimer après la démonstration : npm run demo:clean
import { expect, test } from "@playwright/test";

test("DÉMO ÉCHEC VOLONTAIRE : attend 5 après un seul clic", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("button", { name: "Augmenter" }).click();
  await expect(page.locator("#value")).toHaveText("5", { timeout: 2000 });
});
