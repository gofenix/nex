import { defineConfig, devices } from "@playwright/test";

const exampleName = process.env.E2E_EXAMPLE_NAME ?? "local";
const artifactRoot = process.env.E2E_ARTIFACT_ROOT ?? "e2e/artifacts/playwright";

export default defineConfig({
  testDir: "e2e/specs",
  fullyParallel: false,
  workers: 1,
  timeout: 30_000,
  expect: {
    timeout: 10_000
  },
  forbidOnly: Boolean(process.env.CI),
  reporter: [
    ["list"],
    [
      "html",
      {
        open: "never",
        outputFolder: `${artifactRoot}/${exampleName}/html-report`
      }
    ]
  ],
  outputDir: `${artifactRoot}/${exampleName}/test-results`,
  use: {
    baseURL: process.env.E2E_BASE_URL,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure"
  },
  projects: [
    {
      name: "chromium",
      use: {
        ...devices["Desktop Chrome"]
      }
    }
  ]
});
