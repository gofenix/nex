import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("protects dashboard, logs in, and logs out", async ({ page }) => {
  await gotoExample(page, "/dashboard");

  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByTestId("auth-login-page")).toBeVisible();
  await expect(page.getByTestId("auth-login-flash-error")).toContainText(
    "Please log in"
  );

  await page.getByTestId("auth-login-email").fill("admin@example.com");
  await page.getByTestId("auth-login-password").fill("password");
  await page.getByTestId("auth-login-submit").click();

  await expect(page).toHaveURL(/\/dashboard$/);
  await expect(page.getByTestId("auth-dashboard-page")).toBeVisible();
  await expect(page.getByTestId("auth-dashboard-user-name")).toHaveText(
    "Admin User"
  );
  await expect(page.getByTestId("auth-dashboard-visit-count")).toHaveText("1");

  await page.reload({ waitUntil: "domcontentloaded" });
  await expect(page.getByTestId("auth-dashboard-visit-count")).toHaveText("2");

  await gotoExample(page);
  await page.getByTestId("auth-logout-button").click();

  await expect(page.getByTestId("auth-home-page")).toBeVisible();
  await expect(page.getByTestId("auth-session-state")).toContainText(
    "Not logged in"
  );

  await gotoExample(page, "/dashboard");
  await expect(page).toHaveURL(/\/login$/);
});
