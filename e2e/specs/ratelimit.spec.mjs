import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("returns rate-limit headers and eventually rejects burst traffic", async ({
  page,
  request
}) => {
  await gotoExample(page);
  await expect(page.getByTestId("ratelimit-page")).toBeVisible();

  const responses = [];

  for (let index = 0; index < 6; index += 1) {
    responses.push(await request.get("/api/status"));
  }

  const limited = responses.find((response) => response.status() === 429);

  expect(limited).toBeTruthy();
  expect(limited.headers()["x-ratelimit-limit"]).toBe("5");
  expect(limited.headers()["x-ratelimit-remaining"]).toBe("0");

  const body = await limited.json();

  expect(body.error).toBe("Too Many Requests");
  expect(body.retry_after).toBe(60);
});
