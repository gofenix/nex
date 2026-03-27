import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("renders representative dynamic routes and API responses", async ({
  page,
  request
}) => {
  await gotoExample(page, "/users/1");
  await expect(page.getByTestId("dynamic-user-page")).toBeVisible();
  await expect(page.getByTestId("dynamic-user-name")).toHaveText("Zhang San");

  await gotoExample(page, "/posts/hello-world");
  await expect(page.getByTestId("dynamic-post-page")).toBeVisible();
  await expect(page.getByTestId("dynamic-post-title")).toContainText(
    "Hello World"
  );

  await gotoExample(page, "/docs/getting-started/install");
  await expect(page.getByTestId("dynamic-docs-page")).toBeVisible();
  await expect(page.getByTestId("dynamic-docs-path")).toContainText(
    "/getting-started/install"
  );
  await expect(page.getByTestId("dynamic-docs-content")).toContainText(
    "Content is being written"
  );

  const response = await request.get("/api/users/1");

  expect(response.status()).toBe(200);
  await expect(response).toBeOK();

  const payload = await response.json();

  expect(payload.data.name).toBe("Zhang San");
  expect(payload.data.city).toBe("Beijing");
});
