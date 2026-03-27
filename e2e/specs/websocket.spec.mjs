import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("connects and exchanges chat messages over WebSocket", async ({ page }) => {
  await gotoExample(page);

  await expect(page.getByTestId("websocket-page")).toBeVisible();

  const username = `playwright-${Date.now()}`;
  const message = "Hello from Playwright";

  await page.getByTestId("websocket-username").fill(username);
  await page.getByTestId("websocket-room").selectOption("tech");
  await page.getByTestId("websocket-connect").click();

  await expect(page.getByTestId("websocket-message")).toBeEnabled();

  await page.getByTestId("websocket-message").fill(message);
  await page.getByTestId("websocket-send").click();

  await expect(page.getByTestId("websocket-messages")).toContainText(message);
  await expect(page.getByTestId("websocket-messages")).toContainText(username);
});
