import path from "node:path";
import { fileURLToPath } from "node:url";

const currentDir = path.dirname(fileURLToPath(import.meta.url));

export const repoRoot = path.resolve(currentDir, "..", "..");

export function resolveFromRoot(...segments) {
  return path.join(repoRoot, ...segments);
}

export function requireEnv(name) {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }

  return value;
}

export function buildExampleUrl(pathname = "/") {
  const baseUrl = requireEnv("E2E_BASE_URL");
  return new URL(pathname, baseUrl).toString();
}

export async function locatorText(locator) {
  return ((await locator.textContent()) ?? "").trim();
}
