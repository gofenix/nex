import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("increments, decrements, and resets the counter", async ({ page }) => {
  await gotoExample(page);

  const value = page.getByTestId("counter-value");

  await expect(page.getByTestId("counter-page")).toBeVisible();
  await expect(value).toHaveText("0");

  await page.getByTestId("counter-increment").click();
  await expect(value).toHaveText("1");

  await page.getByTestId("counter-decrement").click();
  await expect(value).toHaveText("0");

  await page.getByTestId("counter-decrement").click();
  await expect(value).toHaveText("0");

  await page.getByTestId("counter-increment").click();
  await page.getByTestId("counter-increment").click();
  await expect(value).toHaveText("2");

  await page.getByTestId("counter-reset").click();
  await expect(value).toHaveText("0");
});
