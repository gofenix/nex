import { expect, test } from "@playwright/test";
import {
  expectTextToChange,
  gotoExample
} from "../support/test-helpers.mjs";

test("receives synchronized SSE updates", async ({ page }) => {
  await gotoExample(page);

  const price = page.getByTestId("energy-price");
  const time = page.getByTestId("energy-time");
  const dataPoints = page.getByTestId("energy-data-points");

  await expect(page.getByTestId("energy-dashboard-page")).toBeVisible();
  await expect(price).not.toHaveText("Loading...");
  await expect(price).toContainText(/^\d+\.\d{2}$/);

  await expectTextToChange(time);
  await expectTextToChange(dataPoints);
});
