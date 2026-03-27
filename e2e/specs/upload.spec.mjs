import { readFile } from "node:fs/promises";
import { expect, test } from "@playwright/test";
import { fixturePath, gotoExample } from "../support/test-helpers.mjs";

test("accepts valid uploads and rejects empty or invalid ones", async ({
  page
}) => {
  await gotoExample(page);

  const fileInput = page.getByTestId("upload-file");
  const submit = page.getByTestId("upload-submit");
  const result = page.getByTestId("upload-result");

  await expect(page.getByTestId("upload-page")).toBeVisible();

  await fileInput.setInputFiles([]);
  await submit.click();
  await expect(result).toContainText("No file selected");

  const imageBuffer = await readFile(fixturePath("test-image.png"));

  await fileInput.setInputFiles([
    {
      name: `upload-${Date.now()}.png`,
      mimeType: "image/png",
      buffer: imageBuffer
    }
  ]);

  await submit.click();
  await expect(result).toContainText("Upload successful");
  await expect(result.locator("img")).toHaveCount(1);

  const invalidBuffer = await readFile(fixturePath("invalid.txt"));

  await fileInput.setInputFiles([
    {
      name: "invalid.txt",
      mimeType: "text/plain",
      buffer: invalidBuffer
    }
  ]);

  await submit.click();
  await expect(result).toContainText("Validation failed");
});
