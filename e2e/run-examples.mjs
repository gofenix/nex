import { spawn } from "node:child_process";
import { examples } from "./examples.manifest.mjs";
import { resolveFromRoot } from "./support/helpers.mjs";

function commandFor(binary) {
  return process.platform === "win32" ? `${binary}.cmd` : binary;
}

async function runExample(name) {
  return new Promise((resolve, reject) => {
    const child = spawn(
      process.execPath,
      [resolveFromRoot("e2e", "run-example.mjs"), "--name", name],
      {
        cwd: resolveFromRoot(),
        stdio: "inherit",
        env: {
          ...process.env
        }
      }
    );

    child.on("exit", (code) => resolve(code ?? 1));
    child.on("error", reject);
  });
}

async function run() {
  const failures = [];

  for (const example of examples) {
    console.log(`\n=== Running ${example.name} ===`);

    const exitCode = await runExample(example.name);

    if (exitCode !== 0) {
      failures.push(example.name);
    }
  }

  if (failures.length > 0) {
    console.error(`\nE2E failures: ${failures.join(", ")}`);
    process.exit(1);
  }

  console.log("\nAll example E2E checks passed.");
}

run().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
