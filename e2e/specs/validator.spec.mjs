import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("shows field-level validation feedback and accepts a valid form", async ({
  page
}) => {
  await gotoExample(page);

  await expect(page.getByTestId("validator-page")).toBeVisible();

  await page.getByTestId("validator-email").fill("not-an-email");
  await page.getByTestId("validator-email").blur();
  await expect(page.getByTestId("validator-error-email")).toContainText(
    "must be a valid email"
  );

  await page.getByTestId("validator-name").fill("Playwright User");
  await page.getByTestId("validator-email").fill("playwright@example.com");
  await page.getByTestId("validator-age").fill("24");
  await page.getByTestId("validator-password").fill("secret123");
  await page.getByTestId("validator-website").fill("https://nex.example");
  await page.getByTestId("validator-email").blur();

  await expect(page.getByTestId("validator-error-email")).toHaveText("");

  await page.getByTestId("validator-submit").click();
  await expect(page.getByTestId("validator-form-status")).toContainText(
    "Registration looks good"
  );
});
