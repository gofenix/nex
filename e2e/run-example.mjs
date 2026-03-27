import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";
import { setTimeout as delay } from "node:timers/promises";
import { getExample } from "./examples.manifest.mjs";
import { resolveFromRoot } from "./support/helpers.mjs";

function parseArgs(argv) {
  const args = {};

  for (let index = 0; index < argv.length; index += 1) {
    const current = argv[index];

    if (current === "--name") {
      args.name = argv[index + 1];
      index += 1;
    }
  }

  return args;
}

function commandFor(binary) {
  return process.platform === "win32" ? `${binary}.cmd` : binary;
}

function tailContent(content, lineCount = 40) {
  return content.trim().split("\n").slice(-lineCount).join("\n");
}

async function waitForServer(example, server, logPath) {
  const readyUrl = new URL(example.readyPath, `http://127.0.0.1:${example.port}`).toString();
  const deadline = Date.now() + 120_000;
  let lastError = "server not ready";

  while (Date.now() < deadline) {
    if (server.exitCode !== null) {
      const logOutput = fs.existsSync(logPath)
        ? tailContent(fs.readFileSync(logPath, "utf8"))
        : "no log output captured";

      throw new Error(
        `Example server exited before readiness for ${example.name}.\n${logOutput}`
      );
    }

    try {
      const response = await fetch(readyUrl, {
        redirect: "manual"
      });

      if (response.ok) {
        return;
      }

      lastError = `received HTTP ${response.status}`;
    } catch (error) {
      lastError = error.message;
    }

    await delay(500);
  }

  const logOutput = fs.existsSync(logPath)
    ? tailContent(fs.readFileSync(logPath, "utf8"))
    : "no log output captured";

  throw new Error(
    `Timed out waiting for ${example.name} at ${readyUrl}: ${lastError}\n${logOutput}`
  );
}

async function stopServer(server) {
  if (!server || server.exitCode !== null) {
    return;
  }

  try {
    process.kill(-server.pid, "SIGTERM");
  } catch (_error) {
    return;
  }

  const deadline = Date.now() + 10_000;

  while (Date.now() < deadline) {
    if (server.exitCode !== null) {
      return;
    }

    await delay(250);
  }

  try {
    process.kill(-server.pid, "SIGKILL");
  } catch (_error) {
    // Process already exited.
  }
}

async function run() {
  const args = parseArgs(process.argv.slice(2));

  if (!args.name) {
    console.error("Usage: npm run e2e:example -- --name <example>");
    process.exit(1);
  }

  const example = getExample(args.name);

  if (!example) {
    console.error(`Unknown example: ${args.name}`);
    process.exit(1);
  }

  const logDir = resolveFromRoot("e2e", "artifacts", "logs");
  const artifactRoot = resolveFromRoot("e2e", "artifacts", "playwright");
  const exampleRoot = resolveFromRoot(example.cwd);
  const logPath = path.join(logDir, `${example.name}.log`);

  fs.mkdirSync(logDir, { recursive: true });
  fs.mkdirSync(artifactRoot, { recursive: true });

  const logStream = fs.createWriteStream(logPath, { flags: "w" });
  const server = spawn(
    commandFor("mix"),
    ["nex.dev", "--port", String(example.port), "--host", "127.0.0.1"],
    {
      cwd: exampleRoot,
      env: {
        ...process.env
      },
      detached: true,
      stdio: ["ignore", "pipe", "pipe"]
    }
  );

  server.stdout.on("data", (chunk) => logStream.write(chunk));
  server.stderr.on("data", (chunk) => logStream.write(chunk));

  let exitCode = 0;

  try {
    console.log(`Starting ${example.name} on http://127.0.0.1:${example.port}`);
    console.log(`Server log: ${path.relative(resolveFromRoot(), logPath)}`);

    await waitForServer(example, server, logPath);

    const specPath = resolveFromRoot(example.spec);
    const playwright = spawn(
      commandFor("npx"),
      ["playwright", "test", specPath, "--config", resolveFromRoot("playwright.config.mjs")],
      {
        cwd: resolveFromRoot(),
        stdio: "inherit",
        env: {
          ...process.env,
          E2E_BASE_URL: `http://127.0.0.1:${example.port}`,
          E2E_EXAMPLE_NAME: example.name,
          E2E_ARTIFACT_ROOT: artifactRoot
        }
      }
    );

    exitCode = await new Promise((resolve, reject) => {
      playwright.on("exit", (code) => resolve(code ?? 1));
      playwright.on("error", reject);
    });
  } finally {
    await stopServer(server);
    logStream.end();
  }

  if (exitCode !== 0 && fs.existsSync(logPath)) {
    const tail = tailContent(fs.readFileSync(logPath, "utf8"));

    console.error(`\n${example.name} failed. Server log tail:\n${tail}\n`);
  }

  process.exit(exitCode);
}

run().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
