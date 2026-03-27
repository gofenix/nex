import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("switches tabs and persists added users", async ({ page }) => {
  await gotoExample(page);

  await expect(page.getByTestId("alpine-page")).toBeVisible();
  await expect(page.getByTestId("alpine-users-panel")).toBeVisible();

  await page.getByTestId("alpine-tab-profile").click();
  await expect(page.getByTestId("alpine-profile-settings")).toBeVisible();

  await page.getByTestId("alpine-tab-users").click();
  await page.getByTestId("alpine-open-user-modal").click();

  await expect(page.getByTestId("alpine-user-modal")).toBeVisible();

  const name = `Playwright User ${Date.now()}`;
  const email = `playwright-${Date.now()}@example.com`;

  await page.getByTestId("alpine-user-name-input").fill(name);
  await page.getByTestId("alpine-user-email-input").fill(email);
  await page.getByTestId("alpine-user-save").click();

  const row = page.locator('[data-testid^="alpine-user-row-"]').filter({
    hasText: name
  });

  await expect(row).toHaveCount(1);
  await page.reload({ waitUntil: "domcontentloaded" });
  await expect(row).toHaveCount(1);
});
