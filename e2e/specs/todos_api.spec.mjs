import { expect, test } from "@playwright/test";
import { gotoExample } from "../support/test-helpers.mjs";

test("supports CRUD operations through the JSON API", async ({
  page,
  request
}) => {
  await gotoExample(page);
  await expect(page.getByTestId("todos-api-page")).toBeVisible();

  const createResponse = await request.post("/api/todos", {
    data: {
      text: "Review Playwright harness"
    }
  });

  expect(createResponse.status()).toBe(201);
  const created = await createResponse.json();
  const todoId = created.data.id;

  const listResponse = await request.get("/api/todos");
  expect(listResponse.status()).toBe(200);
  const listPayload = await listResponse.json();
  expect(listPayload.data.some((todo) => todo.id === todoId)).toBe(true);

  const updateResponse = await request.put(`/api/todos/${todoId}`, {
    data: {
      completed: true
    }
  });

  expect(updateResponse.status()).toBe(200);
  const updated = await updateResponse.json();
  expect(updated.data.completed).toBe(true);

  const showResponse = await request.get(`/api/todos/${todoId}`);
  expect(showResponse.status()).toBe(200);
  const shown = await showResponse.json();
  expect(shown.data.completed).toBe(true);

  const deleteResponse = await request.delete(`/api/todos/${todoId}`);
  expect(deleteResponse.status()).toBe(204);

  const missingResponse = await request.get(`/api/todos/${todoId}`);
  expect(missingResponse.status()).toBe(404);
});
