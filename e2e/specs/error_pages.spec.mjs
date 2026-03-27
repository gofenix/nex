import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("renders custom 404, 403, and 500 pages", async ({ page, request }) => {
  await gotoExample(page);
  await expect(page.getByTestId("error-pages-page")).toBeVisible();

  const notFound = await request.get("/this-page-does-not-exist");
  expect(notFound.status()).toBe(404);
  await expect(await notFound.text()).toContain('data-testid="error-page-404"');

  const forbidden = await request.post("/forbidden");
  expect(forbidden.status()).toBe(403);
  await expect(await forbidden.text()).toContain('data-testid="error-page-403"');

  const serverError = await request.get("/cause_error");
  expect(serverError.status()).toBe(500);
  await expect(await serverError.text()).toContain('data-testid="error-page-500"');
});
