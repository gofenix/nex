import { expect, test } from "@playwright/test";
import {
  byTestIdPrefix,
  gotoExample,
  waitForActionResponse
} from "../support/test-helpers.mjs";

test("creates, toggles, and deletes todos", async ({ page }) => {
  await gotoExample(page);

  await expect(page.getByTestId("todos-page")).toBeVisible();

  const todoText = `Ship E2E ${Date.now()}`;

  await page.getByTestId("todo-input").fill(todoText);
  const createResponse = waitForActionResponse(page, "/create_todo");
  await page.getByTestId("todo-submit").click({ noWaitAfter: true });
  await createResponse;

  const todoTextNode = byTestIdPrefix(page, "todo-text-").filter({
    hasText: todoText
  });

  await expect(todoTextNode).toHaveCount(1);

  const todoTextTestId = await todoTextNode.getAttribute("data-testid");
  const todoId = todoTextTestId.replace("todo-text-", "");
  const todoItem = page.getByTestId(`todo-item-${todoId}`);

  await expect(todoItem).toHaveCount(1);

  const toggleResponse = waitForActionResponse(page, "/toggle_todo");
  await page
    .getByTestId(`todo-toggle-${todoId}`)
    .click({ noWaitAfter: true });
  await toggleResponse;

  await expect(page.getByTestId(`todo-text-${todoId}`)).toHaveClass(
    /line-through/
  );

  const deleteResponse = waitForActionResponse(page, "/delete_todo");
  await page
    .getByTestId(`todo-delete-${todoId}`)
    .click({ noWaitAfter: true });
  await deleteResponse;
  await expect(todoItem).toHaveCount(0);
});
