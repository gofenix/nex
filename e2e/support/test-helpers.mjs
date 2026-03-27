import { expect } from "@playwright/test";
import { buildExampleUrl, locatorText, resolveFromRoot } from "./helpers.mjs";

export async function gotoExample(page, pathname = "/") {
  const response = await page.goto(buildExampleUrl(pathname), {
    waitUntil: "domcontentloaded"
  });

  if (!response) {
    throw new Error(`Missing response for ${pathname}`);
  }

  return response;
}

export function byTestIdPrefix(page, prefix) {
  return page.locator(`[data-testid^="${prefix}"]`);
}

export async function waitForActionResponse(page, pathname, method = "POST") {
  return page.waitForResponse((response) => {
    const url = new URL(response.url());

    return (
      url.pathname === pathname &&
      response.request().method() === method &&
      response.ok()
    );
  });
}

export async function expectTextToChange(locator, timeout = 15_000) {
  const initialText = await locatorText(locator);

  await expect
    .poll(async () => locatorText(locator), { timeout })
    .not.toBe(initialText);
}

export function fixturePath(filename) {
  return resolveFromRoot("e2e", "fixtures", filename);
}
