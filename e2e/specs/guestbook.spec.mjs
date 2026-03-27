import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("creates and deletes guestbook messages", async ({ page }) => {
  await gotoExample(page);

  await expect(page.getByTestId("guestbook-page")).toBeVisible();
  await expect(page.getByTestId("guestbook-empty")).toBeVisible();

  const name = `Visitor ${Date.now()}`;
  const content = "Guestbook message from Playwright";

  await page.getByTestId("guestbook-name").fill(name);
  await page.getByTestId("guestbook-content").fill(content);
  await page.getByTestId("guestbook-submit").click();

  const messageContent = page
    .locator('[data-testid^="guestbook-message-content-"]')
    .filter({ hasText: content });

  await expect(messageContent).toHaveCount(1);

  const messageContentTestId = await messageContent.getAttribute("data-testid");
  const messageId = messageContentTestId.replace(
    "guestbook-message-content-",
    ""
  );
  const message = page.getByTestId(`guestbook-message-${messageId}`);

  await expect(message).toHaveCount(1);
  await expect(message).toContainText(name);

  page.once("dialog", (dialog) => dialog.accept());
  await page.getByTestId(`guestbook-delete-${messageId}`).click();
  await expect(message).toHaveCount(0);
});
